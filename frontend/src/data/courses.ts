import type { Course, Level } from '../types';

export const COURSES_BY_LEVEL: Record<Level, Course[]> = {
  gl2: [
    { id: 'archi_res',   label: 'Architecture Réseaux',   level: 'gl2', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Loukil Adlène' },
    { id: 'analyse2',    label: 'Analyse Mathématique 2', level: 'gl2', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Trigui Elloumi Fatma' },
    { id: 'algebre2',    label: 'Algèbre 2',              level: 'gl2', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Hmida Jendoubi Nadia' },
    { id: 'sgbd',        label: 'SGBD',                   level: 'gl2', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Baklouti Fatma' },
    { id: 'tech_web',    label: 'Technologies Web',       level: 'gl2', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Sellaouti Aymen' },
    { id: 'atelier_java',label: 'Atelier Java Avancé',    level: 'gl2', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Jemai Abderrazak' },
    { id: 'unix',        label: 'Système UNIX',           level: 'gl2', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Mami Imen' },
  ],
  gl3: [
    { id: 'prog_logique', label: 'Programmation Logique',      level: 'gl3', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Khalgui Mohamed' },
    { id: 'bases_rel',    label: 'Bases de Données Rel.',      level: 'gl3', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Baklouti Fatma' },
    { id: 'bases_nonrel', label: 'Bases de Données Non-Rel.',  level: 'gl3', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Baklouti Fatma' },
    { id: 'analyse_data', label: "Analyse des Données",        level: 'gl3', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Arbi Adnèn' },
    { id: 'algorithmique',label: 'Algorithmique Avancée',      level: 'gl3', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Gasmi Ghada' },
    { id: 'complexite',   label: 'Complexité des Algorithmes', level: 'gl3', hasCours: true, hasTd: true,  hasTp: false, defaultInstructor: 'Mliki Hazar' },
    { id: 'protoc_web',   label: 'Protocoles Web / APIs',      level: 'gl3', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Sellaouti Aymen' },
  ],
  gl4: [
    { id: 'devops',         label: 'DevSecOps / DevOps',      level: 'gl4', hasCours: true, hasTd: true,  hasTp: true,  defaultInstructor: 'Ben Yahia Saloua' },
    { id: 'deep_learning',  label: 'Deep Learning',           level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Hamdi Sana' },
    { id: 'big_data',       label: 'Big Data',                level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Sfaxi Lilia' },
    { id: 'traitement_img', label: "Traitement d'Images",     level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Bouzidi Sonia' },
    { id: 'archi_log',      label: 'Architectures Logicielles',level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Sfaxi Lilia' },
    { id: 'test_logiciel',  label: 'Tests Logiciels',         level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Bouzidi Sonia' },
    { id: 'protoc_secu',    label: 'Protocoles de Sécurité',  level: 'gl4', hasCours: true, hasTd: false, hasTp: true,  defaultInstructor: 'Gasmi Maroua' },
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
  gl2: '#00c9b1',
  gl3: '#7c6af7',
  gl4: '#f97316',
};

export const COURSE_PALETTE = [
  '#00c9b1', '#7c6af7', '#f97316', '#22d3ee',
  '#a78bfa', '#34d399', '#fb7185', '#fbbf24',
  '#60a5fa', '#c084fc',
];

export const DAYS: { id: string; label: string }[] = [
  { id: 'lundi',    label: 'Lun' },
  { id: 'mardi',    label: 'Mar' },
  { id: 'mercredi', label: 'Mer' },
  { id: 'jeudi',    label: 'Jeu' },
  { id: 'vendredi', label: 'Ven' },
];

export const TIMESLOTS: { slot: number; label: string }[] = [
  { slot: 1, label: '08:00' },
  { slot: 2, label: '09:30' },
  { slot: 3, label: '11:00' },
  { slot: 4, label: '14:00' },
  { slot: 5, label: '15:30' },
];
