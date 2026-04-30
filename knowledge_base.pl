/* ============================================================
 
   LOGIQUE DE PLANIFICATION :
     • La charge horaire est suivie via cost/3 :
         cost(NomSeance, ReferenceHour, RemainingHour)
     • Une séance placée dans l'emploi du temps consomme 1 slot (1.5h)
       et diminue RemainingHour.
     • Plus de division quinzaine semaine_a / semaine_b.

   SECTIONS :
     1  — Créneaux horaires
     2  — Bâtiments
     3  — Salles
     4  — Groupes
     5  — Enseignants
     6  — Coût des séances (GL2 + GL3 + GL4)
     7  — Métadonnées (enseignants / équipement)
     8  — Disponibilités enseignants
     9  — Dérivation de séance depuis cost/3
     10 — Contraintes hard
     11 — Prédicats clés (interface → Part C)
     12 — Utilitaires
   ============================================================
*/

:- dynamic cost/3.
:- dynamic room_occupied/2.
:- discontiguous cost/3.
:- discontiguous valid_assignment_v2/4.
:- discontiguous instructor_cours/2.
:- discontiguous instructor_td/2.
:- discontiguous instructor_tp/2.

/* ============================================================
   SECTION 1 : CRÉNEAUX HORAIRES
   ============================================================ */

% 3 séances le matin (1,2,3) et 2 séances l'après-midi (4,5).
% Les horaires restent sur des créneaux de 1h30 (slot_hours = 1.5).
timeslot(ts(lundi,1),    lundi,    1,  480). % 08:00
timeslot(ts(lundi,2),    lundi,    2,  585). % 09:45
timeslot(ts(lundi,3),    lundi,    3,  690). % 11:30
timeslot(ts(lundi,4),    lundi,    4,  840). % 14:00
timeslot(ts(lundi,5),    lundi,    5,  945). % 15:45
timeslot(ts(mardi,1),    mardi,    1,  480).
timeslot(ts(mardi,2),    mardi,    2,  585).
timeslot(ts(mardi,3),    mardi,    3,  690).
timeslot(ts(mardi,4),    mardi,    4,  840).
timeslot(ts(mardi,5),    mardi,    5,  945).
timeslot(ts(mercredi,1), mercredi, 1,  480).
timeslot(ts(mercredi,2), mercredi, 2,  585).
timeslot(ts(mercredi,3), mercredi, 3,  690).
timeslot(ts(mercredi,4), mercredi, 4,  840).
timeslot(ts(mercredi,5), mercredi, 5,  945).
timeslot(ts(jeudi,1),    jeudi,    1,  480).
timeslot(ts(jeudi,2),    jeudi,    2,  585).
timeslot(ts(jeudi,3),    jeudi,    3,  690).
timeslot(ts(jeudi,4),    jeudi,    4,  840).
timeslot(ts(jeudi,5),    jeudi,    5,  945).
timeslot(ts(vendredi,1), vendredi, 1,  480).
timeslot(ts(vendredi,2), vendredi, 2,  585).
timeslot(ts(vendredi,3), vendredi, 3,  690).
timeslot(ts(vendredi,4), vendredi, 4,  840).
timeslot(ts(vendredi,5), vendredi, 5,  945).
timeslot(ts(samedi,1),   samedi,   1,  480).
timeslot(ts(samedi,2),   samedi,   2,  585).
timeslot(ts(samedi,3),   samedi,   3,  690).
timeslot(ts(samedi,4),   samedi,   4,  840).
timeslot(ts(samedi,5),   samedi,   5,  945).


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
room_capacity(li013, 50). room_capacity(li116, 50). room_capacity(li173, 50).
room_capacity(li175, 50). room_capacity(li177, 50). room_capacity(li208, 50).
room_capacity(li210, 50). room_capacity(li212, 50). room_capacity(li255, 50).
room_capacity(li2121, 50). room_capacity(li2121bis, 50).

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
   SECTION 6 : COÛT DES SÉANCES (RÉFÉRENCE / RESTANT)
   ============================================================ */

% Convention :
%   - Cours commun : glX_matiere_cours
%   - TD par sous-groupe : glX_matiere_td1, td2, ...
%   - TP par sous-groupe : glX_matiere_tp1, tp2, ...
%
% Au départ :
%   RemainingHour = ReferenceHour

/* ============================================================
   GL2 — 3 sous-groupes : gl2_1, gl2_2, gl2_3
   ============================================================ */

% Architecture des réseaux : Cours 22.5, TD 11.25, TP 15
cost(gl2_archi_res_cours, 22.5, 22.5).
cost(gl2_archi_res_td1, 11.25, 11.25).
cost(gl2_archi_res_td2, 11.25, 11.25).
cost(gl2_archi_res_td3, 11.25, 11.25).
cost(gl2_archi_res_tp1, 15, 15).
cost(gl2_archi_res_tp2, 15, 15).
cost(gl2_archi_res_tp3, 15, 15).

% Analyse Mathématique : Cours 22.5, TD 22.5
cost(gl2_analyse2_cours, 22.5, 22.5).
cost(gl2_analyse2_td1, 22.5, 22.5).
cost(gl2_analyse2_td2, 22.5, 22.5).
cost(gl2_analyse2_td3, 22.5, 22.5).

% Algèbre : Cours 22.5, TD 22.5
cost(gl2_algebre2_cours, 22.5, 22.5).
cost(gl2_algebre2_td1, 22.5, 22.5).
cost(gl2_algebre2_td2, 22.5, 22.5).
cost(gl2_algebre2_td3, 22.5, 22.5).

% Systèmes de gestion de bases de données : Cours 22.5, TP 15
cost(gl2_sgbd_cours, 22.5, 22.5).
cost(gl2_sgbd_tp1, 15, 15).
cost(gl2_sgbd_tp2, 15, 15).
cost(gl2_sgbd_tp3, 15, 15).

% Conception des systèmes d'information : Cours 22.5, TD 22.5, TP 15
cost(gl2_csi_cours, 22.5, 22.5).
cost(gl2_csi_td1, 22.5, 22.5).
cost(gl2_csi_td2, 22.5, 22.5).
cost(gl2_csi_td3, 22.5, 22.5).
cost(gl2_csi_tp1, 15, 15).
cost(gl2_csi_tp2, 15, 15).
cost(gl2_csi_tp3, 15, 15).

% Applications réparties : Cours 22.5, TP 15
cost(gl2_applic_rep_cours, 22.5, 22.5).
cost(gl2_applic_rep_tp1, 15, 15).
cost(gl2_applic_rep_tp2, 15, 15).
cost(gl2_applic_rep_tp3, 15, 15).

% Atelier Java Avancé : Cours 15, TP 15
cost(gl2_atelier_java_cours, 15, 15).
cost(gl2_atelier_java_tp1, 15, 15).
cost(gl2_atelier_java_tp2, 15, 15).
cost(gl2_atelier_java_tp3, 15, 15).

% Développement Web : Cours 15, TP 15
cost(gl2_tech_web_cours, 15, 15).
cost(gl2_tech_web_tp1, 15, 15).
cost(gl2_tech_web_tp2, 15, 15).
cost(gl2_tech_web_tp3, 15, 15).

% Système d'exploitation UNIX : Cours 15, TP 15
cost(gl2_unix_cours, 15, 15).
cost(gl2_unix_tp1, 15, 15).
cost(gl2_unix_tp2, 15, 15).
cost(gl2_unix_tp3, 15, 15).

% Droit de l'homme : Cours 22.5
cost(gl2_droit_cours, 22.5, 22.5).

% Comptabilité : Cours 15, TD 7.5
cost(gl2_comptabilite_cours, 15, 15).
cost(gl2_comptabilite_td1, 7.5, 7.5).
cost(gl2_comptabilite_td2, 7.5, 7.5).
cost(gl2_comptabilite_td3, 7.5, 7.5).

% Anglais : TD 22.5
cost(gl2_anglais_td1, 22.5, 22.5).
cost(gl2_anglais_td2, 22.5, 22.5).
cost(gl2_anglais_td3, 22.5, 22.5).


/* ============================================================
   GL3 — 2 sous-groupes : gl3_1, gl3_2
   ============================================================ */

% Programmation logique : Cours 22.5, TD 11.25, TP 11.25
cost(gl3_prog_logique_cours, 22.5, 22.5).
cost(gl3_prog_logique_td1, 11.25, 11.25).
cost(gl3_prog_logique_td2, 11.25, 11.25).
cost(gl3_prog_logique_tp1, 11.25, 11.25).
cost(gl3_prog_logique_tp2, 11.25, 11.25).

% Bases de données relationnelles : Cours 22.5, TD 11.25, TP 11.25
cost(gl3_bases_rel_cours, 22.5, 22.5).
cost(gl3_bases_rel_td1, 11.25, 11.25).
cost(gl3_bases_rel_td2, 11.25, 11.25).
cost(gl3_bases_rel_tp1, 11.25, 11.25).
cost(gl3_bases_rel_tp2, 11.25, 11.25).

% Bases de données non relationnelles : Cours 22.5, TD 11.25, TP 11.25
cost(gl3_bases_nonrel_cours, 22.5, 22.5).
cost(gl3_bases_nonrel_td1, 11.25, 11.25).
cost(gl3_bases_nonrel_td2, 11.25, 11.25).
cost(gl3_bases_nonrel_tp1, 11.25, 11.25).
cost(gl3_bases_nonrel_tp2, 11.25, 11.25).

% Fondements des systèmes et applications réparties : Cours 22.5, TP 12
cost(gl3_fond_syst_rep_cours, 22.5, 22.5).
cost(gl3_fond_syst_rep_tp1, 12, 12).
cost(gl3_fond_syst_rep_tp2, 12, 12).

% Analyse numérique : Cours 15, TD 7.5
cost(gl3_analyse_num_cours, 15, 15).
cost(gl3_analyse_num_td1, 7.5, 7.5).
cost(gl3_analyse_num_td2, 7.5, 7.5).

% Optimisation appliquée : Cours 15, TD 7.5
cost(gl3_optimisation_cours, 15, 15).
cost(gl3_optimisation_td1, 7.5, 7.5).
cost(gl3_optimisation_td2, 7.5, 7.5).

% Analyse des données : Cours 22.5, TP 12
cost(gl3_analyse_data_cours, 22.5, 22.5).
cost(gl3_analyse_data_tp1, 12, 12).
cost(gl3_analyse_data_tp2, 12, 12).

% Algorithmique avancée : Cours 22.5, TD 11.25
cost(gl3_algorithmique_cours, 22.5, 22.5).
cost(gl3_algorithmique_td1, 11.25, 11.25).
cost(gl3_algorithmique_td2, 11.25, 11.25).

% Complexité des algorithmes : Cours 22.5, TD 22.5
cost(gl3_complexite_cours, 22.5, 22.5).
cost(gl3_complexite_td1, 22.5, 22.5).
cost(gl3_complexite_td2, 22.5, 22.5).

% Co-design : Cours 22.5, TP 12
cost(gl3_co_design_cours, 22.5, 22.5).
cost(gl3_co_design_tp1, 12, 12).
cost(gl3_co_design_tp2, 12, 12).

% Protocoles de communication Web-APIs : Cours 22.5, TP 12
cost(gl3_protoc_web_cours, 22.5, 22.5).
cost(gl3_protoc_web_tp1, 12, 12).
cost(gl3_protoc_web_tp2, 12, 12).

% Méthodologies de Conception : Cours 22.5, TP 12
cost(gl3_methodo_conc_cours, 22.5, 22.5).
cost(gl3_methodo_conc_tp1, 12, 12).
cost(gl3_methodo_conc_tp2, 12, 12).

% Marketing : Cours 22.5
cost(gl3_marketing_cours, 22.5, 22.5).

% Français : TD 22.5
cost(gl3_francais_td1, 22.5, 22.5).
cost(gl3_francais_td2, 22.5, 22.5).

% Anglais : TD 22.5
cost(gl3_anglais_td1, 22.5, 22.5).
cost(gl3_anglais_td2, 22.5, 22.5).

% Projet Personnel Professionnel : TP 30
cost(gl3_ppp_tp1, 30, 30).
cost(gl3_ppp_tp2, 30, 30).


/* ============================================================
   GL4 — 2 sous-groupes : gl4_1, gl4_2
   ============================================================ */

% DevSecOps / DevOps : Cours 15, TD 7.5, TP 12
cost(gl4_devops_cours, 15, 15).
cost(gl4_devops_td1, 7.5, 7.5).
cost(gl4_devops_td2, 7.5, 7.5).
cost(gl4_devops_tp1, 12, 12).
cost(gl4_devops_tp2, 12, 12).

% Deep Learning : Cours 22.5, TP 12
cost(gl4_deep_learning_cours, 22.5, 22.5).
cost(gl4_deep_learning_tp1, 12, 12).
cost(gl4_deep_learning_tp2, 12, 12).

% Compilation et implémentation des langages : Cours 15, TD 7.5, TP 12
cost(gl4_compilation_cours, 15, 15).
cost(gl4_compilation_td1, 7.5, 7.5).
cost(gl4_compilation_td2, 7.5, 7.5).
cost(gl4_compilation_tp1, 12, 12).
cost(gl4_compilation_tp2, 12, 12).

% Traitement d'images : Cours 22.5, TP 12
cost(gl4_traitement_img_cours, 22.5, 22.5).
cost(gl4_traitement_img_tp1, 12, 12).
cost(gl4_traitement_img_tp2, 12, 12).

% Big Data : Cours 22.5, TP 12
cost(gl4_big_data_cours, 22.5, 22.5).
cost(gl4_big_data_tp1, 12, 12).
cost(gl4_big_data_tp2, 12, 12).

% Architectures logicielles : Cours 22.5, TP 12
cost(gl4_archi_log_cours, 22.5, 22.5).
cost(gl4_archi_log_tp1, 12, 12).
cost(gl4_archi_log_tp2, 12, 12).

% Protocoles de sécurité : Cours 22.5, TP 12
cost(gl4_protoc_secu_cours, 22.5, 22.5).
cost(gl4_protoc_secu_tp1, 12, 12).
cost(gl4_protoc_secu_tp2, 12, 12).

% Interface Homme Machine : Cours 11.25, TP 11.25
cost(gl4_ihm_cours, 11.25, 11.25).
cost(gl4_ihm_tp1, 11.25, 11.25).
cost(gl4_ihm_tp2, 11.25, 11.25).

% Tests Logiciels : Cours 22.5, TP 12
cost(gl4_test_logiciel_cours, 22.5, 22.5).
cost(gl4_test_logiciel_tp1, 12, 12).
cost(gl4_test_logiciel_tp2, 12, 12).

% Gestion des ressources humaines : Cours 22.5
cost(gl4_grh_cours, 22.5, 22.5).

% Management de projets : Cours 15, TD 7.5
cost(gl4_management_cours, 15, 15).
cost(gl4_management_td1, 7.5, 7.5).
cost(gl4_management_td2, 7.5, 7.5).

% Anglais : TD 22.5
cost(gl4_anglais_td1, 22.5, 22.5).
cost(gl4_anglais_td2, 22.5, 22.5).


/* ============================================================
   SECTION 7 : MÉTADONNÉES (ENSEIGNANTS / ÉQUIPEMENT)
   ============================================================ */


% --- session_instructor ---
% Modèle normalisé : enseignant par type de séance (cours / td / tp)
% aligné avec les noms utilisés dans cost/3.

% GL2
instructor_cours(gl2_archi_res, loukil_adlene).
instructor_td(gl2_archi_res, loukil_adlene).
instructor_tp(gl2_archi_res, loukil_adlene).

instructor_cours(gl2_analyse2, trigui_elloumi_fatma).
instructor_td(gl2_analyse2, trigui_elloumi_fatma).

instructor_cours(gl2_algebre2, hmida_jendoubi_nadia).
instructor_td(gl2_algebre2, hmida_jendoubi_nadia).
instructor_td(gl2_algebre2, soussi_yosra).

instructor_cours(gl2_sgbd, baklouti_fatma).
instructor_tp(gl2_sgbd, baklouti_fatma).

instructor_cours(gl2_csi, bouzidi_sonia).
instructor_td(gl2_csi, bouzidi_sonia).
instructor_tp(gl2_csi, hanchi_thouraya).

instructor_cours(gl2_applic_rep, ben_hassouna_asma).
instructor_tp(gl2_applic_rep, ben_hassouna_asma).

instructor_cours(gl2_atelier_java, jemai_abderrazak).
instructor_tp(gl2_atelier_java, jemai_abderrazak).

instructor_cours(gl2_tech_web, sellaouti_aymen).
instructor_tp(gl2_tech_web, sellaouti_aymen).

instructor_cours(gl2_unix, mami_imen).
instructor_tp(gl2_unix, mami_imen).

instructor_cours(gl2_droit, boukottaya_hanen).

instructor_cours(gl2_comptabilite, bouaziz_samira).
instructor_td(gl2_comptabilite, bouaziz_samira).

instructor_td(gl2_anglais, ben_rejeb_ihsen).

% GL3
instructor_cours(gl3_prog_logique, khalgui_mohamed).
instructor_td(gl3_prog_logique, khalgui_mohamed).
instructor_tp(gl3_prog_logique, khalgui_mohamed).

instructor_cours(gl3_bases_rel, baklouti_fatma).
instructor_td(gl3_bases_rel, baklouti_fatma).
instructor_tp(gl3_bases_rel, baklouti_fatma).

instructor_cours(gl3_bases_nonrel, baklouti_fatma).
instructor_td(gl3_bases_nonrel, baklouti_fatma).
instructor_tp(gl3_bases_nonrel, baklouti_fatma).

instructor_cours(gl3_fond_syst_rep, ouni_sofiane).
instructor_tp(gl3_fond_syst_rep, ouni_sofiane).

instructor_cours(gl3_analyse_num, arbi_adnen).
instructor_td(gl3_analyse_num, arbi_adnen).

instructor_cours(gl3_optimisation, sfaxi_mourad).
instructor_td(gl3_optimisation, sfaxi_mourad).

instructor_cours(gl3_analyse_data, arbi_adnen).
instructor_tp(gl3_analyse_data, arbi_adnen).

instructor_cours(gl3_algorithmique, gasmi_ghada).
instructor_td(gl3_algorithmique, gasmi_ghada).

instructor_cours(gl3_complexite, mliki_hazar).
instructor_td(gl3_complexite, mliki_hazar).

instructor_cours(gl3_co_design, damergi_emir).
instructor_tp(gl3_co_design, damergi_emir).

instructor_cours(gl3_protoc_web, sellaouti_aymen).
instructor_tp(gl3_protoc_web, sellaouti_aymen).

instructor_cours(gl3_methodo_conc, gasmi_ghada).
instructor_tp(gl3_methodo_conc, gasmi_ghada).

instructor_cours(gl3_marketing, ben_gamra_imene).

instructor_td(gl3_francais, zanina_wiem).
instructor_td(gl3_anglais, bichiou_imene).

instructor_tp(gl3_ppp, taktak_hajer).

% GL4
instructor_cours(gl4_devops, ben_yahia_saloua).
instructor_td(gl4_devops, ben_yahia_saloua).
instructor_tp(gl4_devops, ben_yahia_saloua).

instructor_cours(gl4_deep_learning, hamdi_sana).
instructor_tp(gl4_deep_learning, hamdi_sana).

instructor_cours(gl4_compilation, khalgui_mohamed).
instructor_td(gl4_compilation, khalgui_mohamed).
instructor_tp(gl4_compilation, khalgui_mohamed).

instructor_cours(gl4_traitement_img, bouzidi_sonia).
instructor_tp(gl4_traitement_img, bouzidi_sonia).

instructor_cours(gl4_big_data, sfaxi_lilia).
instructor_tp(gl4_big_data, sfaxi_lilia).

instructor_cours(gl4_archi_log, sfaxi_lilia).
instructor_tp(gl4_archi_log, sfaxi_lilia).

instructor_cours(gl4_protoc_secu, gasmi_maroua).
instructor_tp(gl4_protoc_secu, gasmi_maroua).

instructor_cours(gl4_ihm, taktak_hajer).
instructor_tp(gl4_ihm, taktak_hajer).

instructor_cours(gl4_test_logiciel, bouzidi_sonia).
instructor_tp(gl4_test_logiciel, bouzidi_sonia).

instructor_cours(gl4_grh, mzabi_hela).

instructor_cours(gl4_management, abdelmoula_naouel).
instructor_td(gl4_management, abdelmoula_naouel).

instructor_td(gl4_anglais, negra_amamou_bouthei).


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
   SECTION 9 : DÉRIVATION DE SÉANCE (À PARTIR DE cost/3)
   ============================================================ */

slot_hours(1.5).

remaining_positive(RemainingHour) :-
    RemainingHour > 0.0.

session_level(Session, Level) :-
    atomic_list_concat([Level|_], '_', Session),
    member(Level, [gl2, gl3, gl4]).

session_name_parts(Session, Base, cours, none) :-
    atomic_list_concat(Parts, '_', Session),
    append(BaseParts, [cours], Parts),
    atomic_list_concat(BaseParts, '_', Base).
session_name_parts(Session, Base, td, Index) :-
    atomic_list_concat(Parts, '_', Session),
    append(BaseParts, [Last], Parts),
    atom_concat(td, Index, Last),
    Index \= '',
    atomic_list_concat(BaseParts, '_', Base).
session_name_parts(Session, Base, tp, Index) :-
    atomic_list_concat(Parts, '_', Session),
    append(BaseParts, [Last], Parts),
    atom_concat(tp, Index, Last),
    Index \= '',
    atomic_list_concat(BaseParts, '_', Base).

session_kind(Session, Kind) :-
    session_name_parts(Session, _, Kind, _).

session_group(Session, level(Level)) :-
    session_name_parts(Session, _, cours, _),
    session_level(Session, Level),
    !.
session_group(Session, Group) :-
    session_name_parts(Session, _, Kind, Index),
    member(Kind, [td, tp]),
    session_level(Session, Level),
    atom_concat(Level, '_', Prefix),
    atom_concat(Prefix, Index, CalculatedGroup),
    Group = CalculatedGroup,
    group(Group).

session_equipment(Session, amphi) :-
    session_kind(Session, cours), !.
session_equipment(Session, salle_td) :-
    session_kind(Session, td), !.
session_equipment(Session, labo_pc) :-
    session_kind(Session, tp).

session_instructor(Session, Instructor) :-
    session_name_parts(Session, Base, cours, _),
    instructor_cours(Base, Instructor).
session_instructor(Session, Instructor) :-
    session_name_parts(Session, Base, td, _),
    instructor_td(Base, Instructor).
session_instructor(Session, Instructor) :-
    session_name_parts(Session, Base, tp, _),
    instructor_tp(Base, Instructor).

%% session_priority(+SessionName, -Priority)
%  Attribue une priorité : Cours (1) > TD (2) > TP (3).
session_priority(S, 1) :- session_kind(S, cours), !.
session_priority(S, 2) :- session_kind(S, td), !.
session_priority(S, 3) :- session_kind(S, tp), !.
session_priority(_, 4).

%% session_priority_pair(+SessionTerm, -Pair)
%  Utilitaire pour le tri par priorité.
session_priority_pair(session(S, G), P-session(S, G)) :-
    session_priority(S, P).


/* ============================================================
   SECTION 10 : CONTRAINTES HARD
   ============================================================ */

% ① Équipement compatible
equipment_ok(Session, Room) :-
    session_equipment(Session, Req),
    room_equipment(Room, Req).

% ② Capacité suffisante
%    cours commun : taille totale du niveau
%    td/tp        : taille du groupe concerné
capacity_ok(Session, Room) :-
    session_group(Session, level(Level)), !,
    level_groups(Level, Groups),
    aggregate_size(Groups, TotalSize),
    room_capacity(Room, Cap),
    Cap >= TotalSize.
capacity_ok(Session, Room) :-
    session_group(Session, Group),
    capacity_ok_for_group(Group, Room).

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
instructor_available_ok(Session, Timeslot) :-
    session_instructor(Session, Instr),
    instructor_available(Instr, Timeslot).

% ④ État global des salles (tous emplois confondus)
%    room_occupied(Room, Ts) est dynamique et persistant entre générations.
%    room_state/3 expose un état lisible : free | occupied.
room_state(Room, Ts, occupied) :-
    room_occupied(Room, Ts), !.
room_state(Room, Ts, free) :-
    room(Room),
    timeslot(Ts, _, _, _),
    \+ room_occupied(Room, Ts).

room_available(Room, Ts) :-
    room_state(Room, Ts, free).

occupy_room(Room, Ts) :-
    room(Room),
    timeslot(Ts, _, _, _),
    \+ room_occupied(Room, Ts),
    assertz(room_occupied(Room, Ts)).

release_room(Room, Ts) :-
    retractall(room_occupied(Room, Ts)).

release_occupied_pairs([]).
release_occupied_pairs([room_ts(Room, Ts) | Rest]) :-
    release_room(Room, Ts),
    release_occupied_pairs(Rest).

occupy_schedule_rooms(Schedule) :-
    occupy_schedule_rooms(Schedule, []).

occupy_schedule_rooms([], _Acc).
occupy_schedule_rooms([assignment(_, _, Room, Ts) | Rest], Acc) :-
    (   occupy_room(Room, Ts)
    ->  occupy_schedule_rooms(Rest, [room_ts(Room, Ts) | Acc])
    ;   release_occupied_pairs(Acc),
        fail
    ).

release_schedule_rooms([]).
release_schedule_rooms([assignment(_, _, Room, Ts) | Rest]) :-
    release_room(Room, Ts),
    release_schedule_rooms(Rest).

reset_room_occupancy :-
    retractall(room_occupied(_, _)).

% ⑤ Pas de conflit de salle
%    Format : assignment(Session, Group, Room, Ts)
no_room_conflict(Room, Ts, Partial) :-
    room_available(Room, Ts),
    no_room_conflict_local(Room, Ts, Partial).

no_room_conflict_local(_, _, []).
no_room_conflict_local(Room, Ts, [assignment(_, _, Room, Ts)|_]) :- !, fail.
no_room_conflict_local(Room, Ts, [_|Rest]) :-
    no_room_conflict_local(Room, Ts, Rest).

% ⑥ Pas de conflit de groupe
%    Deux séances ne peuvent pas partager un même groupe effectif.
groups_overlap(level(Level), level(Level)).
groups_overlap(level(Level), Group) :-
    group(Group),
    group_level(Group, Level).
groups_overlap(Group, level(Level)) :-
    group(Group),
    group_level(Group, Level).
groups_overlap(Group, Group) :-
    group(Group).

no_group_conflict(_, _, _, []).
no_group_conflict(Session, Group, Ts,
                  [assignment(OtherSession, OtherGroup, _, Ts)|Rest]) :-
    (   Session \= OtherSession,
        groups_overlap(Group, OtherGroup)
    ->  !, fail
    ;   no_group_conflict(Session, Group, Ts, Rest)
    ).
no_group_conflict(Session, Group, Ts, [_|Rest]) :-
    no_group_conflict(Session, Group, Ts, Rest).

% ⑦ Pas de conflit enseignant
no_instructor_conflict(_, _, []).
no_instructor_conflict(Session, Ts,
                        [assignment(OtherSession, _, _, Ts)|Rest]) :-
    (   Session \= OtherSession,
        session_instructor(Session, I),
        session_instructor(OtherSession, I)
    ->  !, fail
    ;   no_instructor_conflict(Session, Ts, Rest)
    ).
no_instructor_conflict(Session, Ts, [_|Rest]) :-
    no_instructor_conflict(Session, Ts, Rest).


/* ============================================================
   SECTION 11 : PRÉDICATS CLÉS — INTERFACE POUR PART C
   ============================================================

   FORMAT D'ASSIGNMENT :
     assignment(Session, Group, Room, Timeslot)

   Pour les séances ..._cours, Group = level(Level)
   ============================================================ */

level_limit(gl2, 14).
level_limit(gl3, 17).
level_limit(gl4, 14).

%% sessions_to_schedule_v2(+Level, -Sessions)
%  Génère la liste des séances à planifier avec des limites par niveau.
sessions_to_schedule_v2(Level, Sessions) :-
    findall(
        session(Session, Group),
        ( cost(Session, _, RemainingHour),
          remaining_positive(RemainingHour),
          session_level(Session, Level),
          session_group(Session, Group)
        ),
        Raw
    ),
    % 1. Supprimer les doublons
    sort(Raw, Unique),
    % 2. Trier par priorité (Cours > TD > TP)
    maplist(session_priority_pair, Unique, Pairs),
    keysort(Pairs, SortedPairs),
    pairs_values(SortedPairs, AllSessions),
    % 3. Appliquer la limite spécifique au niveau
    level_limit(Level, Limit),
    (   length(AllSessions, L), L =< Limit
    ->  Sessions = AllSessions
    ;   length(Sessions, Limit),
        append(Sessions, _, AllSessions)
    ).

%% valid_assignment_v2(+SessionTerm, -Room, -Timeslot, +Partial)
valid_assignment_v2(session(Session, Group), Room, Ts, Partial) :-
    % 1. Trouver l'enseignant unique
    once(session_instructor(Session, Instr)),
    % 2. Trouver tous les créneaux UNIQUES (setof trie et enlève les doublons)
    setof(T, instructor_available(Instr, T), UniqueTs),
    member(Ts, UniqueTs),
    % 3. Trouver la salle unique pour ce créneau
    once(session_equipment(Session, Req)),
    once((
        room_equipment(Room, Req),
        capacity_ok(Session, Room),
        no_room_conflict(Room, Ts, Partial)
    )),
    % 4. Vérifier les conflits
    no_group_conflict(Session, Group, Ts, Partial),
    no_instructor_conflict(Session, Ts, Partial).

remaining_after_assignment(Current, NewRemaining) :-
    slot_hours(SlotHour),
    Raw is Current - SlotHour,
    ( Raw < 0.0
    -> NewRemaining = 0.0
    ;  NewRemaining is Raw
    ).

decrease_remaining_hour(Session) :-
    retract(cost(Session, Ref, Current)),
    remaining_after_assignment(Current, Updated),
    assertz(cost(Session, Ref, Updated)).

apply_schedule_costs([]).
apply_schedule_costs([assignment(Session, _, _, _) | Rest]) :-
    decrease_remaining_hour(Session),
    apply_schedule_costs(Rest).

reset_remaining_hours :-
    findall(Session-Ref, cost(Session, Ref, _), RefPairs),
    retractall(cost(_, _, _)),
    forall(
        member(Session-Ref, RefPairs),
        assertz(cost(Session, Ref, Ref))
    ).


/* ============================================================
   SECTION 12 : UTILITAIRES
   ============================================================ */

minutes_to_label(480, '08h00').
minutes_to_label(585, '09h45').
minutes_to_label(690, '11h30').
minutes_to_label(840, '14h00').
minutes_to_label(945, '15h45').

display_assignment_v2(assignment(Session, Group, Room, Ts)) :-
    timeslot(Ts, Day, _, Min),
    minutes_to_label(Min, Label),
    format("  [~w] groupe=~w | ~w | ~w ~w~n",
           [Session, Group, Room, Day, Label]).

display_schedule([]).
display_schedule([A|As]) :-
    display_assignment_v2(A),
    display_schedule(As).

rooms_for_course(Session, Rooms) :-
    findall(R, (room(R), equipment_ok(Session, R), capacity_ok(Session, R)), Rooms).
