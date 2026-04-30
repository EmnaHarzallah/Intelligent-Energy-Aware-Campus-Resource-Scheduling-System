import type { Level, Assignment, Session, SessionKind, ScheduleCandidate } from '../types';
import { COURSES_BY_LEVEL } from '../data/courses';
import { generateCandidates, type GenerateOptions as GenerateCandidatesInput } from './engine';

// ─── Server response types ────────────────────────────────────────────────────

interface PrologAssignment {
  sessionName: string;
  group: string;
  roomId: string;        // lowercase Prolog atom e.g. "a1", "li013"
  day: string;
  slot: number;
}

interface PrologCandidate {
  rank: number;
  metrics: { eTotal: number; imbalance: number; fairness: number; sessionCount: number };
  assignments: PrologAssignment[];
}

interface PrologResponse {
  candidates: PrologCandidate[];
  error?: string;
}

// ─── Parse "gl3_prog_logique_cours" → { courseId, kind } ─────────────────────

function parseSessionName(
  sessionName: string,
  level: Level
): { courseId: string; kind: SessionKind } | null {
  const prefix = `${level}_`;
  if (!sessionName.startsWith(prefix)) return null;
  const rest = sessionName.slice(prefix.length);

  if (rest.endsWith('_cours')) {
    return { courseId: rest.slice(0, -6), kind: 'cours' };
  }
  const tdMatch = rest.match(/^(.+)_td\d+$/);
  if (tdMatch) return { courseId: tdMatch[1], kind: 'td' };
  const tpMatch = rest.match(/^(.+)_tp\d+$/);
  if (tpMatch) return { courseId: tpMatch[1], kind: 'tp' };
  return null;
}

// ─── Convert one Prolog assignment → React Assignment ────────────────────────

function convertAssignment(
  pa: PrologAssignment,
  level: Level,
  instructorOverrides: Record<string, string>
): Assignment | null {
  const parsed = parseSessionName(pa.sessionName, level);
  if (!parsed) return null;

  const { courseId, kind } = parsed;
  const course = COURSES_BY_LEVEL[level].find(c => c.id === courseId);
  if (!course) return null;

  const session: Session = {
    sessionId: pa.sessionName,
    courseId,
    courseLabel: course.label,
    level,
    kind,
    group: pa.group,
    instructor: instructorOverrides[courseId] ?? course.defaultInstructor,
    priority: kind === 'cours' ? 1 : kind === 'td' ? 2 : 3,
  };

  // Prolog returns lowercase room IDs ("a1", "li013"); React uses title-case ("A1", "Li013")
  const roomId = pa.roomId.charAt(0).toUpperCase() + pa.roomId.slice(1);

  return {
    session,
    day: pa.day as any,
    slot: pa.slot as any,
    roomId,
  };
}

// ─── Call Prolog server ───────────────────────────────────────────────────────

async function callPrologServer(input: GenerateCandidatesInput): Promise<ScheduleCandidate[]> {
  const { level, selectedCourseIds, instructorOverrides, globalOccupied } = input;

  const res = await fetch('/api/schedule', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      level,
      selectedCourseIds,
      instructorOverrides,
      globalOccupied: {
        roomSlots: Array.from(globalOccupied.roomSlots),
        instructorSlots: Array.from(globalOccupied.instructorSlots),
      },
    }),
    signal: AbortSignal.timeout(60_000),
  });

  if (!res.ok) throw new Error(`HTTP ${res.status}`);

  const data: PrologResponse = await res.json();
  if (data.error) throw new Error(data.error);

  return (data.candidates ?? []).map(pc => ({
    rank: pc.rank,
    metrics: pc.metrics,
    assignments: pc.assignments
      .map(pa => convertAssignment(pa, level, instructorOverrides))
      .filter((a): a is Assignment => a !== null),
  }));
}

// ─── Public API: try Prolog, fall back to TypeScript engine ──────────────────

export type EngineSource = 'prolog' | 'typescript';

export async function generateCandidatesWithFallback(
  input: GenerateCandidatesInput
): Promise<{ candidates: ScheduleCandidate[]; source: EngineSource }> {
  try {
    const candidates = await callPrologServer(input);
    return { candidates, source: 'prolog' };
  } catch {
    const candidates = generateCandidates(input);
    return { candidates, source: 'typescript' };
  }
}
