/* ============================================================
   server.pl — ProScheduler HTTP API
   Usage  : swipl server.pl
   Routes : POST http://localhost:8080/api/schedule
            GET  http://localhost:8080/health
   ============================================================ */

% Declare instructor_available as dynamic BEFORE loading the KB
% so its facts can be retracted/re-asserted for per-request blocking.
:- dynamic instructor_available/2.

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).

:- ['knowledge_base'].
:- ['recursive_scheduling'].
:- ['energy_module'].
:- ['optimization_module'].

% Per-request state: saved instructor slots that were retracted
:- dynamic instructor_saved/2.

% ─── Routes ──────────────────────────────────────────────────────────────────
:- http_handler(root(health),        handle_health,    [method(get)]).
:- http_handler(root(api/schedule),  handle_schedule,  [method(post)]).
:- http_handler(root(api/schedule),  handle_preflight, [method(options)]).

% ─── Entry point ─────────────────────────────────────────────────────────────
:- initialization(start_server, main).

start_server :-
    format("~n[ProScheduler] Starting Prolog HTTP server~n"),
    http_server(http_dispatch, [port(8080)]),
    format("[ProScheduler] Listening  →  http://localhost:8080~n"),
    format("[ProScheduler] POST /api/schedule  GET /health~n~n").


/* ============================================================
   SECTION 1 : HTTP HANDLERS
   ============================================================ */

handle_preflight(Request) :-
    cors_enable(Request, [methods([post, options])]),
    format("Status: 200~n~n").

handle_health(_Request) :-
    cors_enable,
    reply_json_dict(_{status: "ok", engine: "swi-prolog"}).

handle_schedule(Request) :-
    cors_enable(Request, [methods([post, options])]),
    catch(
        do_schedule(Request),
        Err,
        ( term_to_atom(Err, EA), atom_string(EA, ES),
          reply_json_dict(_{error: ES, candidates: []}, [status(500)]) )
    ).

do_schedule(Request) :-
    http_read_json_dict(Request, Body, []),

    % ── Parse request ─────────────────────────────────────
    get_dict(level,           Body, LevelStr),
    atom_string(Level, LevelStr),

    get_dict(selectedCourseIds, Body, SelStrs),
    maplist([S,A]>>(atom_string(A,S)), SelStrs, SelectedIds),

    get_dict(globalOccupied,  Body, Occ),
    get_dict(roomSlots,        Occ, RoomKeys),
    get_dict(instructorSlots,  Occ, InstrKeys),

    % ── Serialise all requests through a mutex ─────────────
    with_mutex(prolog_scheduler, (
        maplist(assert_room_key,       RoomKeys),
        maplist(block_instructor_key,  InstrKeys),

        ( run_filtered(Level, SelectedIds, 10, RawCandidates)
        -> true
        ;  RawCandidates = []
        ),

        retractall(room_occupied(_, _)),
        restore_instructors,
        reset_remaining_hours
    )),

    predsort(compare_candidates, RawCandidates, Sorted),
    length(Sorted, Len),
    ( Len =:= 0
    -> reply_json_dict(_{candidates: []})
    ;  numlist(1, Len, Ranks),
       maplist(ranked_candidate_json, Sorted, Ranks, JsonList),
       reply_json_dict(_{candidates: JsonList})
    ).


/* ============================================================
   SECTION 2 : SESSION FILTERING
   Only schedule sessions whose course base-name is in SelectedIds.
   We temporarily retract cost/3 facts for non-selected sessions,
   run the optimizer, then restore them.
   ============================================================ */

run_filtered(Level, SelectedIds, Max, Candidates) :-
    findall(
        cost(S, Ref, Rem),
        ( cost(S, Ref, Rem),
          session_level(S, Level),
          \+ session_in_selection(S, Level, SelectedIds)
        ),
        Suppressed
    ),
    maplist([cost(S,R,Rem)]>>(retract(cost(S,R,Rem))), Suppressed),
    (   catch(
            collect_level_candidates(Level, Max, Candidates),
            _,
            Candidates = []
        )
    ->  true
    ;   Candidates = []
    ),
    maplist([cost(S,R,Rem)]>>(assertz(cost(S,R,Rem))), Suppressed).

session_in_selection(Session, Level, SelectedIds) :-
    session_name_parts(Session, Base, _, _),
    atom_concat(Level, '_', Prefix),
    atom_concat(Prefix, CourseId, Base),
    member(CourseId, SelectedIds).


/* ============================================================
   SECTION 3 : GLOBAL ROOM OCCUPANCY
   Parse "ROOMID_day_slot" keys sent from the React frontend.
   ROOMID may be mixed-case (A1, Li013); Prolog uses lowercase.
   ============================================================ */

assert_room_key(Key) :-
    ( parse_slot_key(Key, Room, Ts)
    -> ( room_occupied(Room, Ts) -> true ; assertz(room_occupied(Room, Ts)) )
    ;  true
    ).

parse_slot_key(Key, Room, ts(Day, Slot)) :-
    ( atom(Key) -> KeyAtom = Key ; atom_string(KeyAtom, Key) ),
    atomic_list_concat(Parts, '_', KeyAtom),
    reverse(Parts, [SlotAtom, DayAtom | RoomRevParts]),
    atom_number(SlotAtom, Slot),
    Slot >= 1, Slot =< 5,
    member(DayAtom, [lundi, mardi, mercredi, jeudi, vendredi]),
    !,
    reverse(RoomRevParts, RoomParts),
    atomic_list_concat(RoomParts, '_', RoomUpper),
    downcase_atom(RoomUpper, Room).


/* ============================================================
   SECTION 4 : GLOBAL INSTRUCTOR BLOCKING
   Parse "INSTRUCTOR_day_slot" keys.  Instructor names come from
   the React display format ("Khalgui Mohamed_lundi_1") — we
   normalise to Prolog atom (khalgui_mohamed) by lowercasing.
   We retract instructor_available/2 facts temporarily and
   restore them after the run.
   ============================================================ */

block_instructor_key(Key) :-
    ( parse_instr_key(Key, Instr, Ts)
    -> ( retract(instructor_available(Instr, Ts))
       -> assertz(instructor_saved(Instr, Ts))
       ;  true
       )
    ;  true
    ).

parse_instr_key(Key, Instr, ts(Day, Slot)) :-
    ( atom(Key) -> KeyAtom = Key ; atom_string(KeyAtom, Key) ),
    atomic_list_concat(Parts, '_', KeyAtom),
    reverse(Parts, [SlotAtom, DayAtom | InstrRevParts]),
    atom_number(SlotAtom, Slot),
    Slot >= 1, Slot =< 5,
    member(DayAtom, [lundi, mardi, mercredi, jeudi, vendredi]),
    !,
    reverse(InstrRevParts, InstrParts),
    atomic_list_concat(InstrParts, '_', Raw),
    downcase_atom(Raw, Instr).

restore_instructors :-
    forall(
        retract(instructor_saved(I, Ts)),
        assertz(instructor_available(I, Ts))
    ).


/* ============================================================
   SECTION 5 : CANDIDATE SORTING
   Lexicographic order : E_total → Imbalance → Fairness
   predsort/3 also deduplicates candidates with equal metrics.
   ============================================================ */

compare_candidates(Order,
        candidate(_, metrics(E1, I1, V1)),
        candidate(_, metrics(E2, I2, V2))) :-
    ( E1 < E2 -> Order = (<)
    ; E1 > E2 -> Order = (>)
    ; I1 < I2 -> Order = (<)
    ; I1 > I2 -> Order = (>)
    ; V1 < V2 -> Order = (<)
    ; V1 > V2 -> Order = (>)
    ;            Order = (=)
    ).


/* ============================================================
   SECTION 6 : JSON SERIALISATION
   ============================================================ */

ranked_candidate_json(candidate(Schedule, metrics(E, Imb, Fair)), Rank, Json) :-
    length(Schedule, Count),
    maplist(assignment_json, Schedule, AsgList),
    Json = _{
        rank:        Rank,
        metrics:     _{ eTotal:       E,
                         imbalance:    Imb,
                         fairness:     Fair,
                         sessionCount: Count },
        assignments: AsgList
    }.

assignment_json(assignment(SName, Group, Room, ts(Day, Slot)), Json) :-
    atom_string(SName, SN),
    atom_string(Room,  RoomStr),
    atom_string(Day,   DayStr),
    ( Group = level(_) -> GroupStr = "level"
    ; atom_string(Group, GroupStr)
    ),
    Json = _{
        sessionName: SN,
        group:       GroupStr,
        roomId:      RoomStr,
        day:         DayStr,
        slot:        Slot
    }.
