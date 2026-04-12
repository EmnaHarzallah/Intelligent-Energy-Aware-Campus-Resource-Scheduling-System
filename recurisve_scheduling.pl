/* ============================================================
   PART C — RECURSIVE SCHEDULE GENERATION
   Author : Member C
   Load AFTER knowledge_base_insat_gl_complet_memA.pl
   ============================================================

   This file uses predicates provided by A+B :
     - sessions_to_schedule/1        (lists all sessions)
     - sessions_to_schedule_level/2  (filters by level)
     - valid_assignment/5            (checks all constraints)
     - display_schedule/1            (human-readable display)

   MAIN PREDICATE :
     schedule(+Sessions, -Schedule)

   ASSIGNMENT FORMAT :
     assignment(Course, SessionIndex, Room, Timeslot)
   ============================================================ */


/* ============================================================
   1. RECURSIVE BACKTRACKING ENGINE
   ============================================================ */

%% schedule(+Sessions, -Schedule)
%  Sessions : list of (Course, SessionIndex) to place
%  Schedule : list of valid assignments found by backtracking

schedule([], []).
schedule([(Course, Idx) | RestSessions], [assignment(Course, Idx, Room, Ts) | RestPlan]) :-
    % Pick a candidate room and timeslot
    room(Room),
    timeslot(Ts, _, _, _),
    % Early pruning: check ALL constraints before going deeper
    valid_assignment(Course, Idx, Room, Ts, RestPlan),
    % Recurse on the remaining sessions
    schedule(RestSessions, RestPlan).


/* ============================================================
   2. ENTRY POINTS — GENERATE A FULL SCHEDULE
   ============================================================ */

%% generate_schedule(-Schedule)
%  Generates a schedule for ALL courses (GL2 + GL3 + GL4)

generate_schedule(Schedule) :-
    sessions_to_schedule(Sessions),
    schedule(Sessions, Schedule).


%% generate_schedule_level(+Level, -Schedule)
%  Generates a schedule for one level only: gl2, gl3, or gl4

generate_schedule_level(Level, Schedule) :-
    sessions_to_schedule_level(Level, Sessions),
    schedule(Sessions, Schedule).


/* ============================================================
   3. FIND ALL SOLUTIONS (small test example)
   ============================================================ */

%% all_solutions_level(+Level, -AllPlans)
%  Finds ALL possible schedules for a given level
%  ⚠ Use on a small subset only (e.g. gl3)

all_solutions_level(Level, AllPlans) :-
    findall(Plan, generate_schedule_level(Level, Plan), AllPlans).


%% count_solutions_level(+Level, -N)
%  Counts the number of valid schedules for a level

count_solutions_level(Level, N) :-
    all_solutions_level(Level, Plans),
    length(Plans, N).


/* ============================================================
   4. DISPLAY
   ============================================================ */

%% show_schedule(+Level)
%  Displays the first valid schedule found for a level

show_schedule(Level) :-
    generate_schedule_level(Level, Schedule),
    nl,
    format("=== Schedule for ~w ===~n", [Level]),
    display_schedule(Schedule),
    nl.


%% show_all_solutions(+Level)
%  Displays all valid schedules for a level

show_all_solutions(Level) :-
    all_solutions_level(Level, Plans),
    length(Plans, N),
    format("~n=== ~w solution(s) found for ~w ===~n", [N, Level]),
    forall(
        nth1(I, Plans, Plan),
        (format("~n--- Solution #~w ---~n", [I]), display_schedule(Plan))
    ).


/* ============================================================
   5. RECOMMENDED TESTS
   ============================================================

   % Load both files in SWI-Prolog:
   ?- [knowledge_base_insat_gl_complet_memA].
   ?- [member_C_schedule].

   % Quick test: first schedule for GL3
   ?- show_schedule(gl3).

   % Count all solutions for GL3
   ?- count_solutions_level(gl3, N).

   % Display all GL3 solutions
   ?- show_all_solutions(gl3).

   % Test a single valid assignment (with empty partial schedule)
   ?- valid_assignment(gl3_prog_logique, 1, Room, Ts, []),
      format("Room: ~w | Timeslot: ~w~n", [Room, Ts]).

   % Check backtracking works on GL2 alone
   ?- generate_schedule_level(gl2, Plan), length(Plan, N),
      format("~w sessions placed~n", [N]).

   ============================================================ */

/* END — member_C_schedule.pl */
