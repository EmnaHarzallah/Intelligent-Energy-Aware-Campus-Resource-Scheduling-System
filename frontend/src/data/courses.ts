import type { Course, Level } from '../types';

export const COURSES_BY_LEVEL: Record<Level, Course[]> = {
  gl2: [
    { id: 'archi_res',   label: 'Architecture Réseaux',   level: 'gl2', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Loukil Adlène' },
    { id: 'analyse2',    label: 'Analyse Mathématique 2', level: 'gl2', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Trigui Elloumi Fatma' },
    { id: 'algebre2',    label: 'Algèbre 2',              level: 'gl2', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Hmida Jendoubi Nadia' },
    { id: 'sgbd',        label: 'SGBD',                   level: 'gl2', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Baklouti Fatma' },
    { id: 'csi',         label: "Conception des SI",      level: 'gl2', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Bouzidi Sonia' },
    { id: 'applic_rep',  label: 'Applications Réparties', level: 'gl2', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Ben Hassouna Asma' },
    { id: 'tech_web',    label: 'Technologies Web',       level: 'gl2', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Sellaouti Aymen' },
    { id: 'atelier_java',label: 'Atelier Java Avancé',    level: 'gl2', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Jemai Abderrazak' },
    { id: 'unix',        label: 'Système UNIX',           level: 'gl2', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Mami Imen' },
    { id: 'droit',       label: "Droit de l'Homme",       level: 'gl2', hasCours: true, hasTd: false, hasTp: false, defaultInstructor: 'Boukottaya Hanen' },
    { id: 'comptabilite',label: 'Comptabilité',           level: 'gl2', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Bouaziz Samira' },
    { id: 'anglais',     label: 'Anglais',                level: 'gl2', hasCours: false,hasTd: true,  hasTp: false, defaultInstructor: 'Ben Rejeb Ihsen' },
  ],
  gl3: [
    { id: 'prog_logique', label: 'Programmation Logique',      level: 'gl3', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Khalgui Mohamed' },
    { id: 'bases_rel',    label: 'Bases de Données Rel.',      level: 'gl3', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Baklouti Fatma' },
    { id: 'bases_nonrel', label: 'Bases de Données Non-Rel.',  level: 'gl3', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Baklouti Fatma' },
    { id: 'fond_syst_rep',label: 'Fondements Systèmes Répartis',level:'gl3', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Ouni Sofiane' },
    { id: 'analyse_num',  label: 'Analyse Numérique',           level: 'gl3', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Arbi Adnen' },
    { id: 'optimisation', label: 'Optimisation Appliquée',      level: 'gl3', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Sfaxi Mourad' },
    { id: 'analyse_data', label: "Analyse des Données",        level: 'gl3', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Arbi Adnèn' },
    { id: 'algorithmique',label: 'Algorithmique Avancée',      level: 'gl3', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Gasmi Ghada' },
    { id: 'complexite',   label: 'Complexité des Algorithmes', level: 'gl3', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Mliki Hazar' },
    { id: 'co_design',    label: 'Co-Design',                  level: 'gl3', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Damergi Emir' },
    { id: 'protoc_web',   label: 'Protocoles Web / APIs',      level: 'gl3', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Sellaouti Aymen' },
    { id: 'methodo_conc', label: 'Méthodologies de Conception',level: 'gl3', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Gasmi Ghada' },
    { id: 'marketing',    label: 'Marketing',                  level: 'gl3', hasCours: true, hasTd: false, hasTp: false, defaultInstructor: 'Ben Gamra Imene' },
    { id: 'francais',     label: 'Français',                   level: 'gl3', hasCours: false,hasTd: true,  hasTp: false, defaultInstructor: 'Zanina Wiem' },
    { id: 'anglais',      label: 'Anglais',                    level: 'gl3', hasCours: false,hasTd: true,  hasTp: false, defaultInstructor: 'Bichiou Imene' },
    { id: 'ppp',          label: 'Projet Perso Professionnel', level: 'gl3', hasCours: false,hasTd: false, hasTp: true,  defaultInstructor: 'Taktak Hajer' },
  ],
  gl4: [
    { id: 'devops',         label: 'DevSecOps / DevOps',      level: 'gl4', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Ben Yahia Saloua' },
    { id: 'deep_learning',  label: 'Deep Learning',           level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Hamdi Sana' },
    { id: 'compilation',    label: 'Compilation',             level: 'gl4', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Khalgui Mohamed' },
    { id: 'big_data',       label: 'Big Data',                level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Sfaxi Lilia' },
    { id: 'traitement_img', label: "Traitement d'Images",     level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Bouzidi Sonia' },
    { id: 'archi_log',      label: 'Architectures Logicielles',level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Sfaxi Lilia' },
    { id: 'ihm',            label: 'Interface Homme-Machine', level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Taktak Hajer' },
    { id: 'test_logiciel',  label: 'Tests Logiciels',         level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Bouzidi Sonia' },
    { id: 'protoc_secu',    label: 'Protocoles de Sécurité',  level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Gasmi Maroua' },
    { id: 'grh',            label: 'Gestion RH',              level: 'gl4', hasCours: true, hasTd: false, hasTp: false, defaultInstructor: 'Mzabi Hela' },
    { id: 'management',     label: 'Management de Projets',   level: 'gl4', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Abdelmoula Naouel' },
    { id: 'anglais',        label: 'Anglais',                 level: 'gl4', hasCours: false,hasTd: true,  hasTp: false, defaultInstructor: 'Negra Amamou Bouthei' },
  ],
};

export const LEVEL_GROUPS: Record<string, string[]> = {
  gl2: ['gl2_1', 'gl2_2', 'gl2_3'],
  gl3: ['gl3_1', 'gl3_2'],
  gl4: ['gl4_1', 'gl4_2'],
};

export const LEVEL_LIMITS: Record<string, number> = {
  gl2: 14,
  gl3: 17,
  gl4: 14,
};

export const LEVEL_ACCENTS: Record<string, string> = {
  gl2: '#6f8f86',
  gl3: '#8f2b2e',
  gl4: '#c17a42',
};

export const COURSE_PALETTE = [
  '#6f8f86', '#8f2b2e', '#c17a42', '#8ea7a0',
  '#9f7b72', '#2f7d63', '#b14b52', '#caa05d',
  '#5f6f79', '#9e7d7b',
];

export const DAYS: { id: string; label: string }[] = [
  { id: 'lundi',    label: 'Lun' },
  { id: 'mardi',    label: 'Mar' },
  { id: 'mercredi', label: 'Mer' },
  { id: 'jeudi',    label: 'Jeu' },
  { id: 'vendredi', label: 'Ven' },
  { id: 'samedi',   label: 'Sam' },
];

export const TIMESLOTS: { slot: number; label: string }[] = [
  { slot: 1, label: '08:00' },
  { slot: 2, label: '09:30' },
  { slot: 3, label: '11:00' },
  { slot: 4, label: '14:00' },
  { slot: 5, label: '15:30' },
];

