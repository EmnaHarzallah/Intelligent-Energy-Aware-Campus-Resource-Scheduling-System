// ─── Domain Types ────────────────────────────────────────────────────────────

export type Level = 'gl2' | 'gl3' | 'gl4';
export type Day = 'lundi' | 'mardi' | 'mercredi' | 'jeudi' | 'vendredi' | 'samedi';
export type SlotIndex = 1 | 2 | 3 | 4 | 5;
export type SessionKind = 'cours' | 'td' | 'tp';
export type RoomType = 'amphi' | 'salle_td' | 'labo_pc';
export type SessionCountConfig = Record<SessionKind, number>;

export interface Room {
  id: string;
  type: RoomType;
  capacity: number;
  energyCost: number;
}

export interface Course {
  id: string;            // e.g. "archi_res"
  label: string;         // human-readable name
  level: Level;
  hasCours: boolean;
  hasTd: boolean;
  hasTp: boolean;
  defaultInstructor: string;
}

export interface Session {
  sessionId: string;     // e.g. "gl3_prog_logique_td1"
  courseId: string;      // e.g. "prog_logique"
  courseLabel: string;
  level: Level;
  kind: SessionKind;
  group: string;         // "level" for cours, "gl3_1" for td/tp
  instructor: string;
  priority: 1 | 2 | 3;
}

export interface Assignment {
  session: Session;
  day: Day;
  slot: SlotIndex;
  roomId: string;
}

export interface ScheduleCandidate {
  rank: number;
  assignments: Assignment[];
  metrics: {
    eTotal: number;
    imbalance: number;
    fairness: number;
    sessionCount: number;
  };
}

export interface ConfirmedSchedule {
  id: string;
  level: Level;
  assignments: Assignment[];
  confirmedAt: Date;
  rank: number;
  metrics: ScheduleCandidate['metrics'];
}

export interface GlobalOccupied {
  roomSlots: Set<string>;       // "roomId_day_slot"
  instructorSlots: Set<string>; // "instructor_day_slot"
}

export interface InstructorOverride {
  [courseId: string]: string;
}
