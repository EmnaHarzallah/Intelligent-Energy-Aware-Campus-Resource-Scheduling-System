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
    % 1 slot = 1.5 heures (90 min). E = Coût_horaire * Slots * 1.5
    Energy is Epsilon * Duration * 1.5.


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
schedule_energy([Session | Rest], Acc, Schedule) :-
    Session = session(Course, Group, WeekTag),
    % Utilise la validation Feasibility de votre KB (Partie 1)
    valid_assignment_v2(Session, Room, Ts, Acc),
    
    % Contrainte énergétique HC-6 (Partie 3)
    room_building(Room, Building),
    session_energy(Room, Course, SessionE),
    timeslot(Ts, Day, _, _),
    building_day_energy(Acc, Building, Day, CurrentE),
    
    NewE is CurrentE + SessionE,
    respect_emax(Building, NewE),
    
    % On ajoute l'assignment au format complet de la KB
    NewAssignment = assignment(Course, Group, Room, Ts, WeekTag),
    schedule_energy(Rest, [NewAssignment | Acc], Schedule).


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
    nl, write('--- TESTS MODULE ÉNERGIE (CORRIGÉS 1.5h) ---'), nl,

    % Test 1 : salle_td (Cost 3 * 1.5 = 4.5)
    session_energy(r203, gl2_analyse2_td, E1),
    format("TEST 1 : E = ~w [Attendu: 4.5] ", [E1]),
    (E1 =:= 4.5 -> write('OK') ; write('FAIL')), nl,


    % Test 2 : labo_pc (Cost 8 * 1.5 = 12)
    session_energy(li013, gl3_prog_logique_tp, E2),
    format("TEST 2 : E = ~w [Attendu: 12.0] ", [E2]),
    (E2 =:= 12.0 -> write('OK') ; write('FAIL')), nl,

    % Test 3 : Mini Schedule (Analyse TD [4.5] + Algebre TD [4.5] = 9.0)
    S = [assignment(gl2_analyse2_td, gl2_1, r203, ts(lundi,1), toutes_semaines),
         assignment(gl2_algebre2_td, gl2_1, r215, ts(lundi,2), toutes_semaines)],
    building_day_energy(S, bat_cours, lundi, E3),
    format("TEST 3 : Bat_Cours Lundi = ~w [Attendu: 9.0] ", [E3]),
    (E3 =:= 9.0 -> write('OK') ; write('FAIL')), nl.

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