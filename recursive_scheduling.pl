/* ============================================================
   PART C — RECURSIVE SCHEDULE GENERATION 
   ============================================================

   Uses from KB:
     sessions_to_schedule_v2/2   — produces session/3 structs
     valid_assignment_v2/4       — checks all hard constraints
     display_schedule/1          — expects assignment/5 terms

   Session format  : session(Course, Group, WeekTag)
   Assignment format: assignment(Course, Group, Room, Timeslot, WeekTag)
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
    Session = session(Course, Group, WeekTag),
    %% Build assignment in the KBs 5-arg format
    Asgn = assignment(Course, Group, Room, Ts, WeekTag),
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
    all_sessions(Sessions),
    schedule(Sessions, Schedule).

%% generate_schedule_level(+Level, -Schedule)
%  Schedule for one level: gl2, gl3, or gl4.

generate_schedule_level(Level, Schedule) :-
    sessions_to_schedule_v2(Level, Sessions),
    schedule(Sessions, Schedule).


/* ============================================================
   4. ENUMERATE ALL SOLUTIONS
   ============================================================ */

%% all_solutions_level(+Level, -AllPlans)

all_solutions_level(Level, AllPlans) :-
    findall(Plan, generate_schedule_level(Level, Plan), AllPlans).

%% count_solutions_level(+Level, -N)

count_solutions_level(Level, N) :-
    all_solutions_level(Level, Plans),
    length(Plans, N).


/* ============================================================
   5. DISPLAY
   ============================================================
   display_schedule/1 is defined in the KB and already handles
   assignment/5 terms — we simply delegate.
   ============================================================ */

%% show_schedule(+Level)
%  Displays the first valid schedule found for a level.

show_schedule(Level) :-
    generate_schedule_level(Level, Schedule),
    nl,
    format("=== Schedule for ~w ===~n", [Level]),
    display_schedule(Schedule),
    nl.

%% show_all_solutions(+Level)
%  Displays every valid schedule for a level.

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
    Session = session(gl3_prog_logique, gl3_1, toutes_semaines),
    valid_assignment_v2(Session, Room, Ts, []),
    format("OK: ~w -> ~w @ ~w~n", [Session, Room, Ts]), !.
test_one_assignment :-
    write("FAIL: no valid assignment found."), nl.

%% test_mini/0
%  Schedules two independent sessions and displays the result.

test_mini :-
    Sessions = [
        session(gl3_prog_logique, gl3_1, toutes_semaines),
        session(gl3_prog_logique, gl3_2, toutes_semaines)
    ],
    schedule(Sessions, Plan),
    display_schedule(Plan).