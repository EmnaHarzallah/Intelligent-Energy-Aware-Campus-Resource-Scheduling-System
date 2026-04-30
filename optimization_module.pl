/* ============================================================
   CHARGER APRÈS :
     1) knowledge_base.pl
     2) recursive_scheduling.pl
     3) energy_module.pl

   FORMAT D'ASSIGNMENT :
     assignment(SessionName, Group, Room, Timeslot)

   MÉTRIQUES :
     - E_total : total_weekly_energy/2 (module énergie)
     - Imbalance :
         Sum_{d in Days} (Emax_day(d) - Emin_day(d))
       où Emax_day/Emin_day sont max/min des consommations des bâtiments
       pour le jour d.
     - Fairness (salles) :
         Var(R) = (1/m) * Sum_{r in Rooms} (Usage(r) - mu)^2
   ============================================================ */

:- consult('knowledge_base.pl').
:- consult('recursive_scheduling.pl').
:- consult('energy_module.pl').

/* ============================================================
   SECTION 1 : EXTRACTION DES DOMAINES
   ============================================================ */

all_days(Days) :-
    setof(D, Ts^Slot^Min^timeslot(Ts, D, Slot, Min), Days).

all_buildings(Buildings) :-
    setof(B, Emax^building_energy_max(B, Emax), Buildings).

all_rooms(Rooms) :-
    setof(R, room(R), Rooms).


/* ============================================================
   SECTION 2 : MÉTRIQUE 1 — IMBALANCE JOURNALIER
   ============================================================ */

day_building_energies(Schedule, Day, Energies) :-
    all_buildings(Buildings),
    findall(E,
        (   member(B, Buildings),
            building_day_energy(Schedule, B, Day, E)
        ),
        Energies).

day_load_span(Schedule, Day, Span) :-
    day_building_energies(Schedule, Day, Energies),
    max_list(Energies, EmaxDay),
    min_list(Energies, EminDay),
    Span is EmaxDay - EminDay.

daily_load_imbalance(Schedule, Imbalance) :-
    all_days(Days),
    findall(Span,
        (   member(D, Days),
            day_load_span(Schedule, D, Span)
        ),
        Spans),
    sum_list(Spans, Imbalance).


/* ============================================================
   SECTION 3 : MÉTRIQUE 2 — FAIRNESS D'USAGE DES SALLES
   ============================================================ */

room_usage(Schedule, Room, Usage) :-
    findall(1, member(assignment(_, _, Room, _), Schedule), Marks),
    length(Marks, Usage).

room_usages([], _Schedule, []).
room_usages([R | RestRooms], Schedule, [U | RestUsages]) :-
    room_usage(Schedule, R, U),
    room_usages(RestRooms, Schedule, RestUsages).

list_mean(List, Mean) :-
    length(List, N),
    N > 0,
    sum_list(List, Sum),
    Mean is Sum / N.

sum_squared_diff([], _Mean, 0.0).
sum_squared_diff([X | Xs], Mean, Sum) :-
    Diff is X - Mean,
    Sq is Diff * Diff,
    sum_squared_diff(Xs, Mean, Rest),
    Sum is Sq + Rest.

room_usage_variance(Schedule, Variance) :-
    all_rooms(Rooms),
    room_usages(Rooms, Schedule, Usages),
    list_mean(Usages, Mu),
    sum_squared_diff(Usages, Mu, SumSq),
    length(Usages, M),
    M > 0,
    Variance is SumSq / M.


/* ============================================================
   SECTION 4 : VECTEUR DE MÉTRIQUES
   ============================================================ */

schedule_metrics(Schedule, metrics(ETotal, Imbalance, VarRoom)) :-
    total_weekly_energy(Schedule, ETotal),
    daily_load_imbalance(Schedule, Imbalance),
    room_usage_variance(Schedule, VarRoom).


/* ============================================================
   SECTION 5 : COMPARAISON MULTI-CRITÈRES
   ============================================================ */

weighted_value(metrics(E, I, V), weighted(WE, WI, WV), Score) :-
    Score is WE * E + WI * I + WV * V.

metrics_better(lexicographic,
               metrics(E1, I1, V1),
               metrics(E2, I2, V2)) :-
    (   E1 < E2
    ;   E1 =:= E2, I1 < I2
    ;   E1 =:= E2, I1 =:= I2, V1 < V2
    ).

metrics_better(energy,
               metrics(E1, I1, V1),
               metrics(E2, I2, V2)) :-
    (   E1 < E2
    ;   E1 =:= E2, I1 < I2
    ;   E1 =:= E2, I1 =:= I2, V1 < V2
    ).

metrics_better(imbalance,
               metrics(E1, I1, V1),
               metrics(E2, I2, V2)) :-
    (   I1 < I2
    ;   I1 =:= I2, E1 < E2
    ;   I1 =:= I2, E1 =:= E2, V1 < V2
    ).

metrics_better(fairness,
               metrics(E1, I1, V1),
               metrics(E2, I2, V2)) :-
    (   V1 < V2
    ;   V1 =:= V2, E1 < E2
    ;   V1 =:= V2, E1 =:= E2, I1 < I2
    ).

metrics_better(weighted(WE, WI, WV), M1, M2) :-
    weighted_value(M1, weighted(WE, WI, WV), S1),
    weighted_value(M2, weighted(WE, WI, WV), S2),
    (   S1 < S2
    ;   S1 =:= S2,
        metrics_better(lexicographic, M1, M2)
    ).

candidate_better(Strategy, candidate(_, M1), candidate(_, M2)) :-
    metrics_better(Strategy, M1, M2).

best_candidate([C | Rest], Strategy, Best) :-
    best_candidate(Rest, Strategy, C, Best).

best_candidate([], _Strategy, CurrentBest, CurrentBest).
best_candidate([C | Rest], Strategy, CurrentBest, Best) :-
    (   candidate_better(Strategy, C, CurrentBest)
    ->  NextBest = C
    ;   NextBest = CurrentBest
    ),
    best_candidate(Rest, Strategy, NextBest, Best).


/* ============================================================
   SECTION 6 : GÉNÉRATION DE CANDIDATS (LIMITÉE)
   ============================================================ */

take_first_n(_, 0, []) :- !.
take_first_n([], _N, []).
take_first_n([X | Xs], N, [X | Ys]) :-
    N > 0,
    N1 is N - 1,
    take_first_n(Xs, N1, Ys).

solutions_limited(Max, Template, Goal, Solutions) :-
    integer(Max),
    Max > 0,
    (   catch(findnsols(Max, Template, Goal, Solutions), _, fail)
    ->  true
    ;   findall(Template, Goal, All),
        take_first_n(All, Max, Solutions)
    ).

collect_level_candidates(Level, MaxCandidates, Candidates) :-
    solutions_limited(
        MaxCandidates,
        Schedule,
        generate_schedule_level_with_energy_raw(Level, Schedule),
        RawSchedules
    ),
    sort(RawSchedules, Schedules),
    findall(
        candidate(S, M),
        ( member(S, Schedules), schedule_metrics(S, M) ),
        Candidates
    ).

collect_global_candidates(MaxCandidates, Candidates) :-
    solutions_limited(
        MaxCandidates,
        Schedule,
        generate_schedule_with_energy_raw(Schedule),
        RawSchedules
    ),
    sort(RawSchedules, Schedules),
    findall(
        candidate(S, M),
        ( member(S, Schedules), schedule_metrics(S, M) ),
        Candidates
    ).


/* ============================================================
   SECTION 7 : OPTIMISATION (SÉLECTION DU MEILLEUR)
   ============================================================ */

%% optimize_level_schedule(+Level, -BestSchedule, -BestMetrics)
%  Stratégie par défaut : lexicographic, limite 30 candidats.
optimize_level_schedule(Level, BestSchedule, BestMetrics) :-
    optimize_level_schedule(Level, 30, lexicographic, BestSchedule, BestMetrics).

%% optimize_level_schedule(+Level, +MaxCandidates, +Strategy, -BestSchedule, -BestMetrics)
%  Strategy = lexicographic | energy | imbalance | fairness | weighted(WE,WI,WV)
optimize_level_schedule(Level, MaxCandidates, Strategy, BestSchedule, BestMetrics) :-
    collect_level_candidates(Level, MaxCandidates, Candidates),
    Candidates \= [],
    best_candidate(Candidates, Strategy, candidate(BestSchedule, BestMetrics)).

%% optimize_global_schedule(+MaxCandidates, +Strategy, -BestSchedule, -BestMetrics)
%  Attention : peut être coûteux sur GL2+GL3+GL4.
optimize_global_schedule(MaxCandidates, Strategy, BestSchedule, BestMetrics) :-
    collect_global_candidates(MaxCandidates, Candidates),
    Candidates \= [],
    best_candidate(Candidates, Strategy, candidate(BestSchedule, BestMetrics)).


/* ============================================================
   SECTION 8 : RAPPORT
   ============================================================ */

print_metrics(metrics(E, I, V)) :-
    format("E_total=~w | Imbalance=~w | VarRoom=~w~n", [E, I, V]).

print_optimization_report(Level, MaxCandidates, Strategy) :-
    collect_level_candidates(Level, MaxCandidates, Candidates),
    length(Candidates, N),
    format("~n=== Optimization Report (~w) ===~n", [Level]),
    format("Candidates évalués : ~w~n", [N]),
    format("Stratégie : ~w~n", [Strategy]),
    forall(
        nth1(I, Candidates, candidate(_, M)),
        ( format("  Candidate #~w -> ", [I]),
          print_metrics(M) )
    ),
    (   Candidates = []
    ->  write("Aucun schedule candidat trouvé."), nl
    ;   best_candidate(Candidates, Strategy, candidate(BestSchedule, BestMetrics)),
        nl,
        write(">>> Meilleur schedule sélectionné"), nl,
        print_metrics(BestMetrics),
        display_schedule(BestSchedule)
    ).


/* ============================================================
   REQUÊTES UTILES
   ============================================================

   % Charger :
   ?- ['Knowledge-base'], [recursive_scheduling], [energy_module], [optimization_module].

   % Optimisation GL3 (défaut : 30 candidats, lexicographique)
   ?- optimize_level_schedule(gl3, BestS, BestM).

   % Optimisation GL3 avec stratégie énergie pure
   ?- optimize_level_schedule(gl3, 40, energy, BestS, BestM).

   % Optimisation GL3 avec pondération :
   % minimise 1.0*E_total + 0.7*Imbalance + 0.3*VarRoom
   ?- optimize_level_schedule(gl3, 40, weighted(1.0, 0.7, 0.3), BestS, BestM).

   % Rapport détaillé des candidats évalués
   ?- print_optimization_report(gl3, 20, lexicographic).

   ============================================================ */
