/* ============================================================
   server.pl — ProScheduler HTTP API
   Usage  : swipl server.pl
   Routes : POST http://localhost:8080/api/schedule
            GET  http://localhost:8080/api/instructors
            GET  http://localhost:8080/health
   ============================================================ */

% Declare instructor_available as dynamic BEFORE loading the KB
% so its facts can be retracted/re-asserted for per-request blocking.
:- dynamic instructor_available/2.
:- dynamic instructor_override/2.

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(library(time)).

:- ['knowledge_base'].
:- ['recursive_scheduling'].
:- ['energy_module'].
:- ['optimization_module'].

% Per-request state: saved instructor slots that were retracted
:- dynamic instructor_saved/2.
:- dynamic scheduler_owner/1.

% ─── Routes ──────────────────────────────────────────────────────────────────
:- http_handler(root(health),          handle_health,          [method(get)]).
:- http_handler(root(api/schedule),    handle_schedule_route,  []).
:- http_handler(root(api/instructors), handle_instructors_route, []).

% ─── Entry point ─────────────────────────────────────────────────────────────
:- initialization(start_server, main).

start_server :-
    format("~n[ProScheduler] Starting Prolog HTTP server~n"),
    http_server(http_dispatch, [port(8080)]),
    format("[ProScheduler] Listening  →  http://localhost:8080~n"),
    format("[ProScheduler] POST /api/schedule  GET /api/instructors  GET /health~n~n").


/* ============================================================
   SECTION 1 : HTTP HANDLERS
   ============================================================ */

handle_preflight(Request) :-
    cors_enable(Request, [methods([get, post, options])]),
    format("Status: 200~n~n").

handle_health(_Request) :-
    cors_enable,
    reply_json_dict(_{status: "ok", engine: "swi-prolog"}).

handle_instructors(Request) :-
    cors_enable(Request, [methods([get, options])]),
    build_instructor_catalog(Levels),
    reply_json_dict(_{levels: Levels}).

handle_instructors_route(Request) :-
    option(method(Method), Request),
    ( Method = options
    -> handle_preflight(Request)
    ; Method = get
    -> handle_instructors(Request)
    ;  reply_json_dict(_{error: "Method not allowed", candidates: []}, [status(405)])
    ).

handle_schedule_route(Request) :-
    option(method(Method), Request),
    ( Method = options
    -> handle_preflight(Request)
    ; Method = post
    -> handle_schedule(Request)
    ;  reply_json_dict(_{error: "Method not allowed", candidates: []}, [status(405)])
    ).

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

    parse_mode_from_body(Body, Mode),
    parse_max_candidates_from_body(Body, Mode, MaxCandidates),

    get_dict(selectedCourseIds, Body, SelStrs),
    maplist([S,A]>>(atom_string(A,S)), SelStrs, SelectedIds),

    get_dict(globalOccupied,  Body, Occ),
    get_dict(roomSlots,        Occ, RoomKeys),
    get_dict(instructorSlots,  Occ, InstrKeys),
    parse_session_demands_from_body(Body, Level, SessionTerms),
    parse_instructor_overrides_from_body(Body, InstructorOverrides),

    ( acquire_or_preempt_scheduler_lock
    -> call_cleanup(
           run_schedule_locked(
               Mode,
               Level,
               SelectedIds,
               SessionTerms,
               MaxCandidates,
               RoomKeys,
               InstrKeys,
               InstructorOverrides,
               ResponsePayload
           ),
           release_scheduler_lock
       )
    ;  ResponsePayload = _{
           mode: "busy",
           candidates: [],
           error: "Serveur occupe, impossible d'annuler la generation en cours. Reessayez dans quelques secondes."
       }
    ),
    reply_json_dict(ResponsePayload).

acquire_or_preempt_scheduler_lock :-
    acquire_scheduler_lock,
    !.
acquire_or_preempt_scheduler_lock :-
    cancel_running_generation,
    wait_and_acquire_scheduler_lock(2.0).

acquire_scheduler_lock :-
    ( catch(mutex_trylock(prolog_scheduler), _, fail)
    -> true
    ;  catch(mutex_create(prolog_scheduler), _, true),
       catch(mutex_trylock(prolog_scheduler), _, fail)
    ).

release_scheduler_lock :-
    catch(mutex_unlock(prolog_scheduler), _, true).

cancel_running_generation :-
    scheduler_owner(OwnerThread),
    thread_self(SelfThread),
    OwnerThread \= SelfThread,
    catch(thread_signal(OwnerThread, throw(cancelled_by_new_request)), _, fail),
    !.
cancel_running_generation :-
    fail.

wait_and_acquire_scheduler_lock(MaxWaitSeconds) :-
    get_time(T0),
    wait_and_acquire_scheduler_lock_loop(T0, MaxWaitSeconds).

wait_and_acquire_scheduler_lock_loop(T0, MaxWaitSeconds) :-
    ( acquire_scheduler_lock
    -> true
    ; get_time(Now),
      Elapsed is Now - T0,
      Elapsed < MaxWaitSeconds,
      sleep(0.05),
      wait_and_acquire_scheduler_lock_loop(T0, MaxWaitSeconds)
    ).

run_schedule_locked(
    Mode,
    Level,
    SelectedIds,
    SessionTerms,
    MaxCandidates,
    RoomKeys,
    InstrKeys,
    InstructorOverrides,
    ResponsePayload
) :-
    setup_call_cleanup(
        register_scheduler_owner,
        setup_call_cleanup(
            prepare_request_state(Level, RoomKeys, InstrKeys, InstructorOverrides),
            safe_schedule_request(
                Mode,
                Level,
                SelectedIds,
                SessionTerms,
                MaxCandidates,
                ResponsePayload
            ),
            cleanup_request_state
        ),
        unregister_scheduler_owner
    ).

register_scheduler_owner :-
    thread_self(Tid),
    retractall(scheduler_owner(_)),
    assertz(scheduler_owner(Tid)).

unregister_scheduler_owner :-
    thread_self(Tid),
    retractall(scheduler_owner(Tid)).

prepare_request_state(Level, RoomKeys, InstrKeys, InstructorOverrides) :-
    maplist(assert_room_key,       RoomKeys),
    maplist(block_instructor_key,  InstrKeys),
    apply_instructor_overrides(Level, InstructorOverrides).

cleanup_request_state :-
    retractall(room_occupied(_, _)),
    restore_instructors,
    clear_instructor_overrides,
    reset_remaining_hours.

scheduler_time_limit_seconds(25).

safe_schedule_request(Mode, Level, SelectedIds, SessionTerms, MaxCandidates, ResponsePayload) :-
    scheduler_time_limit_seconds(LimitSec),
    catch(
        call_with_time_limit(
            LimitSec,
            schedule_request_for_mode(Mode, Level, SelectedIds, SessionTerms, MaxCandidates, ResponsePayload)
        ),
        Err,
        schedule_failure_payload(Err, LimitSec, ResponsePayload)
    ),
    !.
safe_schedule_request(_Mode, _Level, _SelectedIds, _SessionTerms, _MaxCandidates, ResponsePayload) :-
    ResponsePayload = _{
        mode: "error",
        candidates: [],
        error: "Scheduling failed unexpectedly."
    }.

schedule_failure_payload(time_limit_exceeded, LimitSec, ResponsePayload) :-
    !,
    format(
        string(Message),
        "Delai serveur depasse (~w s). Essayez moins de matieres/seances ou relancez en mode exploration.",
        [LimitSec]
    ),
    ResponsePayload = _{
        mode: "timeout",
        candidates: [],
        error: Message
    }.
schedule_failure_payload(cancelled_by_new_request, _LimitSec, ResponsePayload) :-
    !,
    ResponsePayload = _{
        mode: "cancelled",
        candidates: [],
        error: "Generation annulee par une nouvelle demande."
    }.
schedule_failure_payload(error(cancelled_by_new_request, _), LimitSec, ResponsePayload) :-
    !,
    schedule_failure_payload(cancelled_by_new_request, LimitSec, ResponsePayload).
schedule_failure_payload(error(time_limit_exceeded, _), LimitSec, ResponsePayload) :-
    !,
    schedule_failure_payload(time_limit_exceeded, LimitSec, ResponsePayload).
schedule_failure_payload(Err, _LimitSec, ResponsePayload) :-
    term_to_atom(Err, ErrAtom),
    atom_string(ErrAtom, ErrString),
    ResponsePayload = _{
        mode: "error",
        candidates: [],
        error: ErrString
    }.

parse_mode_from_body(Body, Mode) :-
    ( get_dict(mode, Body, ModeRaw)
    -> coerce_atom(ModeRaw, ModeAtom),
       normalize_mode(ModeAtom, Mode)
    ;  Mode = optimize
    ).

normalize_mode(explore,  explore) :- !.
normalize_mode(optimize, optimize) :- !.
normalize_mode(_, optimize).

default_max_candidates(explore, 40).
default_max_candidates(optimize, 60).

parse_max_candidates_from_body(Body, Mode, MaxCandidates) :-
    default_max_candidates(Mode, Default),
    ( get_dict(maxCandidates, Body, Raw),
      number(Raw)
    -> N0 is floor(Raw)
    ;  N0 = Default
    ),
    ( N0 > 0
    -> MaxCandidates = N0
    ;  MaxCandidates = Default
    ).

schedule_request_for_mode(explore, Level, SelectedIds, SessionTerms, MaxCandidates, ResponsePayload) :-
    schedule_request(Level, SelectedIds, SessionTerms, MaxCandidates, RawCandidates),
    length(RawCandidates, Len),
    ( Len =:= 0
    -> ResponsePayload = _{
           mode: "explore",
           totalCandidates: 0,
           candidates: []
       }
    ;  numlist(1, Len, Ranks),
       maplist(ranked_candidate_json, RawCandidates, Ranks, JsonList),
       ResponsePayload = _{
           mode: "explore",
           totalCandidates: Len,
           candidates: JsonList
       }
    ).

schedule_request_for_mode(optimize, Level, SelectedIds, SessionTerms, MaxCandidates, ResponsePayload) :-
    schedule_request(Level, SelectedIds, SessionTerms, MaxCandidates, RawCandidates),
    sort_candidates_lexicographic(RawCandidates, Sorted),
    length(Sorted, Evaluated),
    ( Evaluated =:= 0
    -> ResponsePayload = _{
           mode: "optimize",
           evaluatedCandidates: 0,
           explanation: "Aucune solution faisable n'a ete trouvee.",
           best: @(null),
           candidates: []
       }
    ;  take_first_n(Sorted, 10, Top10),
       length(Top10, TopN),
       numlist(1, TopN, Ranks),
       maplist(ranked_candidate_json, Top10, Ranks, Top10Json),
       Top10 = [BestCandidate | Rest],
       ranked_candidate_json(BestCandidate, 1, BestJson),
       best_choice_explanation(BestCandidate, Rest, Evaluated, Explanation),
       ResponsePayload = _{
           mode: "optimize",
           evaluatedCandidates: Evaluated,
           explanation: Explanation,
           best: BestJson,
           candidates: Top10Json
       }
    ).

sort_candidates_lexicographic(RawCandidates, SortedCandidates) :-
    maplist(candidate_key_pair, RawCandidates, Keyed),
    keysort(Keyed, SortedKeyed),
    pairs_values(SortedKeyed, SortedCandidates).

candidate_key_pair(candidate(Schedule, metrics(E, Imb, Fair)), key(E, Imb, Fair, Schedule)-candidate(Schedule, metrics(E, Imb, Fair))).

best_choice_explanation(Best, Rest, Evaluated, Explanation) :-
    Best = candidate(_, metrics(E1, I1, V1)),
    ( Rest = [candidate(_, metrics(E2, I2, V2)) | _]
    -> better_reason(E1, I1, V1, E2, I2, V2, Reason),
       format(
           string(Explanation),
           "Meilleure solution choisie par ordre lexicographique (E_total, puis imbalance, puis fairness). Evaluees: ~w. Raison face au #2: ~w.",
           [Evaluated, Reason]
       )
    ;  format(
           string(Explanation),
           "Meilleure solution choisie par ordre lexicographique (E_total, puis imbalance, puis fairness). Une seule solution faisable a ete trouvee (~w evaluee).",
           [Evaluated]
       )
    ).

better_reason(E1, _I1, _V1, E2, _I2, _V2, Reason) :-
    E1 < E2,
    !,
    format(string(Reason), "E_total plus faible (~w < ~w)", [E1, E2]).
better_reason(E1, I1, _V1, E2, I2, _V2, Reason) :-
    E1 =:= E2,
    I1 < I2,
    !,
    format(string(Reason), "E_total egal (~w), mais imbalance plus faible (~w < ~w)", [E1, I1, I2]).
better_reason(E1, I1, V1, E2, I2, V2, Reason) :-
    E1 =:= E2,
    I1 =:= I2,
    format(string(Reason), "E_total et imbalance egaux (~w, ~w), puis fairness plus faible (~w < ~w)", [E1, I1, V1, V2]).


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

schedule_request(Level, SelectedIds, SessionTerms, MaxCandidates, RawCandidates) :-
    ( SessionTerms \= []
    -> collect_custom_candidates(SessionTerms, MaxCandidates, RawCandidates)
    ;  run_filtered(Level, SelectedIds, MaxCandidates, RawCandidates)
    ).

collect_custom_candidates(SessionTerms, MaxCandidates, Candidates) :-
    custom_solutions_limited(
        MaxCandidates,
        Schedule,
        schedule_with_energy(SessionTerms, Schedule),
        RawSchedules
    ),
    sort(RawSchedules, Schedules),
    findall(
        candidate(S, M),
        ( member(S, Schedules), schedule_metrics(S, M) ),
        Candidates
    ).

custom_solutions_limited(Max, Template, Goal, Solutions) :-
    integer(Max),
    Max > 0,
    (   catch(findnsols(Max, Template, Goal, Solutions), _, fail)
    ->  true
    ;   findall(Template, Goal, All),
        take_first_n(All, Max, Solutions)
    ).

take_first_n(_, 0, []) :- !.
take_first_n([], _N, []).
take_first_n([X | Xs], N, [X | Ys]) :-
    N > 0,
    N1 is N - 1,
    take_first_n(Xs, N1, Ys).

parse_session_demands_from_body(Body, Level, SessionTerms) :-
    ( get_dict(sessionDemands, Body, DemandsJson)
    -> parse_session_demands(Level, DemandsJson, SessionTerms)
    ;  SessionTerms = []
    ).

parse_session_demands(_Level, [], []).
parse_session_demands(Level, [Demand | Rest], SessionTerms) :-
    ( demand_to_sessions(Level, Demand, Current) -> true ; Current = [] ),
    parse_session_demands(Level, Rest, Tail),
    append(Current, Tail, SessionTerms).

demand_to_sessions(Level, Demand, Sessions) :-
    get_dict(courseId, Demand, CourseText),
    get_dict(kind, Demand, KindText),
    get_dict(group, Demand, GroupText),
    get_dict(count, Demand, CountRaw),
    coerce_atom(CourseText, CourseId),
    coerce_atom(KindText, Kind),
    coerce_atom(GroupText, Group),
    normalize_demand_count(CountRaw, Count),
    ( Count =< 0
    -> Sessions = []
    ;  build_session_term(Level, CourseId, Kind, Group, SessionTerm),
       repeat_session(SessionTerm, Count, Sessions)
    ).

build_session_term(Level, CourseId, cours, level, session(SessionName, level(Level))) :-
    !,
    atomic_list_concat([Level, CourseId, cours], '_', SessionName).
build_session_term(Level, CourseId, Kind, Group, session(SessionName, Group)) :-
    member(Kind, [td, tp]),
    group_index_for_level(Level, Group, Index),
    atomic_list_concat([Level, CourseId], '_', Base),
    atom_concat(Kind, Index, KindSuffix),
    atomic_list_concat([Base, KindSuffix], '_', SessionName).

group_index_for_level(Level, Group, Index) :-
    atom_concat(Level, '_', Prefix),
    atom_concat(Prefix, Index, Group),
    group(Group).

normalize_demand_count(CountRaw, Count) :-
    ( number(CountRaw)
    -> N0 is floor(CountRaw)
    ;  N0 = 0
    ),
    ( N0 > 0 -> Count = N0 ; Count = 0 ).

repeat_session(_Session, Count, []) :-
    Count =< 0,
    !.
repeat_session(Session, Count, [Session | Rest]) :-
    Count > 0,
    Next is Count - 1,
    repeat_session(Session, Next, Rest).

parse_instructor_overrides_from_body(Body, Overrides) :-
    ( get_dict(instructorOverrides, Body, OverrideDict)
    -> dict_pairs(OverrideDict, _, RawPairs),
       findall(
         CourseId-Instructor,
         ( member(CourseText-InstructorText, RawPairs),
           coerce_atom(CourseText, CourseId),
           normalize_instructor_atom(InstructorText, Instructor)
         ),
         Overrides
       )
    ;  Overrides = []
    ).

apply_instructor_overrides(Level, Overrides) :-
    clear_instructor_overrides,
    atom_concat(Level, '_', Prefix),
    forall(
        member(CourseId-Instructor, Overrides),
        ( atom_concat(Prefix, CourseId, Base),
          assertz(instructor_override(Base, Instructor))
        )
    ).

clear_instructor_overrides :-
    retractall(instructor_override(_, _)).

coerce_atom(Text, Atom) :-
    atom(Text),
    !,
    Atom = Text.
coerce_atom(Text, Atom) :-
    string(Text),
    !,
    atom_string(Atom, Text).
coerce_atom(Text, Atom) :-
    number(Text),
    !,
    atom_number(Atom, Text).


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
    member(DayAtom, [lundi, mardi, mercredi, jeudi, vendredi, samedi]),
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
    member(DayAtom, [lundi, mardi, mercredi, jeudi, vendredi, samedi]),
    !,
    reverse(InstrRevParts, InstrParts),
    atomic_list_concat(InstrParts, '_', Raw),
    normalize_instructor_atom(Raw, Instr).

normalize_instructor_atom(Raw, Instr) :-
    coerce_atom(Raw, RawAtom),
    downcase_atom(RawAtom, Lower),
    atom_chars(Lower, Chars),
    maplist(rewrite_instr_char, Chars, Rewritten),
    atom_chars(Instr, Rewritten).

rewrite_instr_char(' ', '_') :- !.
rewrite_instr_char('-', '_') :- !.
rewrite_instr_char(Char, Char).

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

/* ============================================================
   SECTION 7 : INSTRUCTOR CATALOG
   Expose all assigned instructors per level/course/session kind.
   ============================================================ */

build_instructor_catalog(Levels) :-
    maplist(level_instructor_pair, [gl2, gl3, gl4], Pairs),
    dict_pairs(Levels, _, Pairs).

level_instructor_pair(Level, Level-Courses) :-
    findall(
        CourseId,
        course_id_for_level(Level, CourseId),
        CourseIdsRaw
    ),
    sort(CourseIdsRaw, CourseIds),
    maplist(course_instructor_pair(Level), CourseIds, CoursePairs),
    dict_pairs(Courses, _, CoursePairs).

course_id_for_level(Level, CourseId) :-
    ( instructor_cours(Base, _)
    ; instructor_td(Base, _)
    ; instructor_tp(Base, _)
    ),
    base_course_id(Level, Base, CourseId).

base_course_id(Level, Base, CourseId) :-
    atom_concat(Level, '_', Prefix),
    atom_concat(Prefix, CourseId, Base).

course_instructor_pair(Level, CourseId, CourseId-Entry) :-
    atom_concat(Level, '_', Prefix),
    atom_concat(Prefix, CourseId, Base),
    instructor_names(cours, Base, Cours),
    instructor_names(td, Base, Td),
    instructor_names(tp, Base, Tp),
    append(Cours, Td, CoursTd),
    append(CoursTd, Tp, RawAll),
    sort(RawAll, All),
    Entry = _{
        cours: Cours,
        td: Td,
        tp: Tp,
        all: All
    }.

instructor_names(cours, Base, Names) :-
    findall(Name, (instructor_cours(Base, Instr), instructor_display_name(Instr, Name)), Raw),
    sort(Raw, Names).
instructor_names(td, Base, Names) :-
    findall(Name, (instructor_td(Base, Instr), instructor_display_name(Instr, Name)), Raw),
    sort(Raw, Names).
instructor_names(tp, Base, Names) :-
    findall(Name, (instructor_tp(Base, Instr), instructor_display_name(Instr, Name)), Raw),
    sort(Raw, Names).

instructor_display_name(InstrAtom, NameString) :-
    atomic_list_concat(Words, '_', InstrAtom),
    maplist(capitalized_word, Words, CapWords),
    atomic_list_concat(CapWords, ' ', NameAtom),
    atom_string(NameAtom, NameString).

capitalized_word(Word, Capitalized) :-
    atom_chars(Word, Chars),
    ( Chars = [First | Rest]
    -> upcase_atom(First, FirstUpper),
       atom_chars(Capitalized, [FirstUpper | Rest])
    ; Capitalized = Word
    ).
