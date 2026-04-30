/* ============================================================

   CHARGER APRÈS :
     1) KB.pl
     2) recursive_scheduling.pl

   Ce module utilise les prédicats suivants de la Knowledge Base :
     - room_building(Room, Building)
     - room_energy_cost(Room, Cost)
     - building_energy_max(Building, Emax)
     - timeslot(Ts, Day, _, _)
     - slot_hours/1
     - sessions_to_schedule_v2/2
     - valid_assignment_v2/4
     - occupy_schedule_rooms/1
     - release_schedule_rooms/1
     - apply_schedule_costs/1

   FORMAT D'ASSIGNMENT (produit par recursive_scheduling.pl) :
     assignment(SessionName, Group, Room, Timeslot)

   PRÉDICATS EXPORTÉS (utilisés par Partie 4 — Optimisation) :
     - session_energy/3
     - respect_emax/2
     - check_all_energy_constraints/1
     - total_weekly_energy/2
     - building_day_energy/4
     - print_energy_report/1
   ============================================================ */


/* ============================================================
   SECTION 1 : CALCUL ÉNERGÉTIQUE D'UNE SESSION
   Formule : E_session = epsilon(room) * d_i
   epsilon(room) = room_energy_cost/2 (défini dans KB)
   d_i = slot_hours/1 (durée d'un créneau)
   ============================================================ */

%% session_energy(+Room, +Session, -Energy)
%  Calcule l énergie consommée par une session dans une salle.
%  Utilise room_energy_cost/2 et slot_hours/1 de la Knowledge Base.

session_duration_hours(_Session, DurationHours) :-
    slot_hours(DurationHours).

session_energy(Room, Session, Energy) :-
    room_energy_cost(Room, Epsilon),
    session_duration_hours(Session, Di),
    Energy is Epsilon * Di.


/* ============================================================
   SECTION 2 : CONTRAINTE HC-6 — VÉRIFICATION DU SEUIL EMAX
   Contrainte : E(b_l, d) <= Emax(b_l) pour tout bâtiment et tout jour
   Cette vérification est faite PENDANT la construction,
   pas après — c'est le principe du early enforcement.
   ============================================================ */

%% respect_emax(+Building, +CurrentEnergy)
%  Réussit si CurrentEnergy ne dépasse pas le seuil du bâtiment.
%  Échoue (et déclenche le backtracking) si le seuil est dépassé.

respect_emax(Building, CurrentEnergy) :-
    building_energy_max(Building, Emax),
    CurrentEnergy =< Emax.


/* ============================================================
   SECTION 3 : ACCUMULATION RÉCURSIVE PAR BÂTIMENT ET PAR JOUR
   C'est le cœur intellectuel de cette partie.
   L'accumulateur parcourt la liste d'assignments et cumule
   l'énergie session par session, en vérifiant HC-6 à chaque étape.
   ============================================================ */

%% accumulate_building_energy(+Schedule, +Building, +Day, +Acc, -Total)
%  Parcourt récursivement le planning.
%  Pour chaque assignment dans le bâtiment B le jour D,
%  calcule l énergie de la session et l ajoute à l accumulateur.
%  HC-6 est vérifiée immédiatement après chaque ajout (early pruning).

accumulate_building_energy([], _Building, _Day, Acc, Acc).

accumulate_building_energy(
    [assignment(SessionName, _Group, Room, Ts) | Rest],
    Building, Day, Acc, Total) :-
    (   room_building(Room, Building),
        timeslot(Ts, Day, _, _)
    ->
        session_energy(Room, SessionName, E),
        NewAcc is Acc + E,
        respect_emax(Building, NewAcc),
        accumulate_building_energy(Rest, Building, Day, NewAcc, Total)
    ;
        accumulate_building_energy(Rest, Building, Day, Acc, Total)
    ).


%% building_day_energy(+Schedule, +Building, +Day, -Energy)
%  Calcule la consommation totale d un bâtiment pour un jour donné.
%  Version sans vérification HC-6 — utilisée pour les metriques et rapports.

building_day_energy(Schedule, Building, Day, Energy) :-
    findall(E,
        (   member(assignment(SessionName, _Group, Room, Ts), Schedule),
            room_building(Room, Building),
            timeslot(Ts, Day, _, _),
            session_energy(Room, SessionName, E)
        ),
        Energies),
    sum_list(Energies, Energy).


/* ============================================================
   SECTION 4 : VÉRIFICATION GLOBALE — TOUS BÂTIMENTS, TOUS JOURS
   Vérifie HC-6 pour l'ensemble du planning généré.
   ============================================================ */

%% check_all_energy_constraints(+Schedule)
%  Vérifie que HC-6 est respectée pour chaque (bâtiment, jour).
%  Utilise forall/2 pour tester toutes les combinaisons.
%  Échoue dès qu une violation est trouvée.

check_all_energy_constraints(Schedule) :-
    setof(D, Ts^Slot^Min^timeslot(Ts, D, Slot, Min), Days),
    forall(
        (building_energy_max(B, _), member(D, Days)),
        (   building_day_energy(Schedule, B, D, E),
            respect_emax(B, E)
        )
    ).


/* ============================================================
   SECTION 5 : MÉTRIQUE GLOBALE — CONSOMMATION TOTALE HEBDOMADAIRE
   Formule : E_total = Σ_{b∈B} Σ_{d∈Days} E(b, d)
   ============================================================ */

%% total_weekly_energy(+Schedule, -ETotal)
%  Calcule la consommation énergétique totale sur toute la semaine
%  et tous les bâtiments. Métrique principale pour l optimisation (Partie 4).

total_weekly_energy(Schedule, ETotal) :-
    % Collect unique days to avoid counting each day N times (once per timeslot)
    setof(D, Ts^Slot^Min^timeslot(Ts, D, Slot, Min), Days),
    findall(E,
        (   building_energy_max(B, _),
            member(D, Days),
            building_day_energy(Schedule, B, D, E)
        ),
        AllEnergies),
    sum_list(AllEnergies, ETotal).


/* ============================================================
   SECTION 6 : INTÉGRATION AVEC LE GÉNÉRATEUR (Partie 2)
   Étend le moteur de génération récursive de Emna avec la
   contrainte énergétique vérifiée à chaque assignment ajouté.
   ============================================================ */

%% schedule_with_energy(+Sessions, -Schedule)
%  Génère un planning valide qui respecte TOUTES les contraintes,
%  y compris HC-6 (énergie). 

schedule_with_energy(Sessions, Schedule) :-
    schedule_energy(Sessions, [], Schedule).

schedule_energy([], Acc, Acc).
schedule_energy([SessionTerm | Rest], Acc, Schedule) :-
    SessionTerm = session(SessionName, Group),
    % Utilise la validation Feasibility de votre KB (Partie 1)
    valid_assignment_v2(SessionTerm, Room, Ts, Acc),
    
    % Contrainte énergétique HC-6 (Partie 3)
    room_building(Room, Building),
    session_energy(Room, SessionName, SessionE),
    timeslot(Ts, Day, _, _),
    building_day_energy(Acc, Building, Day, CurrentE),
    
    NewE is CurrentE + SessionE,
    respect_emax(Building, NewE),
    
    % On ajoute l assignment au format complet de la KB
    NewAssignment = assignment(SessionName, Group, Room, Ts),
    schedule_energy(Rest, [NewAssignment | Acc], Schedule).


%% generate_schedule_with_energy(-Schedule)
%  Point d entrée principal : génère un planning complet (GL2+GL3+GL4)
%  avec contrainte énergétique intégrée.

generate_schedule_with_energy(Schedule) :-
    once(generate_schedule_with_energy_raw(Schedule)),
    (   occupy_schedule_rooms(Schedule),
        apply_schedule_costs(Schedule)
    ->  true
    ;   release_schedule_rooms(Schedule),
        fail
    ).

generate_schedule_with_energy_raw(Schedule) :-
    all_sessions(Sessions),
    schedule_with_energy(Sessions, Schedule).


%% generate_schedule_level_with_energy(+Level, -Schedule)
%  Génère un planning pour un niveau (gl2, gl3 ou gl4)
%  avec contrainte énergétique.

generate_schedule_level_with_energy(Level, Schedule) :-
    once(generate_schedule_level_with_energy_raw(Level, Schedule)),
    (   occupy_schedule_rooms(Schedule),
        apply_schedule_costs(Schedule)
    ->  true
    ;   release_schedule_rooms(Schedule),
        fail
    ).

generate_schedule_level_with_energy_raw(Level, Schedule) :-
    sessions_to_schedule_v2(Level, Sessions),
    schedule_with_energy(Sessions, Schedule).


/* ============================================================
   SECTION 7 : AFFICHAGE ET RAPPORT ÉNERGÉTIQUE
   ============================================================ */

%% print_energy_report(+Schedule)
%  Affiche un rapport complet de consommation par bâtiment et par jour,
%  avec indication PASS/VIOLATION pour chaque entrée.

print_energy_report(Schedule) :-
    setof(D, Ts^Slot^Min^timeslot(Ts, D, Slot, Min), Days),
    nl,
    write('======================================================'), nl,
    write('         RAPPORT DE CONSOMMATION ENERGETIQUE         '), nl,
    write('======================================================'), nl,
    forall(
        building_energy_max(B, Emax),
        (   nl,
            format("[Bâtiment: ~w | Emax = ~w unités]~n", [B, Emax]),
            forall(
                member(Day, Days),
                (   building_day_energy(Schedule, B, Day, E),
                    (   E > 0
                    ->  (   E > Emax
                        ->  format("  ~w : ~w unités  *** VIOLATION HC-6 ***~n", [Day, E])
                        ;   format("  ~w : ~w unités  [OK]~n", [Day, E])
                        )
                    ;   true
                    )
                )
            )
        )
    ),
    nl,
    total_weekly_energy(Schedule, ETotal),
    write('------------------------------------------------------'), nl,
    format("  E_total hebdomadaire : ~w unités~n", [ETotal]),
    write('======================================================'), nl.


/* ============================================================
   SECTION 8 : TESTS UNITAIRES
   Les tests exécutables sont centralisés dans test.pl.
   Charger puis lancer :

     ?- ['Knowledge-base'].
     ?- [recursive_scheduling].
     ?- [energy_module].
     ?- [test].
     ?- run_energy_tests.

   Références d'attendu (avec slot_hours = 1.5) :
     - session_energy(r203, gl2_analyse2_td1, E)        -> E = 4.5
     - session_energy(li013, gl3_prog_logique_tp1, E)   -> E = 12
     - building_day_energy([
|           assignment(gl2_analyse2_td1, gl2_1, r203, ts(lundi,1)),
|           assignment(gl2_algebre2_td1, gl2_1, r209, ts(lundi,2))
|       ], bat_cours, lundi, E).
                                                      -> E = 9
   ============================================================ */
/* ============================================================
   SECTION 9 : REQUÊTES UTILES POUR LE RAPPORT
   Copier-coller ces requêtes dans SWI-Prolog pour générer
   les captures d'écran du rapport.
   ============================================================

   % Charger les modules :
   ?- ['Knowledge-base'], [recursive_scheduling], [energy_module], [test].

   % Lancer tous les tests :
   ?- run_energy_tests.

   % Calculer l'énergie d'une session :
   ?- session_energy(li013, gl3_prog_logique_tp1, E).

   % Vérifier le seuil d'un bâtiment :
   ?- respect_emax(bat_labo, 100).
   ?- respect_emax(bat_labo, 200).

   % Générer un schedule GL3 avec contrainte énergie :
   ?- generate_schedule_level_with_energy(gl3, S), print_energy_report(S).

   % Consommation totale d'un schedule GL3 :
   ?- generate_schedule_level_with_energy(gl3, S), total_weekly_energy(S, E).

   % Tester l'impact du seuil (modifier building_energy_max dans KB) :
   % Emax bat_labo = 50  → schedule gl3 faisable ?
   ?- generate_schedule_level_with_energy(gl3, S).

   % Rapport énergétique complet :
   ?- generate_schedule_level_with_energy(gl3, S), print_energy_report(S).

   ============================================================ */


/* ============================================================
   FIN — energy_module.pl

   RÉSUMÉ DES PRÉDICATS :
     session_energy/3                  — E = ε(room) * d_i
     respect_emax/2                    — HC-6 : E ≤ Emax(building)
     accumulate_building_energy/5      — Accumulateur récursif avec HC-6 early
     building_day_energy/4             — Σ E(b, d) pour métriques
     check_all_energy_constraints/1    — Vérif globale HC-6
     total_weekly_energy/2             — E_total = ΣΣ E(b,d)
     schedule_with_energy/2            — Générateur intégré avec HC-6
     generate_schedule_with_energy/1   — Point d'entrée global
     generate_schedule_level_with_energy/2 — Par niveau (gl2/gl3/gl4)
     print_energy_report/1             — Rapport PASS/VIOLATION
     run_energy_tests/0                — défini dans test.pl
   ============================================================ */
