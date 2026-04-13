/* ============================================================
   PARTIE 3 — MODÉLISATION ÉNERGÉTIQUE & ACCUMULATION NUMÉRIQUE
   Auteur : Imen Ben Ouaghrem
   Projet : Intelligent Energy-Aware Campus Resource Scheduling System
   INSAT — GL3 — Semestre 2, 2025-2026
   Superviseur : Mr Mohamed Khalgui

   CHARGER APRÈS :
     1) Knowledge-base.pl
     2) recurisve_scheduling.pl

   Ce module utilise les prédicats suivants de la Knowledge Base :
     - room_building(Room, Building)
     - room_energy_cost(Room, Cost)
     - building_energy_max(Building, Emax)
     - timeslot(Ts, Day, _, _)
     - course_duration(Course, D)

   FORMAT D'ASSIGNMENT (produit par recurisve_scheduling.pl) :
     assignment(Course, SessionIndex, Room, Timeslot)

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
   Formule : E_session = epsilon(room) * duration(course)
   epsilon(room) = room_energy_cost/2 (défini dans KB)
   duration      = course_duration/2  (en nombre de slots, 1 slot = 90 min)
   ============================================================ */

%% session_energy(+Room, +Course, -Energy)
%  Calcule l'énergie consommée par une session d'un cours dans une salle.
%  Utilise room_energy_cost/2 et course_duration/2 de la Knowledge Base.

session_energy(Room, Course, Energy) :-
    room_energy_cost(Room, Epsilon),
    course_duration(Course, Duration),
    Energy is Epsilon * Duration.


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
%  calcule l'énergie de la session et l'ajoute à l'accumulateur.
%  HC-6 est vérifiée immédiatement après chaque ajout (early pruning).

accumulate_building_energy([], _Building, _Day, Acc, Acc).

accumulate_building_energy(
    [assignment(Course, _Idx, Room, Ts) | Rest],
    Building, Day, Acc, Total) :-
    (   room_building(Room, Building),
        timeslot(Ts, Day, _, _)
    ->
        % Cette session appartient au bâtiment B ce jour D
        session_energy(Room, Course, E),
        NewAcc is Acc + E,
        % Vérification HC-6 EN COURS DE CONSTRUCTION — early enforcement
        % Si la contrainte échoue ici, Prolog backtracke immédiatement
        % sans explorer le reste du schedule.
        respect_emax(Building, NewAcc),
        accumulate_building_energy(Rest, Building, Day, NewAcc, Total)
    ;
        % Cette session n'appartient pas à ce bâtiment ce jour-là, on passe
        accumulate_building_energy(Rest, Building, Day, Acc, Total)
    ).


%% building_day_energy(+Schedule, +Building, +Day, -Energy)
%  Calcule la consommation totale d'un bâtiment pour un jour donné.
%  Version sans vérification HC-6 — utilisée pour les métriques et rapports.

building_day_energy(Schedule, Building, Day, Energy) :-
    findall(E,
        (   member(assignment(Course, _Idx, Room, Ts), Schedule),
            room_building(Room, Building),
            timeslot(Ts, Day, _, _),
            session_energy(Room, Course, E)
        ),
        Energies),
    sumlist(Energies, Energy).


/* ============================================================
   SECTION 4 : VÉRIFICATION GLOBALE — TOUS BÂTIMENTS, TOUS JOURS
   Vérifie HC-6 pour l'ensemble du planning généré.
   ============================================================ */

%% check_all_energy_constraints(+Schedule)
%  Vérifie que HC-6 est respectée pour chaque (bâtiment, jour).
%  Utilise forall/2 pour tester toutes les combinaisons.
%  Échoue dès qu'une violation est trouvée.

check_all_energy_constraints(Schedule) :-
    forall(
        (building(B), timeslot(_, D, _, _)),
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
%  et tous les bâtiments. Métrique principale pour l'optimisation (Partie 4).

total_weekly_energy(Schedule, ETotal) :-
    % Collect unique days to avoid counting each day N times (once per timeslot)
    setof(D, Ts^Slot^Min^timeslot(Ts, D, Slot, Min), Days),
    findall(E,
        (   building(B),
            member(D, Days),
            building_day_energy(Schedule, B, D, E),
            E > 0
        ),
        AllEnergies),
    sumlist(AllEnergies, ETotal).


/* ============================================================
   SECTION 6 : INTÉGRATION AVEC LE GÉNÉRATEUR (Partie 2)
   Étend le moteur de génération récursive de Emna avec la
   contrainte énergétique vérifiée à chaque assignment ajouté.
   ============================================================ */

%% schedule_with_energy(+Sessions, -Schedule)
%  Génère un planning valide qui respecte TOUTES les contraintes,
%  y compris HC-6 (énergie). Wrappe le générateur de Emna.

schedule_with_energy(Sessions, Schedule) :-
    schedule_energy(Sessions, [], Schedule).

schedule_energy([], Acc, Acc).
schedule_energy([(Course, Idx) | Rest], Acc, Schedule) :-
    room(Room),
    timeslot(Ts, Day, _, _),
    % Contraintes structurelles (Knowledge Base — Partie 1)
    equipment_ok(Course, Room),
    capacity_ok(Course, Room),
    instructor_available_ok(Course, Ts),
    no_room_conflict(Room, Ts, Acc),
    no_group_conflict(Course, Ts, Acc),
    no_instructor_conflict(Course, Ts, Acc),
    % Contrainte énergétique HC-6 — Partie 3
    % On vérifie que l'ajout de cette session ne dépasse pas Emax(bâtiment)
    room_building(Room, Building),
    session_energy(Room, Course, SessionE),
    building_day_energy(Acc, Building, Day, CurrentE),
    NewE is CurrentE + SessionE,
    respect_emax(Building, NewE),
    % Si tout est OK, on ajoute l'assignment à l'accumulateur
    schedule_energy(Rest, [assignment(Course, Idx, Room, Ts) | Acc], Schedule).


%% generate_schedule_with_energy(-Schedule)
%  Point d'entrée principal : génère un planning complet (GL2+GL3+GL4)
%  avec contrainte énergétique intégrée.

generate_schedule_with_energy(Schedule) :-
    sessions_to_schedule(Sessions),
    schedule_with_energy(Sessions, Schedule).


%% generate_schedule_level_with_energy(+Level, -Schedule)
%  Génère un planning pour un niveau (gl2, gl3 ou gl4)
%  avec contrainte énergétique.

generate_schedule_level_with_energy(Level, Schedule) :-
    sessions_to_schedule_level(Level, Sessions),
    schedule_with_energy(Sessions, Schedule).


/* ============================================================
   SECTION 7 : AFFICHAGE ET RAPPORT ÉNERGÉTIQUE
   ============================================================ */

%% print_energy_report(+Schedule)
%  Affiche un rapport complet de consommation par bâtiment et par jour,
%  avec indication PASS/VIOLATION pour chaque entrée.

print_energy_report(Schedule) :-
    nl,
    write('======================================================'), nl,
    write('         RAPPORT DE CONSOMMATION ENERGETIQUE         '), nl,
    write('======================================================'), nl,
    forall(
        building(B),
        (   nl,
            building_energy_max(B, Emax),
            format("[Bâtiment: ~w | Emax = ~w unités]~n", [B, Emax]),
            forall(
                member(Day, [lundi, mardi, mercredi, jeudi, vendredi, samedi]),
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
   À lancer après chargement des 3 fichiers dans SWI-Prolog :
     ?- [\'Knowledge-base\'].
     ?- [recurisve_scheduling].
     ?- [energy_module].
   ============================================================ */

%% run_energy_tests/0
%  Lance tous les tests de validation de ce module.

run_energy_tests :-
    nl,
    write('=============================================='), nl,
    write('     TESTS UNITAIRES — MODULE ÉNERGIE        '), nl,
    write('=============================================='), nl,

    % --- TEST 1 : session_energy salle_td ---
    write('TEST 1 : session_energy(r203, gl2_analyse2_td, E)'), nl,
    session_energy(r203, gl2_analyse2_td, E1),
    format("  => E = ~w  [attendu: 3] ", [E1]),
    (E1 =:= 3 -> write('PASS') ; write('FAIL')), nl,

    % --- TEST 2 : session_energy labo_pc ---
    write('TEST 2 : session_energy(li013, gl3_prog_logique_tp, E)'), nl,
    session_energy(li013, gl3_prog_logique_tp, E2),
    format("  => E = ~w  [attendu: 8] ", [E2]),
    (E2 =:= 8 -> write('PASS') ; write('FAIL')), nl,

    % --- TEST 3 : session_energy amphi ---
    write('TEST 3 : session_energy(a2, gl2_archi_res, E)'), nl,
    session_energy(a2, gl2_archi_res, E3),
    format("  => E = ~w  [attendu: 4] ", [E3]),
    (E3 =:= 4 -> write('PASS') ; write('FAIL')), nl,

    % --- TEST 4 : respect_emax — valide ---
    write('TEST 4 : respect_emax(bat_labo, 100) — doit passer'), nl,
    (respect_emax(bat_labo, 100)
    ->  write('  => PASS')
    ;   write('  => FAIL')), nl,

    % --- TEST 5 : respect_emax — violation ---
    write('TEST 5 : respect_emax(bat_labo, 200) — doit être bloqué'), nl,
    (respect_emax(bat_labo, 200)
    ->  write('  => NON BLOQUE (BUG)')
    ;   write('  => BLOQUE ok [PASS]')), nl,

    % --- TEST 6 : respect_emax — bat_cours ---
    write('TEST 6 : respect_emax(bat_cours, 60) — limite exacte'), nl,
    (respect_emax(bat_cours, 60)
    ->  write('  => PASS (égalité autorisée)')
    ;   write('  => FAIL')), nl,

    % --- TEST 7 : building_day_energy sur un mini schedule ---
    write('TEST 7 : building_day_energy sur mini schedule'), nl,
    MiniSchedule = [
        assignment(gl2_analyse2_td,    1, r203,  ts(lundi,1)),
        assignment(gl2_algebre2_td,    1, r215,  ts(lundi,2)),
        assignment(gl3_prog_logique,   1, r223,  ts(lundi,3)),
        assignment(gl3_prog_logique_tp,1, li013, ts(lundi,4))
    ],
    building_day_energy(MiniSchedule, bat_cours, lundi, E7a),
    building_day_energy(MiniSchedule, bat_labo,  lundi, E7b),
    format("  bat_cours / lundi = ~w unités  [attendu: 9]  ", [E7a]),
    (E7a =:= 9 -> write('PASS') ; write('FAIL')), nl,
    format("  bat_labo  / lundi = ~w unités  [attendu: 8]  ", [E7b]),
    (E7b =:= 8 -> write('PASS') ; write('FAIL')), nl,

    % --- TEST 8 : total_weekly_energy ---
    write('TEST 8 : total_weekly_energy sur mini schedule'), nl,
    total_weekly_energy(MiniSchedule, ETotal),
    format("  E_total = ~w unités  [attendu: 17] ", [ETotal]),
    (ETotal =:= 17 -> write('PASS') ; write('FAIL')), nl,

    % --- TEST 9 : check_all_energy_constraints — schedule valide ---
    write('TEST 9 : check_all_energy_constraints — mini schedule (valide)'), nl,
    (check_all_energy_constraints(MiniSchedule)
    ->  write('  => Toutes les contraintes respectées [PASS]')
    ;   write('  => Violation détectée [FAIL]')), nl,

    % --- TEST 10 : HC-6 violation détectée ---
    % On concentre 22 sessions d'amphi sur le MÊME jour lundi :
    % 20 sessions × 4 u + 2 sessions × 5 u (a7) = 90 u > Emax(bat_amphi)=80
    write('TEST 10 : HC-6 violation — surcharge bat_amphi (lundi)'), nl,
    OverloadSchedule = [
        assignment(gl2_archi_res,    1, a1, ts(lundi,1)),
        assignment(gl2_analyse2,     1, a2, ts(lundi,1)),
        assignment(gl2_algebre2,     1, a5, ts(lundi,1)),
        assignment(gl2_sgbd,         1, a6, ts(lundi,1)),
        assignment(gl2_applic_rep,   1, a7, ts(lundi,1)),
        assignment(gl2_csi,          2, a1, ts(lundi,2)),
        assignment(gl2_droit,        2, a2, ts(lundi,2)),
        assignment(gl2_comptabilite, 2, a5, ts(lundi,2)),
        assignment(gl3_bases_rel,    2, a6, ts(lundi,2)),
        assignment(gl3_fond_syst_rep,2, a7, ts(lundi,2)),
        assignment(gl3_analyse_data, 3, a1, ts(lundi,3)),
        assignment(gl3_co_design,    3, a2, ts(lundi,3)),
        assignment(gl3_protoc_web,   3, a5, ts(lundi,3)),
        assignment(gl3_methodo_conc, 3, a6, ts(lundi,3)),
        assignment(gl3_marketing,    3, a7, ts(lundi,3)),
        assignment(gl4_big_data,     4, a1, ts(lundi,4)),
        assignment(gl4_archi_log,    4, a2, ts(lundi,4)),
        assignment(gl4_protoc_secu,  4, a5, ts(lundi,4)),
        assignment(gl4_management,   4, a6, ts(lundi,4)),
        assignment(gl4_grh,          4, a7, ts(lundi,4))
    ],
    % bat_amphi/lundi = 15×4 + 5×5 = 60+25 = 85 unités > Emax=80
    building_day_energy(OverloadSchedule, bat_amphi, lundi, EOver),
    format("  bat_amphi / lundi = ~w unités (Emax=80) => doit déclencher violation", [EOver]), nl,
    (check_all_energy_constraints(OverloadSchedule)
    ->  write('  => Non détectée (BUG)')
    ;   write('  => Violation détectée [PASS]')), nl,

    nl,
    write('=============================================='), nl,
    write('          FIN DES TESTS UNITAIRES            '), nl,
    write('=============================================='), nl.


/* ============================================================
   SECTION 9 : REQUÊTES UTILES POUR LE RAPPORT
   Copier-coller ces requêtes dans SWI-Prolog pour générer
   les captures d'écran du rapport.
   ============================================================

   % Charger les modules :
   ?- [\'Knowledge-base\'], [recurisve_scheduling], [energy_module].

   % Lancer tous les tests :
   ?- run_energy_tests.

   % Calculer l'énergie d'une session :
   ?- session_energy(li013, gl3_prog_logique_tp, E).

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
     session_energy/3                  — E = ε(room) × duration(course)
     respect_emax/2                    — HC-6 : E ≤ Emax(building)
     accumulate_building_energy/5      — Accumulateur récursif avec HC-6 early
     building_day_energy/4             — Σ E(b, d) pour métriques
     check_all_energy_constraints/1    — Vérif globale HC-6
     total_weekly_energy/2             — E_total = ΣΣ E(b,d)
     schedule_with_energy/2            — Générateur intégré avec HC-6
     generate_schedule_with_energy/1   — Point d'entrée global
     generate_schedule_level_with_energy/2 — Par niveau (gl2/gl3/gl4)
     print_energy_report/1             — Rapport PASS/VIOLATION
     run_energy_tests/0                — Suite de 10 tests unitaires
   ============================================================ */