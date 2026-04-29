:- encoding(utf8).

/* ============================================================
   tests.pl — Suite de tests alignée sur cost/3
   ============================================================ */

run_test(Label, Goal) :-
    format("  ~w ... ", [Label]),
    (   once(call(Goal))
    ->  write('PASS'), nl
    ;   write('FAIL'), nl
    ).

run_all_tests :-
    reset_room_occupancy,
    reset_remaining_hours,
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


mini_schedule([
    assignment(gl2_analyse2_td1,   gl2_1, r203,  ts(lundi,1)),
    assignment(gl2_algebre2_td2,   gl2_2, r215,  ts(lundi,2)),
    assignment(gl3_prog_logique_td1, gl3_1, r223,  ts(lundi,3)),
    assignment(gl3_prog_logique_tp1, gl3_1, li013, ts(lundi,4))
]).

overload_schedule([
    assignment(gl2_archi_res_cours,     level(gl2), a1, ts(lundi,1)),
    assignment(gl2_analyse2_cours,      level(gl2), a2, ts(lundi,1)),
    assignment(gl2_algebre2_cours,      level(gl2), a5, ts(lundi,1)),
    assignment(gl2_sgbd_cours,          level(gl2), a6, ts(lundi,1)),
    assignment(gl2_applic_rep_cours,    level(gl2), a7, ts(lundi,1)),
    assignment(gl2_csi_cours,           level(gl2), a1, ts(lundi,2)),
    assignment(gl2_droit_cours,         level(gl2), a2, ts(lundi,2)),
    assignment(gl2_comptabilite_cours,  level(gl2), a5, ts(lundi,2)),
    assignment(gl3_bases_rel_cours,     level(gl3), a6, ts(lundi,2)),
    assignment(gl3_fond_syst_rep_cours, level(gl3), a7, ts(lundi,2)),
    assignment(gl3_analyse_data_cours,  level(gl3), a1, ts(lundi,3)),
    assignment(gl3_co_design_cours,     level(gl3), a2, ts(lundi,3)),
    assignment(gl3_protoc_web_cours,    level(gl3), a5, ts(lundi,3)),
    assignment(gl3_methodo_conc_cours,  level(gl3), a6, ts(lundi,3)),
    assignment(gl3_marketing_cours,     level(gl3), a7, ts(lundi,3)),
    assignment(gl4_big_data_cours,      level(gl4), a1, ts(lundi,4)),
    assignment(gl4_archi_log_cours,     level(gl4), a2, ts(lundi,4)),
    assignment(gl4_protoc_secu_cours,   level(gl4), a5, ts(lundi,4)),
    assignment(gl4_management_cours,    level(gl4), a6, ts(lundi,4)),
    assignment(gl4_grh_cours,           level(gl4), a7, ts(lundi,4))
]).


run_kb_tests :-
    run_test('equipment_ok — amphi pour cours commun',
        equipment_ok(gl2_archi_res_cours, a2)),

    run_test('equipment_ok — labo_pc pour TP',
        equipment_ok(gl3_prog_logique_tp1, li013)),

    run_test('equipment_ok — salle_td pour TD',
        equipment_ok(gl2_analyse2_td1, r203)),

    run_test('equipment_ok — rejet salle_td pour cours commun',
        \+ equipment_ok(gl2_archi_res_cours, r203)),

    run_test('capacity_ok_for_group — salle suffisante (gl3_1, r223)',
        capacity_ok_for_group(gl3_1, r223)),

    run_test('capacity_ok_for_group — rejet labo trop petit pour gl3_1',
        \+ capacity_ok_for_group(gl3_1, li013)),

    run_test('instructor_available_ok — prog_logique_td1 lundi slot 1',
        instructor_available_ok(gl3_prog_logique_td1, ts(lundi,1))),

    run_test('instructor_available_ok — rejet créneau indisponible',
        \+ instructor_available_ok(gl3_prog_logique_td1, ts(samedi,2))),

    run_test('room_building — li013 dans bat_labo',
        room_building(li013, bat_labo)),

    run_test('room_energy_cost — coût r203 = 3',
        ( room_energy_cost(r203, C), C =:= 3 )),

    run_test('building_energy_max — bat_amphi = 80',
        ( building_energy_max(bat_amphi, M), M =:= 80 )),

    run_test('level_groups — gl3 a 2 groupes',
        ( level_groups(gl3, Gs), length(Gs, 2) )).


run_scheduling_tests :-
    run_test('sessions_to_schedule_v2 gl3 — non vide',
        ( sessions_to_schedule_v2(gl3, Ss), Ss \= [] )),

    run_test('sessions_to_schedule_v2 gl2 — non vide',
        ( sessions_to_schedule_v2(gl2, Ss), Ss \= [] )),

    run_test('sessions_to_schedule_v2 gl4 — non vide',
        ( sessions_to_schedule_v2(gl4, Ss), Ss \= [] )),

    run_test('all_sessions — agrège les 3 niveaux',
        ( all_sessions(Ss), length(Ss, N), N > 0 )),

    run_test('no_instructor_conflict — détecte conflit trigui lundi-1',
        ( mini_schedule(Mini),
          \+ no_instructor_conflict(gl2_analyse2_cours, ts(lundi,1), Mini) )),

    run_test('valid_assignment_v2 — session TD sur partial vide',
        valid_assignment_v2(
            session(gl3_prog_logique_td1, gl3_1),
            _, _, [])),

    run_test('valid_assignment_v2 — session cours commun sur partial vide',
        valid_assignment_v2(
            session(gl2_archi_res_cours, level(gl2)),
            _, _, [])),

    mini_schedule(Mini),

    run_test('no_room_conflict — détecte collision r203/lundi-1',
        \+ no_room_conflict(r203, ts(lundi,1), Mini)),

    run_test('no_room_conflict — accepte salle libre',
        no_room_conflict(r247, ts(lundi,1), Mini)),

    run_test('no_group_conflict — détecte gl2_1 occupé lundi-1',
        \+ no_group_conflict(gl2_csi_td1, gl2_1, ts(lundi,1), Mini)),

    run_test('no_group_conflict — accepte groupe libre',
        no_group_conflict(gl2_csi_td1, gl2_3, ts(lundi,1), Mini)),

    run_test('no_instructor_conflict — détecte conflit khalgui lundi-3',
        \+ no_instructor_conflict(gl3_prog_logique_td2, ts(lundi,3), Mini)),

    run_test('generate_schedule_level_raw gl3 — produit un plan',
        ( generate_schedule_level_raw(gl3, S), S \= [] )),

    run_test('schedule résultat — toutes les entrées sont assignment/4',
        (   generate_schedule_level_raw(gl3, S),
            forall(member(A, S), A = assignment(_, _, _, _))
        )),

    run_test('schedule 2 sessions prog_logique — pas de conflit groupe',
        (   schedule([
                session(gl3_prog_logique_td1, gl3_1),
                session(gl3_prog_logique_td2, gl3_2)
            ], Plan),
            \+ ( member(assignment(_, gl3_1, _, Ts), Plan),
                 member(assignment(_, gl3_2, _, Ts), Plan) )
        )).


run_energy_tests :-
    run_test('session_energy salle_td r203 = 4.5',
        ( session_energy(r203, gl2_analyse2_td1, E), E =:= 4.5 )),

    run_test('session_energy labo_pc li013 = 12',
        ( session_energy(li013, gl3_prog_logique_tp1, E), E =:= 12 )),

    run_test('session_energy amphi a2 = 6',
        ( session_energy(a2, gl2_archi_res_cours, E), E =:= 6 )),

    run_test('session_energy amphi a7 = 7.5',
        ( session_energy(a7, gl2_archi_res_cours, E), E =:= 7.5 )),

    run_test('respect_emax bat_labo 100 — passe',
        respect_emax(bat_labo, 100)),

    run_test('respect_emax bat_labo 200 — limite exacte passe',
        respect_emax(bat_labo, 200)),

    run_test('respect_emax bat_labo 201 — violation bloquée',
        \+ respect_emax(bat_labo, 201)),

    mini_schedule(Mini),

    run_test('bat_cours / lundi = 13.5',
        ( building_day_energy(Mini, bat_cours, lundi, E), E =:= 13.5 )),

    run_test('bat_labo / lundi = 12',
        ( building_day_energy(Mini, bat_labo, lundi, E), E =:= 12 )),

    run_test('bat_amphi / lundi = 0 (aucune session amphi)',
        ( building_day_energy(Mini, bat_amphi, lundi, E), E =:= 0 )),

    run_test('total_weekly_energy mini = 25.5',
        ( total_weekly_energy(Mini, E), E =:= 25.5 )),

    run_test('HC-6 respectée sur mini schedule',
        check_all_energy_constraints(Mini)),

    overload_schedule(Over),

    run_test('HC-6 violation détectée sur overload schedule',
        \+ check_all_energy_constraints(Over)),

    run_test('bat_amphi / lundi > 80 sur overload (valeur = 127.5)',
        ( building_day_energy(Over, bat_amphi, lundi, E), E =:= 127.5 )),

    run_test('generate_schedule_level_with_energy_raw gl3 — produit un plan',
        ( generate_schedule_level_with_energy_raw(gl3, S), S \= [] )),

    run_test('schedule_with_energy — HC-6 respectée sur le résultat',
        (   generate_schedule_level_with_energy_raw(gl3, S),
            check_all_energy_constraints(S)
        )).
