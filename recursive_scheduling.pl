/* ============================================================
   PART C — RECURSIVE SCHEDULE GENERATION 
   ============================================================ */

:- consult('KB.pl').

/* ============================================================

   Uses from KB:
     sessions_to_schedule_v2/2   — produces session/2 structs
     valid_assignment_v2/4       — checks all hard constraints
     display_schedule/1          — expects assignment/4 terms
     occupy_schedule_rooms/1     — marks global room occupancy
     release_schedule_rooms/1    — rollback helper
     apply_schedule_costs/1      — updates RemainingHour in cost/3

   Session format   : session(SessionName, Group)
   Assignment format: assignment(SessionName, Group, Room, Timeslot)
   ============================================================ */


/* ============================================================
   1. RECURSIVE BACKTRACKING ENGINE
   ============================================================ */

%% schedule(+Sessions, -Schedule)
%  Entry point — delegates to accumulator form.

schedule(Sessions, Schedule) :-
    schedule(Sessions, [], Schedule).

%% schedule(+Remaining, +Partial, -Schedule)
%  For each session, find a Room+Timeslot that satisfies ALL
%  constraints against the already-placed sessions (Partial),
%  then recurse.  Backtracking explores alternatives.

schedule([], Acc, Acc).
schedule([Session | Rest], Partial, Schedule) :-
    %% KB predicate: picks a valid Room+Ts against current Partial
    valid_assignment_v2(Session, Room, Ts, Partial),
    Session = session(SessionName, Group),
    %% Build assignment in the KB 4-arg format
    Asgn = assignment(SessionName, Group, Room, Ts),
    schedule(Rest, [Asgn | Partial], Schedule).


/* ============================================================
   2. SESSION LIST HELPERS
   ============================================================
   The KB only exposes sessions_to_schedule_v2(+Level, -Sessions).
   We define the missing all-levels and per-level wrappers here.
   ============================================================ */

%% all_sessions(-Sessions)
%  Collects sessions for all three levels into one flat list.

all_sessions(Sessions) :-
    sessions_to_schedule_v2(gl2, S2),
    sessions_to_schedule_v2(gl3, S3),
    sessions_to_schedule_v2(gl4, S4),
    append(S2, S3, S23),
    append(S23, S4, Sessions).


/* ============================================================
   3. ENTRY POINTS
   ============================================================ */

%% generate_schedule(-Schedule)
%  Full schedule for GL2 + GL3 + GL4.

generate_schedule(Schedule) :-
    once(generate_schedule_raw(Schedule)),
    commit_schedule(Schedule).

%% generate_schedule_raw(-Schedule)
%  Full schedule without consuming remaining hours.

generate_schedule_raw(Schedule) :-
    all_sessions(Sessions),
    schedule(Sessions, Schedule).

%% generate_schedule_level(+Level, -Schedule)
%  Schedule for one level: gl2, gl3, or gl4.

generate_schedule_level(Level, Schedule) :-
    once(generate_schedule_level_raw(Level, Schedule)),
    commit_schedule(Schedule).

%% generate_schedule_level_raw(+Level, -Schedule)
%  Per-level schedule without consuming remaining hours.

generate_schedule_level_raw(Level, Schedule) :-
    sessions_to_schedule_v2(Level, Sessions),
    schedule(Sessions, Schedule).


%% commit_schedule(+Schedule)
%  Applies side effects atomically from the scheduler perspective:
%  1) lock rooms globally
%  2) consume remaining hours (cost/3)
%  If step 2 fails, release rooms locked in step 1.
%
%  Note: occupy_schedule_rooms/1 already rolls back its own partial
%  locks when it fails, so we never force a blind release on that path.

commit_schedule(Schedule) :-
    occupy_schedule_rooms(Schedule),
    (   apply_schedule_costs(Schedule)
    ->  true
    ;   release_schedule_rooms(Schedule),
        fail
    ).


/* ============================================================
   4. ENUMERATE ALL SOLUTIONS
   ============================================================ */

%% all_solutions_level(+Level, -AllPlans)

all_solutions_level(Level, AllPlans) :-
    findall(Plan, generate_schedule_level_raw(Level, Plan), AllPlans).

%% count_solutions_level(+Level, -N)

count_solutions_level(Level, N) :-
    all_solutions_level(Level, Plans),
    length(Plans, N).


/* ============================================================
   5. DISPLAY
   ============================================================
   display_schedule/1 is defined in the KB and already handles
   assignment/4 terms — we simply delegate.
   ============================================================ */

%% show_schedule(+Level)
%  Displays the first valid schedule found for a level.
%  Non-destructive: does not consume cost/3 and does not lock rooms.
show_schedule(Level) :-
    sessions_to_schedule_v2(Level, Sessions),
    State = count(0),
    (   schedule(Sessions, Schedule),
        arg(1, State, C),
        C1 is C + 1,
        nb_setarg(1, State, C1),
        format("~n--- Solution #~w ---~n", [C1]),
        display_schedule(Schedule),
        nl, write(">> Appuyez sur [ENTRÉE] pour la solution suivante, ou une autre touche pour arrêter..."),
        get_single_char(Char),
        nl,
        ( (Char = 13 ; Char = 10) -> fail ; !, true )
    ;   nl, write("--- Fin de la recherche ---"), nl
    ).

%% show_all_solutions(+Level)
%  Displays every valid schedule for a level.
% ATTENTION : Ce prédicat peut provoquer un dépassement de mémoire (Stack limit) 
% car il tente de stocker des milliers de solutions via findall/3. 
% Il est préférable dutiliser show_schedule/1 pour naviguer interactivement.

show_all_solutions(Level) :-
    all_solutions_level(Level, Plans),
    length(Plans, N),
    format("~n=== ~w solution(s) found for ~w ===~n", [N, Level]),
    forall(
        nth1(I, Plans, Plan),
        ( format("~n--- Solution #~w ---~n", [I]),
          display_schedule(Plan) )
    ).


/* ============================================================
   6. DEBUG TESTS
   ============================================================ */

%% test_one_assignment/0
%  Manually tests that valid_assignment_v2 can fire at all.

test_one_assignment :-
    Session = session(gl3_prog_logique_td1, gl3_1),
    valid_assignment_v2(Session, Room, Ts, []),
    format("OK: ~w -> ~w @ ~w~n", [Session, Room, Ts]), !.
test_one_assignment :-
    write("FAIL: no valid assignment found."), nl.

%% test_mini/0
%  Schedules two independent sessions and displays the result.

test_mini :-
    Sessions = [
        session(gl3_prog_logique_td1, gl3_1),
        session(gl3_prog_logique_td2, gl3_2)
    ],
    schedule(Sessions, Plan),
    display_schedule(Plan).
