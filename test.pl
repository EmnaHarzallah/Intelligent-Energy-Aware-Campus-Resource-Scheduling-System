/* ============================================================
   tests.pl — Suite de tests unifiée
   Auteurs : Minyar Frifita, Emna Harzallah, Imen Ben Ouaghrem
   Projet  : Intelligent Energy-Aware Campus Scheduling System

   Ordre de chargement obligatoire :
     1. knowledge_base.pl
     2. recursive_scheduling.pl
     3. energy_module.pl
     4. tests.pl   ← ce fichier

   Lancer tous les tests :
     ?- run_all_tests.

   Lancer une section uniquement :
     ?- run_kb_tests.
     ?- run_scheduling_tests.
     ?- run_energy_tests.
   ============================================================ */


/* ============================================================
   INFRASTRUCTURE — runner isolé
   Chaque test est exécuté dans son propre call/1.
   Un test qui échoue affiche FAIL mais ne bloque pas les suivants.
   ============================================================ */

run_test(Label, Goal) :-
    format("  ~w ... ", [Label]),
    (call(Goal)
    ->  write('PASS'), nl
    ;   write('FAIL'), nl
    ).

run_all_tests :-
    nl,
    write('=============================================='), nl,
    write('  SUITE DE TESTS COMPLÈTE                    '), nl,
    write('=============================================='), nl,
    nl, write('--- 1. Knowledge Base ---'), nl,
    run_kb_tests,
    nl, write('--- 2. Recursive Scheduling ---'), nl,
    run_scheduling_tests,
    nl, write('--- 3. Energy Module ---'), nl,
    run_energy_tests,
    nl,
    write('=============================================='), nl,
    write('  FIN DES TESTS                              '), nl,
    write('=============================================='), nl.


/* ============================================================
   DONNÉES PARTAGÉES
   Définies une seule fois, réutilisées dans toutes les sections.
   ============================================================ */

mini_schedule([
    assignment(gl2_analyse2_td,    gl2_1, r203,  ts(lundi,1), toutes_semaines),
    assignment(gl2_algebre2_td,    gl2_2, r215,  ts(lundi,2), toutes_semaines),
    assignment(gl3_prog_logique,   gl3_1, r223,  ts(lundi,3), toutes_semaines),
    assignment(gl3_prog_logique_tp,gl3_1, li013, ts(lundi,4), semaine_a)
]).

overload_schedule([
    assignment(gl2_archi_res,     level(gl2), a1, ts(lundi,1), toutes_semaines),
    assignment(gl2_analyse2,      level(gl2), a2, ts(lundi,1), toutes_semaines),
    assignment(gl2_algebre2,      level(gl2), a5, ts(lundi,1), toutes_semaines),
    assignment(gl2_sgbd,          level(gl2), a6, ts(lundi,1), toutes_semaines),
    assignment(gl2_applic_rep,    level(gl2), a7, ts(lundi,1), toutes_semaines),
    assignment(gl2_csi,           level(gl2), a1, ts(lundi,2), toutes_semaines),
    assignment(gl2_droit,         level(gl2), a2, ts(lundi,2), toutes_semaines),
    assignment(gl2_comptabilite,  level(gl2), a5, ts(lundi,2), toutes_semaines),
    assignment(gl3_bases_rel,     level(gl3), a6, ts(lundi,2), toutes_semaines),
    assignment(gl3_fond_syst_rep, level(gl3), a7, ts(lundi,2), toutes_semaines),
    assignment(gl3_analyse_data,  level(gl3), a1, ts(lundi,3), toutes_semaines),
    assignment(gl3_co_design,     level(gl3), a2, ts(lundi,3), toutes_semaines),
    assignment(gl3_protoc_web,    level(gl3), a5, ts(lundi,3), toutes_semaines),
    assignment(gl3_methodo_conc,  level(gl3), a6, ts(lundi,3), toutes_semaines),
    assignment(gl3_marketing,     level(gl3), a7, ts(lundi,3), toutes_semaines),
    assignment(gl4_big_data,      level(gl4), a1, ts(lundi,4), toutes_semaines),
    assignment(gl4_archi_log,     level(gl4), a2, ts(lundi,4), toutes_semaines),
    assignment(gl4_protoc_secu,   level(gl4), a5, ts(lundi,4), toutes_semaines),
    assignment(gl4_management,    level(gl4), a6, ts(lundi,4), toutes_semaines),
    assignment(gl4_grh,           level(gl4), a7, ts(lundi,4), toutes_semaines)
]).


/* ============================================================
   SECTION 1 : KNOWLEDGE BASE
   Vérifie que les faits de la KB sont cohérents et accessibles.
   ============================================================ */

run_kb_tests :-
    run_test('equipment_ok — amphi pour cours amphi',
        equipment_ok(gl2_archi_res, a2)),

    run_test('equipment_ok — labo_pc pour TP',
        equipment_ok(gl3_prog_logique_tp, li013)),

    run_test('equipment_ok — salle_td pour TD',
        equipment_ok(gl2_analyse2_td, r203)),

    run_test('equipment_ok — rejet salle_td pour amphi',
        \+ equipment_ok(gl2_archi_res, r203)),

    run_test('capacity_ok_for_group — salle suffisante (gl3_1, r223)',
        capacity_ok_for_group(gl3_1, r223)),

    run_test('capacity_ok_for_group — rejet labo trop petit pour gl3_1',
        \+ capacity_ok_for_group(gl3_1, li013)),

    run_test('instructor_available_ok — khalgui lundi slot 1',
        instructor_available_ok(gl3_prog_logique, ts(lundi,1))),

    run_test('instructor_available_ok — rejet créneau indisponible',
        \+ instructor_available_ok(gl3_prog_logique, ts(samedi,2))),

    run_test('room_building — li013 dans bat_labo',
        room_building(li013, bat_labo)),

    run_test('room_energy_cost — coût r203 = 3',
        ( room_energy_cost(r203, C), C =:= 3 )),

    run_test('building_energy_max — bat_amphi = 80',
        ( building_energy_max(bat_amphi, M), M =:= 80 )),

    run_test('level_groups — gl3 a 2 groupes',
        ( level_groups(gl3, Gs), length(Gs, 2) )).


/* ============================================================
   SECTION 2 : RECURSIVE SCHEDULING (Part C)
   ============================================================ */

run_scheduling_tests :-
    % --- Génération de sessions ---
    run_test('sessions_to_schedule_v2 gl3 — non vide',
        ( sessions_to_schedule_v2(gl3, Ss), Ss \= [] )),

    run_test('sessions_to_schedule_v2 gl2 — non vide',
        ( sessions_to_schedule_v2(gl2, Ss), Ss \= [] )),

    run_test('sessions_to_schedule_v2 gl4 — non vide',
        ( sessions_to_schedule_v2(gl4, Ss), Ss \= [] )),

    run_test('all_sessions — agrège les 3 niveaux',
        ( all_sessions(Ss), length(Ss, N), N > 0 )),

    % --- valid_assignment_v2 ---
    run_test('valid_assignment_v2 — session TD sur partial vide',
        valid_assignment_v2(
            session(gl3_prog_logique, gl3_1, toutes_semaines),
            _, _, [])),

    run_test('valid_assignment_v2 — session amphi sur partial vide',
        valid_assignment_v2(
            session(gl2_archi_res, level(gl2), toutes_semaines),
            _, _, [])),

    % --- Contraintes de conflit sur mini_schedule ---
    mini_schedule(Mini),

    run_test('no_room_conflict — détecte collision r203/lundi-1',
        \+ no_room_conflict(r203, ts(lundi,1), Mini)),

    run_test('no_room_conflict — accepte salle libre',
        no_room_conflict(r247, ts(lundi,1), Mini)),

    run_test('no_group_conflict — détecte gl2_1 occupé lundi-1',
        \+ no_group_conflict(gl2_csi_td, gl2_1, ts(lundi,1), Mini)),

    run_test('no_group_conflict — accepte groupe libre',
        no_group_conflict(gl2_csi_td, gl2_3, ts(lundi,1), Mini)),

    run_test('no_instructor_conflict — détecte conflit trigui lundi-2',
        \+ no_instructor_conflict(gl2_analyse2_td, ts(lundi,2), Mini)),

    % --- Génération complète ---
    run_test('generate_schedule_level gl3 — produit un plan',
        ( generate_schedule_level(gl3, S), S \= [] )),

    run_test('schedule résultat — toutes les entrées sont assignment/5',
        (   generate_schedule_level(gl3, S),
            forall(member(A, S),
                   A = assignment(_, _, _, _, _))
        )),

    % --- test_mini équivalent ---
    run_test('schedule 2 sessions gl3_prog_logique — pas de conflit groupe',
        (   schedule([
                session(gl3_prog_logique, gl3_1, toutes_semaines),
                session(gl3_prog_logique, gl3_2, toutes_semaines)
            ], Plan),
            \+ ( member(assignment(_, gl3_1, _, Ts, _), Plan),
                 member(assignment(_, gl3_2, _, Ts, _), Plan) )
        )).


/* ============================================================
   SECTION 3 : ENERGY MODULE (Part 3)
   ============================================================ */

run_energy_tests :-
    % --- session_energy ---
    run_test('session_energy salle_td r203 = 3',
        ( session_energy(r203, gl2_analyse2_td, E), E =:= 3 )),

    run_test('session_energy labo_pc li013 = 8',
        ( session_energy(li013, gl3_prog_logique_tp, E), E =:= 8 )),

    run_test('session_energy amphi a2 = 4',
        ( session_energy(a2, gl2_archi_res, E), E =:= 4 )),

    run_test('session_energy amphi a7 = 5',
        ( session_energy(a7, gl2_archi_res, E), E =:= 5 )),

    % --- respect_emax ---
    run_test('respect_emax bat_labo 100 — passe',
        respect_emax(bat_labo, 100)),

    run_test('respect_emax bat_labo 200 — limite exacte passe',
        respect_emax(bat_labo, 200)),

    run_test('respect_emax bat_labo 201 — violation bloquée',
        \+ respect_emax(bat_labo, 201)),

    run_test('respect_emax bat_cours 60 — limite exacte passe',
        respect_emax(bat_cours, 60)),

    run_test('respect_emax bat_cours 61 — violation bloquée',
        \+ respect_emax(bat_cours, 61)),

    run_test('respect_emax bat_amphi 80 — limite exacte passe',
        respect_emax(bat_amphi, 80)),

    run_test('respect_emax bat_amphi 81 — violation bloquée',
        \+ respect_emax(bat_amphi, 81)),

    % --- building_day_energy ---
    mini_schedule(Mini),

    run_test('bat_cours / lundi = 9',
        ( building_day_energy(Mini, bat_cours, lundi, E), E =:= 9 )),

    run_test('bat_labo / lundi = 8',
        ( building_day_energy(Mini, bat_labo, lundi, E), E =:= 8 )),

    run_test('bat_amphi / lundi = 0 (aucune session amphi)',
        ( building_day_energy(Mini, bat_amphi, lundi, E), E =:= 0 )),

    run_test('bat_cours / mardi = 0 (aucune session mardi)',
        ( building_day_energy(Mini, bat_cours, mardi, E), E =:= 0 )),

    % --- total_weekly_energy ---
    run_test('total_weekly_energy mini = 17',
        ( total_weekly_energy(Mini, E), E =:= 17 )),

    % --- check_all_energy_constraints ---
    run_test('HC-6 respectée sur mini schedule',
        check_all_energy_constraints(Mini)),

    overload_schedule(Over),

    run_test('HC-6 violation détectée sur overload schedule',
        \+ check_all_energy_constraints(Over)),

    run_test('bat_amphi / lundi > 80 sur overload (valeur = 85)',
        ( building_day_energy(Over, bat_amphi, lundi, E), E =:= 85 )),

    % --- schedule_with_energy ---
    run_test('generate_schedule_level_with_energy gl3 — produit un plan',
        ( generate_schedule_level_with_energy(gl3, S), S \= [] )),

    run_test('schedule_with_energy — HC-6 respectée sur le résultat',
        (   generate_schedule_level_with_energy(gl3, S),
            check_all_energy_constraints(S)
        )).