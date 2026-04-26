/* ============================================================
   INTELLIGENT ENERGY-AWARE CAMPUS SCHEDULING SYSTEM
   Authors : Minyar Frifita
   Projet   : Prolog
   Version  : 3 — sans sous-groupes a/b
   ============================================================

   LOGIQUE DE PLANIFICATION :
     • Cours (amphi)  : tout le niveau ensemble (gl2 / gl3 / gl4)
                        → 1 seule séance, même salle, même créneau
     • TD             : chaque groupe indépendamment
                        (gl3_1 seul, gl3_2 seul, créneaux séparés)
     • TP quinzaine   : course_quinzaine/1 marqué dans la KB
                        → 1 séance par groupe, tagué semaine_a ou semaine_b

   SECTIONS :
     1  — Créneaux horaires
     2  — Bâtiments
     3  — Salles
     4  — Groupes
     5  — Enseignants
     6  — Cours (GL2 + GL3 + GL4)
     7  — Propriétés des cours
     8  — Disponibilités enseignants
     9  — Type de cours (amphi / td / tp_quinzaine)
     10 — Contraintes hard
     11 — Prédicats clés (interface → Part C)
     12 — Utilitaires
   ============================================================
*/

:- discontiguous course_sessions/2.
:- discontiguous course_duration/2.
:- discontiguous course_group/2.
:- discontiguous course_instructor/2.
:- discontiguous course_equipment/2.
:- discontiguous course_type/2.
:- discontiguous course_quinzaine/1.

/* ============================================================
   SECTION 1 : CRÉNEAUX HORAIRES
   ============================================================ */

timeslot(ts(lundi,1),    lundi,    1,  480).
timeslot(ts(lundi,2),    lundi,    2,  585).
timeslot(ts(lundi,3),    lundi,    3,  840).
timeslot(ts(lundi,4),    lundi,    4,  945).
timeslot(ts(mardi,1),    mardi,    1,  480).
timeslot(ts(mardi,2),    mardi,    2,  585).
timeslot(ts(mardi,3),    mardi,    3,  840).
timeslot(ts(mardi,4),    mardi,    4,  945).
timeslot(ts(mercredi,1), mercredi, 1,  480).
timeslot(ts(mercredi,2), mercredi, 2,  585).
timeslot(ts(mercredi,3), mercredi, 3,  840).
timeslot(ts(mercredi,4), mercredi, 4,  945).
timeslot(ts(jeudi,1),    jeudi,    1,  480).
timeslot(ts(jeudi,2),    jeudi,    2,  585).
timeslot(ts(jeudi,3),    jeudi,    3,  840).
timeslot(ts(jeudi,4),    jeudi,    4,  945).
timeslot(ts(vendredi,1), vendredi, 1,  480).
timeslot(ts(vendredi,2), vendredi, 2,  585).
timeslot(ts(vendredi,3), vendredi, 3,  840).
timeslot(ts(vendredi,4), vendredi, 4,  945).
timeslot(ts(samedi,1),   samedi,   1,  480).
timeslot(ts(samedi,2),   samedi,   2,  585).


/* ============================================================
   SECTION 2 : BÂTIMENTS
   ============================================================ */

building(bat_amphi).
building(bat_cours).
building(bat_labo).

:- dynamic building_energy_max/2.
building_energy_max(bat_amphi, 80).
building_energy_max(bat_cours, 60).
building_energy_max(bat_labo,  200).


/* ============================================================
   SECTION 3 : SALLES
   ============================================================ */

room(a1). room(a2). room(a5). room(a6). room(a7).
room(r103). room(r105). room(r115).
room(r135). room(r145). room(r153).
room(r155). room(r169). room(r171).
room(r203). room(r209). room(r215).
room(r217). room(r219). room(r223).
room(r225). room(r227). room(r231).
room(r235). room(r239). room(r245).
room(r247).
room(li013). room(li116). room(li173).
room(li175). room(li177). room(li208).
room(li210). room(li212). room(li255).
room(li2121). room(li2121bis).

room_building(a1, bat_amphi). room_building(a2, bat_amphi).
room_building(a5, bat_amphi). room_building(a6, bat_amphi).
room_building(a7, bat_amphi).
room_building(r103, bat_cours). room_building(r105, bat_cours).
room_building(r115, bat_cours). room_building(r135, bat_cours).
room_building(r145, bat_cours). room_building(r153, bat_cours).
room_building(r155, bat_cours). room_building(r169, bat_cours).
room_building(r171, bat_cours). room_building(r203, bat_cours).
room_building(r209, bat_cours). room_building(r215, bat_cours).
room_building(r217, bat_cours). room_building(r219, bat_cours).
room_building(r223, bat_cours). room_building(r225, bat_cours).
room_building(r227, bat_cours). room_building(r231, bat_cours).
room_building(r235, bat_cours). room_building(r239, bat_cours).
room_building(r245, bat_cours). room_building(r247, bat_cours).
room_building(li013, bat_labo). room_building(li116, bat_labo).
room_building(li173, bat_labo). room_building(li175, bat_labo).
room_building(li177, bat_labo). room_building(li208, bat_labo).
room_building(li210, bat_labo). room_building(li212, bat_labo).
room_building(li255, bat_labo). room_building(li2121, bat_labo).
room_building(li2121bis, bat_labo).

room_capacity(a1,  100). room_capacity(a2,  200). room_capacity(a5,  100).
room_capacity(a6,  100). room_capacity(a7,  200).
room_capacity(r103, 50). room_capacity(r105, 50). room_capacity(r115, 50).
room_capacity(r135, 50). room_capacity(r145, 50). room_capacity(r153, 35).
room_capacity(r155, 35). room_capacity(r169, 35). room_capacity(r171, 35).
room_capacity(r203, 50). room_capacity(r209, 50). room_capacity(r215, 50).
room_capacity(r217, 50). room_capacity(r219, 50). room_capacity(r223, 50).
room_capacity(r225, 50). room_capacity(r227, 50). room_capacity(r231, 50).
room_capacity(r235, 50). room_capacity(r239, 50). room_capacity(r245, 50).
room_capacity(r247, 50).
room_capacity(li013, 24). room_capacity(li116, 24). room_capacity(li173, 24).
room_capacity(li175, 24). room_capacity(li177, 24). room_capacity(li208, 24).
room_capacity(li210, 24). room_capacity(li212, 24). room_capacity(li255, 24).
room_capacity(li2121, 30). room_capacity(li2121bis, 30).

room_equipment(a1, amphi). room_equipment(a2, amphi). room_equipment(a5, amphi).
room_equipment(a6, amphi). room_equipment(a7, amphi).
room_equipment(r103, salle_td). room_equipment(r105, salle_td).
room_equipment(r115, salle_td). room_equipment(r135, salle_td).
room_equipment(r145, salle_td). room_equipment(r153, salle_td).
room_equipment(r155, salle_td). room_equipment(r169, salle_td).
room_equipment(r171, salle_td). room_equipment(r203, salle_td).
room_equipment(r209, salle_td). room_equipment(r215, salle_td).
room_equipment(r217, salle_td). room_equipment(r219, salle_td).
room_equipment(r223, salle_td). room_equipment(r225, salle_td).
room_equipment(r227, salle_td). room_equipment(r231, salle_td).
room_equipment(r235, salle_td). room_equipment(r239, salle_td).
room_equipment(r245, salle_td). room_equipment(r247, salle_td).
room_equipment(li013, labo_pc). room_equipment(li116, labo_pc).
room_equipment(li173, labo_pc). room_equipment(li175, labo_pc).
room_equipment(li177, labo_pc). room_equipment(li208, labo_pc).
room_equipment(li210, labo_pc). room_equipment(li212, labo_pc).
room_equipment(li255, labo_pc). room_equipment(li2121, labo_pc).
room_equipment(li2121bis, labo_pc).

room_energy_cost(a1, 4). room_energy_cost(a2, 4). room_energy_cost(a5, 4).
room_energy_cost(a6, 4). room_energy_cost(a7, 5).
room_energy_cost(r103, 3). room_energy_cost(r105, 3). room_energy_cost(r115, 3).
room_energy_cost(r135, 3). room_energy_cost(r145, 3). room_energy_cost(r153, 3).
room_energy_cost(r155, 3). room_energy_cost(r169, 3). room_energy_cost(r171, 3).
room_energy_cost(r203, 3). room_energy_cost(r209, 3). room_energy_cost(r215, 3).
room_energy_cost(r217, 3). room_energy_cost(r219, 3). room_energy_cost(r223, 3).
room_energy_cost(r225, 3). room_energy_cost(r227, 3). room_energy_cost(r231, 3).
room_energy_cost(r235, 3). room_energy_cost(r239, 3). room_energy_cost(r245, 3).
room_energy_cost(r247, 3).
room_energy_cost(li013, 8). room_energy_cost(li116, 8). room_energy_cost(li173, 8).
room_energy_cost(li175, 8). room_energy_cost(li177, 8). room_energy_cost(li208, 8).
room_energy_cost(li210, 8). room_energy_cost(li212, 8). room_energy_cost(li255, 8).
room_energy_cost(li2121, 9). room_energy_cost(li2121bis, 9).


/* ============================================================
   SECTION 4 : GROUPES D'ÉTUDIANTS
   — Plus de sous-groupes a/b —
   ============================================================ */

group(gl2_1). group(gl2_2). group(gl2_3).
group(gl3_1). group(gl3_2).
group(gl4_1). group(gl4_2).

group_size(gl2_1, 35). group_size(gl2_2, 35). group_size(gl2_3, 35).
group_size(gl3_1, 45). group_size(gl3_2, 45).
group_size(gl4_1, 45). group_size(gl4_2, 45).

level_groups(gl2, [gl2_1, gl2_2, gl2_3]).
level_groups(gl3, [gl3_1, gl3_2]).
level_groups(gl4, [gl4_1, gl4_2]).

%% group_level(+Group, -Level)
group_level(G, Level) :-
    level_groups(Level, Gs),
    member(G, Gs).


/* ============================================================
   SECTION 5 : ENSEIGNANTS
   ============================================================ */

instructor(loukil_adlene).        instructor(trigui_elloumi_fatma).
instructor(hmida_jendoubi_nadia). instructor(soussi_yosra).
instructor(ben_rejeb_ihsen).      instructor(boukottaya_hanen).
instructor(baklouti_fatma).       instructor(bouaziz_samira).
instructor(mami_imen).            instructor(jemai_abderrazak).
instructor(ben_hassouna_asma).    instructor(bouzidi_sonia).
instructor(hanchi_thouraya).      instructor(sellaouti_aymen).
instructor(khalgui_mohamed).      instructor(ouni_sofiane).
instructor(arbi_adnen).           instructor(gasmi_ghada).
instructor(sfaxi_mourad).         instructor(mliki_hazar).
instructor(damergi_emir).         instructor(ben_gamra_imene).
instructor(zanina_wiem).          instructor(yaich_sameh).
instructor(bichiou_imene).        instructor(taktak_hajer).
instructor(ben_yahia_saloua).     instructor(hamdi_sana).
instructor(mzabi_hela).           instructor(abdelmoula_naouel).
instructor(sfaxi_lilia).          instructor(gasmi_maroua).
instructor(negra_amamou_bouthei).


/* ============================================================
   SECTION 6 : COURS
   ============================================================ */

course(gl2_archi_res).    course(gl2_archi_res_tdtp). course(gl2_analyse2).
course(gl2_analyse2_td).  course(gl2_algebre2).       course(gl2_algebre2_td).
course(gl2_sgbd).         course(gl2_sgbd_tp).        course(gl2_applic_rep).
course(gl2_applic_rep_tp). course(gl2_csi).           course(gl2_csi_td).
course(gl2_csi_tp).       course(gl2_atelier_java).   course(gl2_unix).
course(gl2_tech_web).     course(gl2_droit).          course(gl2_comptabilite).
course(gl2_anglais).

course(gl3_prog_logique).    course(gl3_prog_logique_tp). course(gl3_bases_rel).
course(gl3_bases_rel_td).    course(gl3_bases_nonrel).    course(gl3_fond_syst_rep).
course(gl3_fond_syst_rep_td). course(gl3_analyse_num).    course(gl3_analyse_data).
course(gl3_analyse_data_tp). course(gl3_algorithmique).   course(gl3_optimisation).
course(gl3_complexite).      course(gl3_co_design).       course(gl3_co_design_tp).
course(gl3_protoc_web).      course(gl3_protoc_web_tp).   course(gl3_methodo_conc).
course(gl3_methodo_conc_tp). course(gl3_marketing).       course(gl3_francais).
course(gl3_anglais).         course(gl3_ppp).

course(gl4_devops).          course(gl4_devops_tp).       course(gl4_deep_learning).
course(gl4_deep_learning_tp). course(gl4_compilation).    course(gl4_compilation_tp).
course(gl4_traitement_img).  course(gl4_traitement_img_tp). course(gl4_big_data).
course(gl4_big_data_tp).     course(gl4_archi_log).       course(gl4_archi_log_tp).
course(gl4_protoc_secu).     course(gl4_protoc_secu_tp).  course(gl4_ihm).
course(gl4_test_logiciel).   course(gl4_management).      course(gl4_grh).
course(gl4_anglais).


/* ============================================================
   SECTION 7 : PROPRIÉTÉS DES COURS
   ============================================================ */

% --- course_group ---
% Amphi  → groupes principaux du niveau (séance commune)
% TD/TP  → groupes principaux (chaque groupe assiste indépendamment)

% GL2
course_group(gl2_archi_res,      gl2_1). course_group(gl2_archi_res,      gl2_2). course_group(gl2_archi_res,      gl2_3).
course_group(gl2_analyse2,       gl2_1). course_group(gl2_analyse2,       gl2_2). course_group(gl2_analyse2,       gl2_3).
course_group(gl2_algebre2,       gl2_1). course_group(gl2_algebre2,       gl2_2). course_group(gl2_algebre2,       gl2_3).
course_group(gl2_sgbd,           gl2_1). course_group(gl2_sgbd,           gl2_2). course_group(gl2_sgbd,           gl2_3).
course_group(gl2_applic_rep,     gl2_1). course_group(gl2_applic_rep,     gl2_2). course_group(gl2_applic_rep,     gl2_3).
course_group(gl2_csi,            gl2_1). course_group(gl2_csi,            gl2_2). course_group(gl2_csi,            gl2_3).
course_group(gl2_droit,          gl2_1). course_group(gl2_droit,          gl2_2). course_group(gl2_droit,          gl2_3).
course_group(gl2_comptabilite,   gl2_1). course_group(gl2_comptabilite,   gl2_2). course_group(gl2_comptabilite,   gl2_3).
course_group(gl2_analyse2_td,    gl2_1). course_group(gl2_analyse2_td,    gl2_2). course_group(gl2_analyse2_td,    gl2_3).
course_group(gl2_algebre2_td,    gl2_1). course_group(gl2_algebre2_td,    gl2_2). course_group(gl2_algebre2_td,    gl2_3).
course_group(gl2_csi_td,         gl2_1). course_group(gl2_csi_td,         gl2_2). course_group(gl2_csi_td,         gl2_3).
course_group(gl2_anglais,        gl2_1). course_group(gl2_anglais,        gl2_2). course_group(gl2_anglais,        gl2_3).
course_group(gl2_archi_res_tdtp, gl2_1). course_group(gl2_archi_res_tdtp, gl2_2). course_group(gl2_archi_res_tdtp, gl2_3).
course_group(gl2_sgbd_tp,        gl2_1). course_group(gl2_sgbd_tp,        gl2_2). course_group(gl2_sgbd_tp,        gl2_3).
course_group(gl2_applic_rep_tp,  gl2_1). course_group(gl2_applic_rep_tp,  gl2_2). course_group(gl2_applic_rep_tp,  gl2_3).
course_group(gl2_csi_tp,         gl2_1). course_group(gl2_csi_tp,         gl2_2). course_group(gl2_csi_tp,         gl2_3).
course_group(gl2_atelier_java,   gl2_1). course_group(gl2_atelier_java,   gl2_2). course_group(gl2_atelier_java,   gl2_3).
course_group(gl2_unix,           gl2_1). course_group(gl2_unix,           gl2_2). course_group(gl2_unix,           gl2_3).
course_group(gl2_tech_web,       gl2_1). course_group(gl2_tech_web,       gl2_2). course_group(gl2_tech_web,       gl2_3).

% GL3
course_group(gl3_bases_rel,       gl3_1). course_group(gl3_bases_rel,       gl3_2).
course_group(gl3_fond_syst_rep,   gl3_1). course_group(gl3_fond_syst_rep,   gl3_2).
course_group(gl3_analyse_data,    gl3_1). course_group(gl3_analyse_data,    gl3_2).
course_group(gl3_marketing,       gl3_1). course_group(gl3_marketing,       gl3_2).
course_group(gl3_protoc_web,      gl3_1). course_group(gl3_protoc_web,      gl3_2).
course_group(gl3_methodo_conc,    gl3_1). course_group(gl3_methodo_conc,    gl3_2).
course_group(gl3_prog_logique,    gl3_1). course_group(gl3_prog_logique,    gl3_2).
course_group(gl3_algorithmique,   gl3_1). course_group(gl3_algorithmique,   gl3_2).
course_group(gl3_analyse_num,     gl3_1). course_group(gl3_analyse_num,     gl3_2).
course_group(gl3_optimisation,    gl3_1). course_group(gl3_optimisation,    gl3_2).
course_group(gl3_complexite,      gl3_1). course_group(gl3_complexite,      gl3_2).
course_group(gl3_co_design,       gl3_1). course_group(gl3_co_design,       gl3_2).
course_group(gl3_anglais,         gl3_1). course_group(gl3_anglais,         gl3_2).
course_group(gl3_francais,        gl3_1). course_group(gl3_francais,        gl3_2).
course_group(gl3_prog_logique_tp, gl3_1). course_group(gl3_prog_logique_tp, gl3_2).
course_group(gl3_bases_rel_td,    gl3_1). course_group(gl3_bases_rel_td,    gl3_2).
course_group(gl3_bases_nonrel,    gl3_1). course_group(gl3_bases_nonrel,    gl3_2).
course_group(gl3_fond_syst_rep_td,gl3_1). course_group(gl3_fond_syst_rep_td,gl3_2).
course_group(gl3_analyse_data_tp, gl3_1). course_group(gl3_analyse_data_tp, gl3_2).
course_group(gl3_co_design_tp,    gl3_1). course_group(gl3_co_design_tp,    gl3_2).
course_group(gl3_protoc_web_tp,   gl3_1). course_group(gl3_protoc_web_tp,   gl3_2).
course_group(gl3_methodo_conc_tp, gl3_1). course_group(gl3_methodo_conc_tp, gl3_2).
course_group(gl3_ppp,             gl3_1). course_group(gl3_ppp,             gl3_2).

% GL4
course_group(gl4_big_data,           gl4_1). course_group(gl4_big_data,           gl4_2).
course_group(gl4_archi_log,          gl4_1). course_group(gl4_archi_log,          gl4_2).
course_group(gl4_protoc_secu,        gl4_1). course_group(gl4_protoc_secu,        gl4_2).
course_group(gl4_management,         gl4_1). course_group(gl4_management,         gl4_2).
course_group(gl4_grh,                gl4_1). course_group(gl4_grh,                gl4_2).
course_group(gl4_devops,             gl4_1). course_group(gl4_devops,             gl4_2).
course_group(gl4_deep_learning,      gl4_1). course_group(gl4_deep_learning,      gl4_2).
course_group(gl4_compilation,        gl4_1). course_group(gl4_compilation,        gl4_2).
course_group(gl4_traitement_img,     gl4_1). course_group(gl4_traitement_img,     gl4_2).
course_group(gl4_test_logiciel,      gl4_1). course_group(gl4_test_logiciel,      gl4_2).
course_group(gl4_anglais,            gl4_1). course_group(gl4_anglais,            gl4_2).
course_group(gl4_devops_tp,          gl4_1). course_group(gl4_devops_tp,          gl4_2).
course_group(gl4_deep_learning_tp,   gl4_1). course_group(gl4_deep_learning_tp,   gl4_2).
course_group(gl4_compilation_tp,     gl4_1). course_group(gl4_compilation_tp,     gl4_2).
course_group(gl4_traitement_img_tp,  gl4_1). course_group(gl4_traitement_img_tp,  gl4_2).
course_group(gl4_big_data_tp,        gl4_1). course_group(gl4_big_data_tp,        gl4_2).
course_group(gl4_archi_log_tp,       gl4_1). course_group(gl4_archi_log_tp,       gl4_2).
course_group(gl4_protoc_secu_tp,     gl4_1). course_group(gl4_protoc_secu_tp,     gl4_2).
course_group(gl4_ihm,                gl4_1). course_group(gl4_ihm,                gl4_2).


% --- course_instructor ---

% GL2
course_instructor(gl2_archi_res,      loukil_adlene).
course_instructor(gl2_archi_res_tdtp, loukil_adlene).
course_instructor(gl2_analyse2,       trigui_elloumi_fatma).
course_instructor(gl2_analyse2_td,    trigui_elloumi_fatma).
course_instructor(gl2_algebre2,       hmida_jendoubi_nadia).
course_instructor(gl2_algebre2_td,    hmida_jendoubi_nadia).
course_instructor(gl2_algebre2_td,    soussi_yosra).
course_instructor(gl2_sgbd,           baklouti_fatma).
course_instructor(gl2_sgbd_tp,        baklouti_fatma).
course_instructor(gl2_applic_rep,     ben_hassouna_asma).
course_instructor(gl2_applic_rep_tp,  ben_hassouna_asma).
course_instructor(gl2_csi,            bouzidi_sonia).
course_instructor(gl2_csi_td,         bouzidi_sonia).
course_instructor(gl2_csi_tp,         hanchi_thouraya).
course_instructor(gl2_atelier_java,   jemai_abderrazak).
course_instructor(gl2_unix,           mami_imen).
course_instructor(gl2_tech_web,       sellaouti_aymen).
course_instructor(gl2_droit,          boukottaya_hanen).
course_instructor(gl2_comptabilite,   bouaziz_samira).
course_instructor(gl2_anglais,        ben_rejeb_ihsen).

% GL3
course_instructor(gl3_prog_logique,     khalgui_mohamed).
course_instructor(gl3_prog_logique_tp,  khalgui_mohamed).
course_instructor(gl3_bases_rel,        baklouti_fatma).
course_instructor(gl3_bases_rel_td,     baklouti_fatma).
course_instructor(gl3_bases_nonrel,     baklouti_fatma).
course_instructor(gl3_fond_syst_rep,    ouni_sofiane).
course_instructor(gl3_fond_syst_rep_td, ouni_sofiane).
course_instructor(gl3_analyse_num,      arbi_adnen).
course_instructor(gl3_analyse_data,     arbi_adnen).
course_instructor(gl3_analyse_data_tp,  arbi_adnen).
course_instructor(gl3_algorithmique,    gasmi_ghada).
course_instructor(gl3_optimisation,     sfaxi_mourad).
course_instructor(gl3_complexite,       mliki_hazar).
course_instructor(gl3_co_design,        damergi_emir).
course_instructor(gl3_co_design_tp,     damergi_emir).
course_instructor(gl3_protoc_web,       sellaouti_aymen).
course_instructor(gl3_protoc_web_tp,    sellaouti_aymen).
course_instructor(gl3_methodo_conc,     gasmi_ghada).
course_instructor(gl3_methodo_conc_tp,  gasmi_ghada).
course_instructor(gl3_marketing,        ben_gamra_imene).
course_instructor(gl3_francais,         zanina_wiem).
course_instructor(gl3_anglais,          bichiou_imene).
course_instructor(gl3_ppp,              taktak_hajer).

% GL4
course_instructor(gl4_devops,            ben_yahia_saloua).
course_instructor(gl4_devops_tp,         ben_yahia_saloua).
course_instructor(gl4_deep_learning,     hamdi_sana).
course_instructor(gl4_deep_learning_tp,  hamdi_sana).
course_instructor(gl4_compilation,       khalgui_mohamed).
course_instructor(gl4_compilation_tp,    khalgui_mohamed).
course_instructor(gl4_traitement_img,    bouzidi_sonia).
course_instructor(gl4_traitement_img_tp, bouzidi_sonia).
course_instructor(gl4_big_data,          sfaxi_lilia).
course_instructor(gl4_big_data_tp,       sfaxi_lilia).
course_instructor(gl4_archi_log,         sfaxi_lilia).
course_instructor(gl4_archi_log_tp,      sfaxi_lilia).
course_instructor(gl4_protoc_secu,       gasmi_maroua).
course_instructor(gl4_protoc_secu_tp,    gasmi_maroua).
course_instructor(gl4_ihm,               taktak_hajer).
course_instructor(gl4_test_logiciel,     bouzidi_sonia).
course_instructor(gl4_management,        abdelmoula_naouel).
course_instructor(gl4_grh,               mzabi_hela).
course_instructor(gl4_anglais,           negra_amamou_bouthei).


% --- course_equipment ---

% GL2
course_equipment(gl2_archi_res,      amphi).
course_equipment(gl2_archi_res_tdtp, labo_pc).
course_equipment(gl2_analyse2,       amphi).
course_equipment(gl2_analyse2_td,    salle_td).
course_equipment(gl2_algebre2,       amphi).
course_equipment(gl2_algebre2_td,    salle_td).
course_equipment(gl2_sgbd,           amphi).
course_equipment(gl2_sgbd_tp,        labo_pc).
course_equipment(gl2_applic_rep,     amphi).
course_equipment(gl2_applic_rep_tp,  labo_pc).
course_equipment(gl2_csi,            amphi).
course_equipment(gl2_csi_td,         salle_td).
course_equipment(gl2_csi_tp,         labo_pc).
course_equipment(gl2_atelier_java,   labo_pc).
course_equipment(gl2_unix,           labo_pc).
course_equipment(gl2_tech_web,       labo_pc).
course_equipment(gl2_droit,          amphi).
course_equipment(gl2_comptabilite,   amphi).
course_equipment(gl2_anglais,        salle_td).

% GL3
course_equipment(gl3_prog_logique,     salle_td).
course_equipment(gl3_prog_logique_tp,  labo_pc).
course_equipment(gl3_bases_rel,        amphi).
course_equipment(gl3_bases_rel_td,     salle_td).
course_equipment(gl3_bases_nonrel,     salle_td).
course_equipment(gl3_fond_syst_rep,    amphi).
course_equipment(gl3_fond_syst_rep_td, labo_pc).
course_equipment(gl3_analyse_num,      salle_td).
course_equipment(gl3_analyse_data,     amphi).
course_equipment(gl3_analyse_data_tp,  labo_pc).
course_equipment(gl3_algorithmique,    salle_td).
course_equipment(gl3_optimisation,     salle_td).
course_equipment(gl3_complexite,       salle_td).
course_equipment(gl3_co_design,        salle_td).
course_equipment(gl3_co_design_tp,     labo_pc).
course_equipment(gl3_protoc_web,       amphi).
course_equipment(gl3_protoc_web_tp,    labo_pc).
course_equipment(gl3_methodo_conc,     amphi).
course_equipment(gl3_methodo_conc_tp,  labo_pc).
course_equipment(gl3_marketing,        amphi).
course_equipment(gl3_francais,         salle_td).
course_equipment(gl3_anglais,          salle_td).
course_equipment(gl3_ppp,              labo_pc).

% GL4
course_equipment(gl4_devops,            salle_td).
course_equipment(gl4_devops_tp,         labo_pc).
course_equipment(gl4_deep_learning,     salle_td).
course_equipment(gl4_deep_learning_tp,  labo_pc).
course_equipment(gl4_compilation,       salle_td).
course_equipment(gl4_compilation_tp,    labo_pc).
course_equipment(gl4_traitement_img,    labo_pc).
course_equipment(gl4_traitement_img_tp, labo_pc).
course_equipment(gl4_big_data,          amphi).
course_equipment(gl4_big_data_tp,       labo_pc).
course_equipment(gl4_archi_log,         amphi).
course_equipment(gl4_archi_log_tp,      labo_pc).
course_equipment(gl4_protoc_secu,       amphi).
course_equipment(gl4_protoc_secu_tp,    labo_pc).
course_equipment(gl4_ihm,               labo_pc).
course_equipment(gl4_test_logiciel,     salle_td).
course_equipment(gl4_management,        amphi).
course_equipment(gl4_grh,               amphi).
course_equipment(gl4_anglais,           salle_td).


% --- course_sessions et course_duration ---

% GL2
course_sessions(gl2_archi_res,      1). course_duration(gl2_archi_res,      1).
course_sessions(gl2_archi_res_tdtp, 1). course_duration(gl2_archi_res_tdtp, 1).
course_sessions(gl2_analyse2,       1). course_duration(gl2_analyse2,       1).
course_sessions(gl2_analyse2_td,    1). course_duration(gl2_analyse2_td,    1).
course_sessions(gl2_algebre2,       1). course_duration(gl2_algebre2,       1).
course_sessions(gl2_algebre2_td,    1). course_duration(gl2_algebre2_td,    1).
course_sessions(gl2_sgbd,           1). course_duration(gl2_sgbd,           1).
course_sessions(gl2_sgbd_tp,        1). course_duration(gl2_sgbd_tp,        1).
course_sessions(gl2_applic_rep,     1). course_duration(gl2_applic_rep,     1).
course_sessions(gl2_applic_rep_tp,  1). course_duration(gl2_applic_rep_tp,  1).
course_sessions(gl2_csi,            1). course_duration(gl2_csi,            1).
course_sessions(gl2_csi_td,         1). course_duration(gl2_csi_td,         1).
course_sessions(gl2_csi_tp,         1). course_duration(gl2_csi_tp,         1).
course_sessions(gl2_atelier_java,   1). course_duration(gl2_atelier_java,   1).
course_sessions(gl2_unix,           1). course_duration(gl2_unix,           1).
course_sessions(gl2_tech_web,       1). course_duration(gl2_tech_web,       1).
course_sessions(gl2_droit,          1). course_duration(gl2_droit,          1).
course_sessions(gl2_comptabilite,   1). course_duration(gl2_comptabilite,   1).
course_sessions(gl2_anglais,        1). course_duration(gl2_anglais,        1).

% GL3
course_sessions(gl3_prog_logique,     1). course_duration(gl3_prog_logique,     1).
course_sessions(gl3_prog_logique_tp,  1). course_duration(gl3_prog_logique_tp,  1).
course_sessions(gl3_bases_rel,        1). course_duration(gl3_bases_rel,        1).
course_sessions(gl3_bases_rel_td,     1). course_duration(gl3_bases_rel_td,     1).
course_sessions(gl3_bases_nonrel,     1). course_duration(gl3_bases_nonrel,     1).
course_sessions(gl3_fond_syst_rep,    1). course_duration(gl3_fond_syst_rep,    1).
course_sessions(gl3_fond_syst_rep_td, 1). course_duration(gl3_fond_syst_rep_td, 1).
course_sessions(gl3_analyse_num,      1). course_duration(gl3_analyse_num,      1).
course_sessions(gl3_analyse_data,     1). course_duration(gl3_analyse_data,     1).
course_sessions(gl3_analyse_data_tp,  1). course_duration(gl3_analyse_data_tp,  1).
course_sessions(gl3_algorithmique,    1). course_duration(gl3_algorithmique,    1).
course_sessions(gl3_optimisation,     1). course_duration(gl3_optimisation,     1).
course_sessions(gl3_complexite,       1). course_duration(gl3_complexite,       1).
course_sessions(gl3_co_design,        1). course_duration(gl3_co_design,        1).
course_sessions(gl3_co_design_tp,     1). course_duration(gl3_co_design_tp,     1).
course_sessions(gl3_protoc_web,       1). course_duration(gl3_protoc_web,       1).
course_sessions(gl3_protoc_web_tp,    1). course_duration(gl3_protoc_web_tp,    1).
course_sessions(gl3_methodo_conc,     1). course_duration(gl3_methodo_conc,     1).
course_sessions(gl3_methodo_conc_tp,  1). course_duration(gl3_methodo_conc_tp,  1).
course_sessions(gl3_marketing,        1). course_duration(gl3_marketing,        1).
course_sessions(gl3_francais,         1). course_duration(gl3_francais,         1).
course_sessions(gl3_anglais,          1). course_duration(gl3_anglais,          1).
course_sessions(gl3_ppp,              1). course_duration(gl3_ppp,              1).

% GL4
course_sessions(gl4_devops,            1). course_duration(gl4_devops,            1).
course_sessions(gl4_devops_tp,         1). course_duration(gl4_devops_tp,         1).
course_sessions(gl4_deep_learning,     1). course_duration(gl4_deep_learning,     1).
course_sessions(gl4_deep_learning_tp,  1). course_duration(gl4_deep_learning_tp,  1).
course_sessions(gl4_compilation,       1). course_duration(gl4_compilation,       1).
course_sessions(gl4_compilation_tp,    1). course_duration(gl4_compilation_tp,    1).
course_sessions(gl4_traitement_img,    1). course_duration(gl4_traitement_img,    1).
course_sessions(gl4_traitement_img_tp, 1). course_duration(gl4_traitement_img_tp, 1).
course_sessions(gl4_big_data,          1). course_duration(gl4_big_data,          1).
course_sessions(gl4_big_data_tp,       1). course_duration(gl4_big_data_tp,       1).
course_sessions(gl4_archi_log,         1). course_duration(gl4_archi_log,         1).
course_sessions(gl4_archi_log_tp,      1). course_duration(gl4_archi_log_tp,      1).
course_sessions(gl4_protoc_secu,       1). course_duration(gl4_protoc_secu,       1).
course_sessions(gl4_protoc_secu_tp,    1). course_duration(gl4_protoc_secu_tp,    1).
course_sessions(gl4_ihm,               1). course_duration(gl4_ihm,               1).
course_sessions(gl4_test_logiciel,     1). course_duration(gl4_test_logiciel,     1).
course_sessions(gl4_management,        1). course_duration(gl4_management,        1).
course_sessions(gl4_grh,               1). course_duration(gl4_grh,               1).
course_sessions(gl4_anglais,           1). course_duration(gl4_anglais,           1).


/* ============================================================
   SECTION 8 : DISPONIBILITÉS DES ENSEIGNANTS
   ============================================================ */

instructor_available(khalgui_mohamed, ts(lundi,1)).
instructor_available(khalgui_mohamed, ts(lundi,2)).
instructor_available(khalgui_mohamed, ts(lundi,3)).
instructor_available(khalgui_mohamed, ts(lundi,4)).
instructor_available(khalgui_mohamed, ts(mardi,1)).
instructor_available(khalgui_mohamed, ts(mardi,2)).
instructor_available(khalgui_mohamed, ts(mardi,3)).
instructor_available(khalgui_mohamed, ts(mercredi,1)).
instructor_available(khalgui_mohamed, ts(mercredi,2)).
instructor_available(khalgui_mohamed, ts(mercredi,3)).
instructor_available(khalgui_mohamed, ts(jeudi,1)).
instructor_available(khalgui_mohamed, ts(jeudi,2)).
instructor_available(khalgui_mohamed, ts(vendredi,1)).
instructor_available(khalgui_mohamed, ts(vendredi,2)).

instructor_available(baklouti_fatma, ts(lundi,1)).
instructor_available(baklouti_fatma, ts(lundi,2)).
instructor_available(baklouti_fatma, ts(lundi,3)).
instructor_available(baklouti_fatma, ts(mardi,2)).
instructor_available(baklouti_fatma, ts(mardi,3)).
instructor_available(baklouti_fatma, ts(mardi,4)).
instructor_available(baklouti_fatma, ts(mercredi,1)).
instructor_available(baklouti_fatma, ts(mercredi,2)).
instructor_available(baklouti_fatma, ts(jeudi,1)).
instructor_available(baklouti_fatma, ts(jeudi,2)).
instructor_available(baklouti_fatma, ts(vendredi,1)).
instructor_available(baklouti_fatma, ts(vendredi,2)).

instructor_available(loukil_adlene, ts(lundi,1)).
instructor_available(loukil_adlene, ts(lundi,2)).
instructor_available(loukil_adlene, ts(lundi,3)).
instructor_available(loukil_adlene, ts(mardi,1)).
instructor_available(loukil_adlene, ts(mercredi,1)).
instructor_available(loukil_adlene, ts(mercredi,2)).
instructor_available(loukil_adlene, ts(mercredi,3)).
instructor_available(loukil_adlene, ts(jeudi,1)).
instructor_available(loukil_adlene, ts(vendredi,1)).
instructor_available(loukil_adlene, ts(vendredi,2)).
instructor_available(loukil_adlene, ts(vendredi,3)).

instructor_available(trigui_elloumi_fatma, ts(lundi,2)).
instructor_available(trigui_elloumi_fatma, ts(lundi,3)).
instructor_available(trigui_elloumi_fatma, ts(mardi,1)).
instructor_available(trigui_elloumi_fatma, ts(mardi,2)).
instructor_available(trigui_elloumi_fatma, ts(mercredi,1)).
instructor_available(trigui_elloumi_fatma, ts(mercredi,2)).
instructor_available(trigui_elloumi_fatma, ts(jeudi,1)).
instructor_available(trigui_elloumi_fatma, ts(jeudi,2)).
instructor_available(trigui_elloumi_fatma, ts(vendredi,4)).

instructor_available(hmida_jendoubi_nadia, ts(lundi,3)).
instructor_available(hmida_jendoubi_nadia, ts(mardi,1)).
instructor_available(hmida_jendoubi_nadia, ts(mardi,2)).
instructor_available(hmida_jendoubi_nadia, ts(mercredi,1)).
instructor_available(hmida_jendoubi_nadia, ts(jeudi,2)).
instructor_available(hmida_jendoubi_nadia, ts(vendredi,1)).
instructor_available(hmida_jendoubi_nadia, ts(vendredi,2)).

instructor_available(soussi_yosra, ts(lundi,2)).
instructor_available(soussi_yosra, ts(lundi,4)).
instructor_available(soussi_yosra, ts(mardi,1)).
instructor_available(soussi_yosra, ts(mercredi,1)).
instructor_available(soussi_yosra, ts(jeudi,3)).
instructor_available(soussi_yosra, ts(vendredi,1)).

instructor_available(ben_rejeb_ihsen, ts(lundi,4)).
instructor_available(ben_rejeb_ihsen, ts(mardi,1)).
instructor_available(ben_rejeb_ihsen, ts(mardi,2)).
instructor_available(ben_rejeb_ihsen, ts(mercredi,1)).
instructor_available(ben_rejeb_ihsen, ts(mercredi,3)).
instructor_available(ben_rejeb_ihsen, ts(jeudi,1)).
instructor_available(ben_rejeb_ihsen, ts(vendredi,1)).

instructor_available(boukottaya_hanen, ts(lundi,1)).
instructor_available(boukottaya_hanen, ts(mardi,2)).
instructor_available(boukottaya_hanen, ts(mardi,3)).
instructor_available(boukottaya_hanen, ts(mercredi,1)).
instructor_available(boukottaya_hanen, ts(jeudi,1)).
instructor_available(boukottaya_hanen, ts(vendredi,1)).

instructor_available(bouaziz_samira, ts(lundi,1)).
instructor_available(bouaziz_samira, ts(lundi,2)).
instructor_available(bouaziz_samira, ts(mardi,1)).
instructor_available(bouaziz_samira, ts(mercredi,1)).
instructor_available(bouaziz_samira, ts(jeudi,1)).
instructor_available(bouaziz_samira, ts(vendredi,1)).

instructor_available(mami_imen, ts(lundi,1)).
instructor_available(mami_imen, ts(lundi,2)).
instructor_available(mami_imen, ts(mardi,3)).
instructor_available(mami_imen, ts(mardi,4)).
instructor_available(mami_imen, ts(mercredi,1)).
instructor_available(mami_imen, ts(jeudi,1)).
instructor_available(mami_imen, ts(vendredi,1)).
instructor_available(mami_imen, ts(vendredi,4)).

instructor_available(jemai_abderrazak, ts(lundi,1)).
instructor_available(jemai_abderrazak, ts(lundi,2)).
instructor_available(jemai_abderrazak, ts(mardi,3)).
instructor_available(jemai_abderrazak, ts(mardi,4)).
instructor_available(jemai_abderrazak, ts(mercredi,1)).
instructor_available(jemai_abderrazak, ts(mercredi,2)).
instructor_available(jemai_abderrazak, ts(jeudi,1)).
instructor_available(jemai_abderrazak, ts(vendredi,1)).

instructor_available(ben_hassouna_asma, ts(lundi,1)).
instructor_available(ben_hassouna_asma, ts(lundi,2)).
instructor_available(ben_hassouna_asma, ts(mardi,1)).
instructor_available(ben_hassouna_asma, ts(mercredi,1)).
instructor_available(ben_hassouna_asma, ts(jeudi,3)).
instructor_available(ben_hassouna_asma, ts(jeudi,4)).
instructor_available(ben_hassouna_asma, ts(vendredi,1)).

instructor_available(bouzidi_sonia, ts(lundi,2)).
instructor_available(bouzidi_sonia, ts(mardi,1)).
instructor_available(bouzidi_sonia, ts(mardi,2)).
instructor_available(bouzidi_sonia, ts(mercredi,1)).
instructor_available(bouzidi_sonia, ts(mercredi,2)).
instructor_available(bouzidi_sonia, ts(jeudi,1)).
instructor_available(bouzidi_sonia, ts(vendredi,1)).
instructor_available(bouzidi_sonia, ts(vendredi,2)).

instructor_available(hanchi_thouraya, ts(lundi,4)).
instructor_available(hanchi_thouraya, ts(mardi,3)).
instructor_available(hanchi_thouraya, ts(mardi,4)).
instructor_available(hanchi_thouraya, ts(mercredi,1)).
instructor_available(hanchi_thouraya, ts(vendredi,2)).
instructor_available(hanchi_thouraya, ts(vendredi,3)).

instructor_available(sellaouti_aymen, ts(lundi,1)).
instructor_available(sellaouti_aymen, ts(lundi,2)).
instructor_available(sellaouti_aymen, ts(mardi,1)).
instructor_available(sellaouti_aymen, ts(mercredi,1)).
instructor_available(sellaouti_aymen, ts(jeudi,4)).
instructor_available(sellaouti_aymen, ts(vendredi,1)).
instructor_available(sellaouti_aymen, ts(samedi,1)).
instructor_available(sellaouti_aymen, ts(samedi,2)).

instructor_available(ouni_sofiane, ts(lundi,1)).
instructor_available(ouni_sofiane, ts(lundi,2)).
instructor_available(ouni_sofiane, ts(lundi,3)).
instructor_available(ouni_sofiane, ts(mardi,1)).
instructor_available(ouni_sofiane, ts(mercredi,2)).
instructor_available(ouni_sofiane, ts(mercredi,3)).
instructor_available(ouni_sofiane, ts(jeudi,1)).
instructor_available(ouni_sofiane, ts(vendredi,1)).

instructor_available(arbi_adnen, ts(lundi,1)).
instructor_available(arbi_adnen, ts(lundi,2)).
instructor_available(arbi_adnen, ts(lundi,3)).
instructor_available(arbi_adnen, ts(lundi,4)).
instructor_available(arbi_adnen, ts(mardi,1)).
instructor_available(arbi_adnen, ts(mardi,2)).
instructor_available(arbi_adnen, ts(mercredi,1)).
instructor_available(arbi_adnen, ts(jeudi,1)).
instructor_available(arbi_adnen, ts(vendredi,1)).
instructor_available(arbi_adnen, ts(vendredi,4)).

instructor_available(gasmi_ghada, ts(lundi,1)).
instructor_available(gasmi_ghada, ts(lundi,2)).
instructor_available(gasmi_ghada, ts(lundi,3)).
instructor_available(gasmi_ghada, ts(mardi,1)).
instructor_available(gasmi_ghada, ts(mardi,2)).
instructor_available(gasmi_ghada, ts(mercredi,1)).
instructor_available(gasmi_ghada, ts(jeudi,1)).
instructor_available(gasmi_ghada, ts(vendredi,2)).
instructor_available(gasmi_ghada, ts(vendredi,3)).

instructor_available(sfaxi_mourad, ts(lundi,1)).
instructor_available(sfaxi_mourad, ts(lundi,2)).
instructor_available(sfaxi_mourad, ts(lundi,3)).
instructor_available(sfaxi_mourad, ts(mardi,1)).
instructor_available(sfaxi_mourad, ts(mercredi,1)).
instructor_available(sfaxi_mourad, ts(mercredi,2)).
instructor_available(sfaxi_mourad, ts(jeudi,1)).
instructor_available(sfaxi_mourad, ts(vendredi,4)).

instructor_available(mliki_hazar, ts(lundi,1)).
instructor_available(mliki_hazar, ts(lundi,2)).
instructor_available(mliki_hazar, ts(mardi,1)).
instructor_available(mliki_hazar, ts(mardi,2)).
instructor_available(mliki_hazar, ts(mercredi,1)).
instructor_available(mliki_hazar, ts(jeudi,4)).
instructor_available(mliki_hazar, ts(vendredi,4)).

instructor_available(damergi_emir, ts(lundi,1)).
instructor_available(damergi_emir, ts(lundi,2)).
instructor_available(damergi_emir, ts(mardi,1)).
instructor_available(damergi_emir, ts(mercredi,1)).
instructor_available(damergi_emir, ts(jeudi,3)).
instructor_available(damergi_emir, ts(jeudi,4)).

instructor_available(ben_gamra_imene, ts(lundi,1)).
instructor_available(ben_gamra_imene, ts(lundi,2)).
instructor_available(ben_gamra_imene, ts(mardi,1)).
instructor_available(ben_gamra_imene, ts(mercredi,1)).
instructor_available(ben_gamra_imene, ts(mercredi,2)).
instructor_available(ben_gamra_imene, ts(jeudi,1)).
instructor_available(ben_gamra_imene, ts(vendredi,1)).

instructor_available(zanina_wiem, ts(lundi,1)).
instructor_available(zanina_wiem, ts(lundi,2)).
instructor_available(zanina_wiem, ts(mardi,1)).
instructor_available(zanina_wiem, ts(mercredi,1)).
instructor_available(zanina_wiem, ts(jeudi,1)).
instructor_available(zanina_wiem, ts(vendredi,1)).

instructor_available(bichiou_imene, ts(lundi,1)).
instructor_available(bichiou_imene, ts(mardi,1)).
instructor_available(bichiou_imene, ts(mercredi,1)).
instructor_available(bichiou_imene, ts(jeudi,1)).
instructor_available(bichiou_imene, ts(jeudi,2)).
instructor_available(bichiou_imene, ts(vendredi,1)).

instructor_available(taktak_hajer, ts(lundi,1)).
instructor_available(taktak_hajer, ts(mardi,2)).
instructor_available(taktak_hajer, ts(mercredi,1)).
instructor_available(taktak_hajer, ts(jeudi,1)).
instructor_available(taktak_hajer, ts(vendredi,3)).
instructor_available(taktak_hajer, ts(vendredi,4)).

instructor_available(ben_yahia_saloua, ts(lundi,1)).
instructor_available(ben_yahia_saloua, ts(lundi,2)).
instructor_available(ben_yahia_saloua, ts(mardi,1)).
instructor_available(ben_yahia_saloua, ts(mercredi,1)).
instructor_available(ben_yahia_saloua, ts(jeudi,1)).
instructor_available(ben_yahia_saloua, ts(vendredi,2)).
instructor_available(ben_yahia_saloua, ts(vendredi,3)).

instructor_available(hamdi_sana, ts(lundi,1)).
instructor_available(hamdi_sana, ts(lundi,2)).
instructor_available(hamdi_sana, ts(mardi,1)).
instructor_available(hamdi_sana, ts(mardi,2)).
instructor_available(hamdi_sana, ts(mercredi,1)).
instructor_available(hamdi_sana, ts(jeudi,1)).
instructor_available(hamdi_sana, ts(vendredi,1)).

instructor_available(mzabi_hela, ts(lundi,3)).
instructor_available(mzabi_hela, ts(mardi,1)).
instructor_available(mzabi_hela, ts(mercredi,1)).
instructor_available(mzabi_hela, ts(jeudi,1)).
instructor_available(mzabi_hela, ts(vendredi,1)).

instructor_available(abdelmoula_naouel, ts(lundi,1)).
instructor_available(abdelmoula_naouel, ts(lundi,2)).
instructor_available(abdelmoula_naouel, ts(mardi,1)).
instructor_available(abdelmoula_naouel, ts(mercredi,3)).
instructor_available(abdelmoula_naouel, ts(mercredi,4)).
instructor_available(abdelmoula_naouel, ts(jeudi,1)).
instructor_available(abdelmoula_naouel, ts(vendredi,1)).

instructor_available(sfaxi_lilia, ts(lundi,1)).
instructor_available(sfaxi_lilia, ts(lundi,2)).
instructor_available(sfaxi_lilia, ts(mardi,1)).
instructor_available(sfaxi_lilia, ts(mercredi,1)).
instructor_available(sfaxi_lilia, ts(jeudi,2)).
instructor_available(sfaxi_lilia, ts(jeudi,4)).
instructor_available(sfaxi_lilia, ts(vendredi,1)).
instructor_available(sfaxi_lilia, ts(vendredi,2)).
instructor_available(sfaxi_lilia, ts(vendredi,4)).

instructor_available(gasmi_maroua, ts(lundi,1)).
instructor_available(gasmi_maroua, ts(lundi,2)).
instructor_available(gasmi_maroua, ts(mardi,1)).
instructor_available(gasmi_maroua, ts(mercredi,1)).
instructor_available(gasmi_maroua, ts(jeudi,1)).
instructor_available(gasmi_maroua, ts(vendredi,1)).
instructor_available(gasmi_maroua, ts(vendredi,3)).
instructor_available(gasmi_maroua, ts(vendredi,4)).

instructor_available(negra_amamou_bouthei, ts(lundi,1)).
instructor_available(negra_amamou_bouthei, ts(mardi,1)).
instructor_available(negra_amamou_bouthei, ts(mercredi,1)).
instructor_available(negra_amamou_bouthei, ts(jeudi,3)).
instructor_available(negra_amamou_bouthei, ts(vendredi,1)).


/* ============================================================
   SECTION 9 : TYPE DE COURS
   ============================================================
   amphi        — séance commune à tout le niveau (1 seule assignment)
   td           — séance par groupe indépendamment
   tp_quinzaine — séance par groupe, alternée semaine_a / semaine_b
   ============================================================ */

% GL2
course_type(gl2_archi_res,      amphi).
course_type(gl2_analyse2,       amphi).
course_type(gl2_algebre2,       amphi).
course_type(gl2_sgbd,           amphi).
course_type(gl2_applic_rep,     amphi).
course_type(gl2_csi,            amphi).
course_type(gl2_droit,          amphi).
course_type(gl2_comptabilite,   amphi).

course_type(gl2_analyse2_td,    td).
course_type(gl2_algebre2_td,    td).
course_type(gl2_csi_td,         td).
course_type(gl2_anglais,        td).

course_type(gl2_archi_res_tdtp, tp_quinzaine).
course_type(gl2_sgbd_tp,        tp_quinzaine).
course_type(gl2_applic_rep_tp,  tp_quinzaine).
course_type(gl2_csi_tp,         tp_quinzaine).


course_quinzaine(gl2_archi_res_tdtp).
course_quinzaine(gl2_sgbd_tp).
course_quinzaine(gl2_applic_rep_tp).
course_quinzaine(gl2_csi_tp).


course_type(gl2_atelier_java,   tp).
course_type(gl2_unix,           tp).
course_type(gl2_tech_web,       tp).

% GL3
course_type(gl3_bases_rel,      amphi).
course_type(gl3_fond_syst_rep,  amphi).
course_type(gl3_analyse_data,   amphi).
course_type(gl3_marketing,      amphi).
course_type(gl3_protoc_web,     amphi).
course_type(gl3_methodo_conc,   amphi).

course_type(gl3_prog_logique,   td).
course_type(gl3_algorithmique,  td).
course_type(gl3_analyse_num,    td).
course_type(gl3_optimisation,   td).
course_type(gl3_complexite,     td).
course_type(gl3_co_design,      td).
course_type(gl3_anglais,        td).
course_type(gl3_francais,       td).

course_type(gl3_prog_logique_tp,  tp_quinzaine).
course_type(gl3_bases_rel_td,     tp_quinzaine).
course_type(gl3_bases_nonrel,     tp_quinzaine).
course_type(gl3_fond_syst_rep_td, tp_quinzaine).
course_type(gl3_analyse_data_tp,  tp_quinzaine).
course_type(gl3_co_design_tp,     tp_quinzaine).
course_type(gl3_protoc_web_tp,    tp_quinzaine).
course_type(gl3_methodo_conc_tp,  tp_quinzaine).

course_quinzaine(gl3_prog_logique_tp).
course_quinzaine(gl3_bases_rel_td).
course_quinzaine(gl3_bases_nonrel).
course_quinzaine(gl3_fond_syst_rep_td).
course_quinzaine(gl3_analyse_data_tp).
course_quinzaine(gl3_co_design_tp).
course_quinzaine(gl3_protoc_web_tp).
course_quinzaine(gl3_methodo_conc_tp).

course_type(gl3_ppp, tp).

% GL4
course_type(gl4_big_data,      amphi).
course_type(gl4_archi_log,     amphi).
course_type(gl4_protoc_secu,   amphi).
course_type(gl4_management,    amphi).
course_type(gl4_grh,           amphi).

course_type(gl4_devops,        td).
course_type(gl4_deep_learning, td).
course_type(gl4_compilation,   td).
course_type(gl4_traitement_img,td).
course_type(gl4_test_logiciel, td).
course_type(gl4_anglais,       td).

course_type(gl4_devops_tp,          tp_quinzaine).
course_type(gl4_deep_learning_tp,   tp_quinzaine).
course_type(gl4_compilation_tp,     tp_quinzaine).
course_type(gl4_traitement_img_tp,  tp_quinzaine).
course_type(gl4_big_data_tp,        tp_quinzaine).
course_type(gl4_archi_log_tp,       tp_quinzaine).
course_type(gl4_protoc_secu_tp,     tp_quinzaine).
course_type(gl4_ihm,                tp_quinzaine).

course_quinzaine(gl4_devops_tp).
course_quinzaine(gl4_deep_learning_tp).
course_quinzaine(gl4_compilation_tp).
course_quinzaine(gl4_traitement_img_tp).
course_quinzaine(gl4_big_data_tp).
course_quinzaine(gl4_archi_log_tp).
course_quinzaine(gl4_protoc_secu_tp).
course_quinzaine(gl4_ihm).


/* ============================================================
   SECTION 10 : CONTRAINTES HARD
   ============================================================ */

% ① Équipement compatible
equipment_ok(Course, Room) :-
    course_equipment(Course, Req),
    room_equipment(Room, Req).

% ② Capacité suffisante
%    amphi    : taille totale du niveau
%    td/tp    : taille du groupe concerné
capacity_ok(Course, Room) :-
    course_type(Course, amphi), !,
    course_group(Course, SomeGroup),
    group_level(SomeGroup, Level),
    level_groups(Level, Groups),
    aggregate_size(Groups, TotalSize),
    room_capacity(Room, Cap),
    Cap >= TotalSize.
capacity_ok(Course, Room) :-
    course_group(Course, Group),
    group_size(Group, N),
    room_capacity(Room, Cap),
    Cap >= N.

capacity_ok_for_group(Group, Room) :-
    group_size(Group, N),
    room_capacity(Room, Cap),
    Cap >= N.

aggregate_size([], 0).
aggregate_size([G|Gs], Total) :-
    group_size(G, N),
    aggregate_size(Gs, Rest),
    Total is N + Rest.

% ③ Disponibilité enseignant
instructor_available_ok(Course, Timeslot) :-
    course_instructor(Course, Instr),
    instructor_available(Instr, Timeslot).

% ④ Pas de conflit de salle
%    Format : assignment(Course, Group, Room, Ts, WeekTag)
no_room_conflict(_, _, []).
no_room_conflict(Room, Ts, [assignment(_, _, Room, Ts, _)|_]) :- !, fail.
no_room_conflict(Room, Ts, [_|Rest]) :-
    no_room_conflict(Room, Ts, Rest).

% ⑤ Pas de conflit de groupe
%    Deux cours ne peuvent pas avoir le même groupe au même créneau.
no_group_conflict(_, _, _, []).
no_group_conflict(Course, Group, Ts,
                  [assignment(OtherC, OtherG, _, Ts, _)|Rest]) :-
    (   Course \= OtherC, OtherG == Group
    ->  !, fail
    ;   no_group_conflict(Course, Group, Ts, Rest)
    ).
no_group_conflict(Course, Group, Ts, [_|Rest]) :-
    no_group_conflict(Course, Group, Ts, Rest).

% ⑥ Pas de conflit enseignant
no_instructor_conflict(_, _, []).
no_instructor_conflict(Course, Ts,
                        [assignment(OtherC, _, _, Ts, _)|Rest]) :-
    (   Course \= OtherC,
        course_instructor(Course, I),
        course_instructor(OtherC, I)
    ->  !, fail
    ;   no_instructor_conflict(Course, Ts, Rest)
    ).
no_instructor_conflict(Course, Ts, [_|Rest]) :-
    no_instructor_conflict(Course, Ts, Rest).


/* ============================================================
   SECTION 11 : PRÉDICATS CLÉS — INTERFACE POUR PART C
   ============================================================

   FORMAT D'ASSIGNMENT :
     assignment(Course, Group, Room, Timeslot, WeekTag)
     WeekTag = toutes_semaines | semaine_a | semaine_b

   Pour les amphi, Group = level(Level)
   ============================================================ */

%% sessions_to_schedule_v2(+Level, -Sessions)
%  Génère la liste des sessions à planifier.
%  session(Course, Group, WeekTag)

sessions_to_schedule_v2(Level, Sessions) :-
    findall(S, session_for_level(Level, S), Raw),
    sort(Raw, Sessions).

% Amphi : une seule session par cours pour tout le niveau
session_for_level(Level, session(Course, level(Level), toutes_semaines)) :-
    level_groups(Level, Groups),
    % Un cours amphi par cours (on prend le premier groupe pour trouver le cours)
    member(G, Groups),
    course_group(Course, G),
    course_type(Course, amphi),
    % Évite les doublons si le cours a plusieurs groupes
    \+ ( member(G2, Groups), G2 @< G, course_group(Course, G2) ).

% TD : une session par groupe principal
session_for_level(Level, session(Course, Group, toutes_semaines)) :-
    level_groups(Level, Groups),
    member(Group, Groups),
    course_group(Course, Group),
    course_type(Course, td).


/*
La première génère les sessions pour la semaine A (tag semaine_a)
La deuxième génère les sessions pour la semaine B (tag semaine_b)
*/

% TP quinzaine : deux sessions par groupe (semaine_a + semaine_b)
session_for_level(Level, session(Course, Group, semaine_a)) :-
    level_groups(Level, Groups),
    member(Group, Groups),
    course_group(Course, Group),
    course_type(Course, tp_quinzaine).

session_for_level(Level, session(Course, Group, semaine_b)) :-
    level_groups(Level, Groups),
    member(Group, Groups),
    course_group(Course, Group),
    course_type(Course, tp_quinzaine).

    
% TP hebdomadaire (non quinzaine) : une session par groupe, toutes les semaines
session_for_level(Level, session(Course, Group, toutes_semaines)) :-
    level_groups(Level, Groups),
    member(Group, Groups),
    course_group(Course, Group),
    course_type(Course, tp).  % Type 'tp' (sans _quinzaine)

%% valid_assignment_v2(+Session, -Room, -Timeslot, +Partial)
% Cas amphi avec contrainte renforcée : tous les groupes du niveau doivent être ensemble

valid_assignment_v2(session(Course, level(Level), WeekTag), Room, Ts, Partial) :-
    room(Room),
    timeslot(Ts, _, _, _),
    equipment_ok(Course, Room),
    level_groups(Level, Groups),
    aggregate_size(Groups, TotalSize),
    room_capacity(Room, Cap),
    Cap >= TotalSize,
    instructor_available_ok(Course, Ts),
    
    % CONTRAINTE RENFORCÉE : Tous les groupes doivent être libres ET
    % aucun autre cours ne doit occuper un de ces groupes à ce créneau
    forall(member(G, Groups),
           ( no_group_conflict(Course, G, Ts, Partial),
             \+ ( member(OtherG, Groups),
                  assignment_exists_for_group(OtherG, Ts, Partial)
                )
           )),
    
    no_room_conflict(Room, Ts, Partial),
    no_instructor_conflict(Course, Ts, Partial).

% Prédicat auxiliaire pour vérifier si un groupe a déjà une assignation
assignment_exists_for_group(Group, Ts, Partial) :-
    member(assignment(_, Group, _, Ts, _), Partial).

% Cas TD / TP quinzaine (inchangé)
valid_assignment_v2(session(Course, Group, _WeekTag), Room, Ts, Partial) :-
    Group \= level(_),
    room(Room),
    timeslot(Ts, _, _, _),
    equipment_ok(Course, Room),
    capacity_ok_for_group(Group, Room),
    instructor_available_ok(Course, Ts),
    no_room_conflict(Room, Ts, Partial),
    no_group_conflict(Course, Group, Ts, Partial),
    no_instructor_conflict(Course, Ts, Partial).

/* ============================================================
   SECTION 12 : UTILITAIRES
   ============================================================ */

minutes_to_label(480, '08h00').
minutes_to_label(585, '09h45').
minutes_to_label(840, '14h00').
minutes_to_label(945, '15h45').

display_assignment_v2(assignment(Course, Group, Room, Ts, WeekTag)) :-
    timeslot(Ts, Day, _, Min),
    minutes_to_label(Min, Label),
    format("  [~w] groupe=~w | ~w | ~w ~w | ~w~n",
           [Course, Group, Room, Day, Label, WeekTag]).

display_schedule([]).
display_schedule([A|As]) :-
    display_assignment_v2(A),
    display_schedule(As).

rooms_for_course(Course, Rooms) :-
    findall(R, (room(R), equipment_ok(Course, R)), Rooms).