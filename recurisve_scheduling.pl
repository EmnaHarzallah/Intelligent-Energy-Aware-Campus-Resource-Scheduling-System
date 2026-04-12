/* ============================================================
   PART C — RECURSIVE SCHEDULE GENERATION
   Author : Emna Harzallah
   Load AFTER knowledge_base_insat_gl_complet_memA.pl
   ============================================================

   This file uses predicates provided by Knowledge Base :
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
%  Entry point
 
schedule(Sessions, Schedule) :-
    schedule(Sessions, [], Schedule).
 
%% schedule(+Remaining, +Placed, -Schedule)
%  Recursive worker with accumulator
 
schedule([], Acc, Acc).
schedule([(Course, Idx) | Rest], Acc, Schedule) :-
    % Pick a candidate room and timeslot
    room(Room),
    timeslot(Ts, _, _, _),
    % Static constraints (independent of partial schedule)
    equipment_ok(Course, Room),
    capacity_ok(Course, Room),
    instructor_available_ok(Course, Ts),
    % Dynamic constraints: check against ALREADY placed sessions
    no_room_conflict(Room, Ts, Acc),
    no_group_conflict(Course, Ts, Acc),
    no_instructor_conflict(Course, Ts, Acc),
    % Add this assignment to the accumulator
    schedule(Rest, [assignment(Course, Idx, Room, Ts) | Acc], Schedule).


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
   5. DEBUG TESTS
   ============================================================*/

  % Test one assignment manually with empty partial schedule
test_one_assignment :-
    Course = gl3_prog_logique,
    room(Room),
    timeslot(Ts, _, _, _),
    equipment_ok(Course, Room),
    capacity_ok(Course, Room),
    instructor_available_ok(Course, Ts),
    format("OK: ~w -> ~w @ ~w~n", [Course, Room, Ts]), !.
 
test_one_assignment :-
    write("FAIL: no valid assignment found."), nl.
 
% Test scheduling just 2 sessions
test_mini :-
    Sessions = [(gl3_prog_logique, 1), (gl3_prog_logique, 2)],
    schedule(Sessions, Plan),
    display_schedule(Plan).
    

