import type {
  Level, Day, SlotIndex, SessionKind, Session,
  Assignment, ScheduleCandidate, GlobalOccupied,
} from '../types';
import { ROOMS_BY_TYPE, ROOMS_BY_ID } from '../data/rooms';
import { LEVEL_GROUPS, COURSES_BY_LEVEL } from '../data/courses';

// ─── Constants ───────────────────────────────────────────────────────────────

const DAYS: Day[] = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
const SLOTS: SlotIndex[] = [1, 2, 3, 4, 5];

export interface SessionDemand {
  courseId: string;
  kind: SessionKind;
  group: string;       // "level" for cours, or group id for td/tp
  count: number;       // number of occurrences requested
}

function supportsKind(courseId: string, level: Level, kind: SessionKind): boolean {
  const course = COURSES_BY_LEVEL[level].find(c => c.id === courseId);
  if (!course) return false;
  if (kind === 'cours') return course.hasCours;
  if (kind === 'td') return course.hasTd;
  return course.hasTp;
}

function normalizeCount(count: number): number {
  if (!Number.isFinite(count)) return 0;
  return Math.max(0, Math.floor(count));
}

// ─── Session Building ────────────────────────────────────────────────────────

function buildSessions(
  level: Level,
  selectedCourseIds: string[],
  instructorOverrides: Record<string, string>,
  sessionDemands?: SessionDemand[]
): Session[] {
  const courses = COURSES_BY_LEVEL[level];
  const groups = LEVEL_GROUPS[level];

  const allSessions: Session[] = [];

  // Custom mode: exact request from UI (kind + count + group)
  if (sessionDemands && sessionDemands.length > 0) {
    for (const demand of sessionDemands) {
      const count = normalizeCount(demand.count);
      if (count <= 0) continue;

      const course = courses.find(c => c.id === demand.courseId);
      if (!course) continue;
      if (!supportsKind(demand.courseId, level, demand.kind)) continue;

      if (demand.kind === 'cours' && demand.group !== 'level') continue;
      if (demand.kind !== 'cours' && !groups.includes(demand.group)) continue;

      const instructor = instructorOverrides[demand.courseId] ?? course.defaultInstructor;
      const priority = demand.kind === 'cours' ? 1 : demand.kind === 'td' ? 2 : 3;
      for (let i = 0; i < count; i++) {
        const idx = i + 1;
        const sessionId = `${level}_${demand.courseId}_${demand.kind}${idx}`;
        allSessions.push({
          sessionId,
          courseId: demand.courseId,
          courseLabel: course.label,
          level,
          kind: demand.kind,
          group: demand.group,
          instructor,
          priority,
        });
      }
    }
    return allSessions;
  }

  // Priority 1: cours (level-wide)
  for (const courseId of selectedCourseIds) {
    const course = courses.find(c => c.id === courseId);
    if (!course || !course.hasCours) continue;
    const instructor = instructorOverrides[courseId] ?? course.defaultInstructor;
    allSessions.push({
      sessionId: `${level}_${courseId}_cours`,
      courseId,
      courseLabel: course.label,
      level,
      kind: 'cours',
      group: 'level',
      instructor,
      priority: 1,
    });
  }

  // Priority 2: td (per group)
  for (const courseId of selectedCourseIds) {
    const course = courses.find(c => c.id === courseId);
    if (!course || !course.hasTd) continue;
    const instructor = instructorOverrides[courseId] ?? course.defaultInstructor;
    for (let gi = 0; gi < groups.length; gi++) {
      allSessions.push({
        sessionId: `${level}_${courseId}_td${gi + 1}`,
        courseId,
        courseLabel: course.label,
        level,
        kind: 'td',
        group: groups[gi],
        instructor,
        priority: 2,
      });
    }
  }

  // Priority 3: tp (per group)
  for (const courseId of selectedCourseIds) {
    const course = courses.find(c => c.id === courseId);
    if (!course || !course.hasTp) continue;
    const instructor = instructorOverrides[courseId] ?? course.defaultInstructor;
    for (let gi = 0; gi < groups.length; gi++) {
      allSessions.push({
        sessionId: `${level}_${courseId}_tp${gi + 1}`,
        courseId,
        courseLabel: course.label,
        level,
        kind: 'tp',
        group: groups[gi],
        instructor,
        priority: 3,
      });
    }
  }

  return allSessions;
}

// ─── LCG Seeded Shuffle ──────────────────────────────────────────────────────

function seededShuffle<T>(arr: T[], seed: number): T[] {
  const result = [...arr];
  let s = seed >>> 0;
  for (let i = result.length - 1; i > 0; i--) {
    s = (Math.imul(s, 1664525) + 1013904223) >>> 0;
    const j = s % (i + 1);
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

// ─── Room type mapping ───────────────────────────────────────────────────────

function roomTypeForKind(kind: SessionKind): string {
  if (kind === 'cours') return 'amphi';
  if (kind === 'td') return 'salle_td';
  return 'labo_pc';
}

// ─── Conflict Checks ─────────────────────────────────────────────────────────

function groupConflicts(groupA: string, groupB: string, level: Level): boolean {
  if (groupA === 'level' && groupB === 'level') return true;
  if (groupA === 'level') return groupB.startsWith(level);
  if (groupB === 'level') return groupA.startsWith(level);
  return groupA === groupB;
}

function canPlace(
  session: Session,
  day: Day,
  slot: SlotIndex,
  roomId: string,
  partial: Assignment[],
  globalOccupied: GlobalOccupied
): boolean {
  const roomKey = `${roomId}_${day}_${slot}`;
  const instrKey = `${session.instructor}_${day}_${slot}`;

  // Check global occupied sets (cross-level locks)
  if (globalOccupied.roomSlots.has(roomKey)) return false;
  if (globalOccupied.instructorSlots.has(instrKey)) return false;

  // Check partial assignments (within current schedule)
  for (const asgn of partial) {
    if (asgn.day !== day || asgn.slot !== slot) continue;

    // Room conflict
    if (asgn.roomId === roomId) return false;

    // Group conflict
    if (groupConflicts(session.group, asgn.session.group, session.level)) return false;

    // Instructor conflict
    if (session.instructor === asgn.session.instructor) return false;
  }

  return true;
}

// ─── Backtracking Scheduler ──────────────────────────────────────────────────

function scheduleOne(
  sessions: Session[],
  index: number,
  partial: Assignment[],
  globalOccupied: GlobalOccupied,
  orderedDays: Day[],
  orderedSlots: SlotIndex[]
): Assignment[] | null {
  if (index === sessions.length) return [...partial];

  const session = sessions[index];
  const roomType = roomTypeForKind(session.kind);
  const candidateRooms = ROOMS_BY_TYPE[roomType] ?? [];

  for (const day of orderedDays) {
    for (const slot of orderedSlots) {
      for (const room of candidateRooms) {
        if (canPlace(session, day, slot, room.id, partial, globalOccupied)) {
          partial.push({ session, day, slot, roomId: room.id });
          const result = scheduleOne(sessions, index + 1, partial, globalOccupied, orderedDays, orderedSlots);
          if (result !== null) return result;
          partial.pop();
        }
      }
    }
  }

  return null;
}

// ─── Metrics ─────────────────────────────────────────────────────────────────

function computeMetrics(assignments: Assignment[]): ScheduleCandidate['metrics'] {
  // E_total: sum of room.energyCost * 1.5 for each assignment
  const eTotal = assignments.reduce((acc, a) => {
    const room = ROOMS_BY_ID[a.roomId];
    return acc + (room ? room.energyCost * 1.5 : 0);
  }, 0);

  // Imbalance: per-day sum of (max_building_energy - min_building_energy)
  // Buildings: amphi, td_room, labo
  const buildingTypes = ['amphi', 'salle_td', 'labo_pc'];
  let imbalance = 0;
  for (const day of DAYS) {
    const dayAssignments = assignments.filter(a => a.day === day);
    const energyPerBuilding = buildingTypes.map(bt => {
      return dayAssignments
        .filter(a => ROOMS_BY_ID[a.roomId]?.type === bt)
        .reduce((sum, a) => {
          const room = ROOMS_BY_ID[a.roomId];
          return sum + (room ? room.energyCost : 0);
        }, 0);
    });
    const nonZero = energyPerBuilding.filter(e => e > 0);
    if (nonZero.length >= 2) {
      imbalance += Math.max(...nonZero) - Math.min(...nonZero);
    }
  }

  // Fairness: variance of room usage counts across all 7 rooms
  const ROOM_IDS = ['A1', 'A2', 'R103', 'R105', 'R115', 'Li013', 'Li116'];
  const usageCounts = ROOM_IDS.map(id =>
    assignments.filter(a => a.roomId === id).length
  );
  const mean = usageCounts.reduce((s, c) => s + c, 0) / usageCounts.length;
  const variance = usageCounts.reduce((s, c) => s + (c - mean) ** 2, 0) / usageCounts.length;

  return {
    eTotal: Math.round(eTotal * 10) / 10,
    imbalance,
    fairness: Math.round(variance * 100) / 100,
    sessionCount: assignments.length,
  };
}

// ─── Public API ──────────────────────────────────────────────────────────────

export interface GenerateOptions {
  level: Level;
  selectedCourseIds: string[];
  instructorOverrides: Record<string, string>;
  sessionDemands?: SessionDemand[];
  globalOccupied: GlobalOccupied;
}

export function generateCandidates(options: GenerateOptions): ScheduleCandidate[] {
  const { level, selectedCourseIds, instructorOverrides, sessionDemands, globalOccupied } = options;
  const sessions = buildSessions(level, selectedCourseIds, instructorOverrides, sessionDemands);

  const NUM_CANDIDATES = 10;
  const candidates: ScheduleCandidate[] = [];

  for (let seed = 0; seed < NUM_CANDIDATES * 3 && candidates.length < NUM_CANDIDATES; seed++) {
    const orderedDays = seededShuffle(DAYS, seed * 7 + 1);
    const orderedSlots = seededShuffle(SLOTS, seed * 13 + 3);
    const orderedSessions = seededShuffle(sessions, seed * 31 + 7);

    const result = scheduleOne(orderedSessions, 0, [], globalOccupied, orderedDays, orderedSlots);
    if (result === null) continue;

    // Deduplicate by session assignment signature
    const sig = result
      .map(a => `${a.session.sessionId}:${a.day}:${a.slot}:${a.roomId}`)
      .sort()
      .join('|');
    const isDuplicate = candidates.some(c => {
      const csig = c.assignments
        .map(a => `${a.session.sessionId}:${a.day}:${a.slot}:${a.roomId}`)
        .sort()
        .join('|');
      return csig === sig;
    });

    if (!isDuplicate) {
      candidates.push({
        rank: 0,
        assignments: result,
        metrics: computeMetrics(result),
      });
    }
  }

  // Sort lexicographically: eTotal asc, imbalance asc, fairness asc
  candidates.sort((a, b) => {
    if (a.metrics.eTotal !== b.metrics.eTotal) return a.metrics.eTotal - b.metrics.eTotal;
    if (a.metrics.imbalance !== b.metrics.imbalance) return a.metrics.imbalance - b.metrics.imbalance;
    return a.metrics.fairness - b.metrics.fairness;
  });

  // Assign ranks
  return candidates.map((c, i) => ({ ...c, rank: i + 1 }));
}
