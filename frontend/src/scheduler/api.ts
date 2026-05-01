import type { Level, Assignment, Session, SessionKind, ScheduleCandidate } from '../types';
import { COURSES_BY_LEVEL } from '../data/courses';
import type { GenerateOptions as GenerateCandidatesInput } from './engine';

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

interface PrologScheduleResponse {
  mode?: string;
  totalCandidates?: number;
  evaluatedCandidates?: number;
  explanation?: string;
  best?: PrologCandidate | null;
  candidates: PrologCandidate[];
  error?: string;
}

interface InstructorCatalogEntry {
  cours?: string[];
  td?: string[];
  tp?: string[];
  all?: string[];
}

interface InstructorCatalogResponse {
  levels?: Record<string, Record<string, InstructorCatalogEntry>>;
}

export type InstructorOptionsByLevel = Record<Level, Record<string, string[]>>;
export type EngineSource = 'prolog' | 'typescript';
export type ScheduleMode = 'explore' | 'optimize';

export interface ExploreResult {
  source: EngineSource;
  mode: 'explore';
  totalCandidates: number;
  candidates: ScheduleCandidate[];
}

export interface OptimizeResult {
  source: EngineSource;
  mode: 'optimize';
  evaluatedCandidates: number;
  explanation: string;
  bestRank: number | null;
  candidates: ScheduleCandidate[];
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

async function callPrologServer(
  input: GenerateCandidatesInput,
  mode: ScheduleMode,
  maxCandidates: number
): Promise<PrologScheduleResponse> {
  const { level, selectedCourseIds, instructorOverrides, sessionDemands, globalOccupied } = input;

  let res: Response;
  try {
    res = await fetch('/api/schedule', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        level,
        mode,
        maxCandidates,
        selectedCourseIds,
        instructorOverrides,
        sessionDemands: sessionDemands ?? [],
        globalOccupied: {
          roomSlots: Array.from(globalOccupied.roomSlots),
          instructorSlots: Array.from(globalOccupied.instructorSlots),
        },
      }),
      signal: AbortSignal.timeout(45_000),
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    if (/timed out|timeout|aborted/i.test(msg)) {
      throw new Error(
        "Delai de reponse depasse. Le serveur est peut-etre occupe; reessayez dans quelques secondes."
      );
    }
    throw err;
  }

  if (!res.ok) throw new Error(`HTTP ${res.status}`);

  const data: PrologScheduleResponse = await res.json();
  if (data.error) throw new Error(data.error);

  return data;
}

function convertCandidates(
  prologCandidates: PrologCandidate[] | undefined,
  level: Level,
  instructorOverrides: Record<string, string>
): ScheduleCandidate[] {
  return (prologCandidates ?? []).map(pc => ({
    rank: pc.rank,
    metrics: pc.metrics,
    assignments: pc.assignments
      .map(pa => convertAssignment(pa, level, instructorOverrides))
      .filter((a): a is Assignment => a !== null),
  }));
}

export async function generateFeasibleCandidates(
  input: GenerateCandidatesInput
): Promise<ExploreResult> {
  const data = await callPrologServer(input, 'explore', 40);
  const candidates = convertCandidates(data.candidates, input.level, input.instructorOverrides);
  return {
    source: 'prolog',
    mode: 'explore',
    totalCandidates: data.totalCandidates ?? candidates.length,
    candidates,
  };
}

export async function optimizeCandidates(
  input: GenerateCandidatesInput
): Promise<OptimizeResult> {
  const data = await callPrologServer(input, 'optimize', 60);
  const candidates = convertCandidates(data.candidates, input.level, input.instructorOverrides);
  const best = data.best
    ? convertCandidates([data.best], input.level, input.instructorOverrides)[0]
    : null;
  return {
    source: 'prolog',
    mode: 'optimize',
    evaluatedCandidates: data.evaluatedCandidates ?? candidates.length,
    explanation: data.explanation ?? 'Classement lexicographique (E_total, imbalance, fairness).',
    bestRank: best?.rank ?? candidates[0]?.rank ?? null,
    candidates,
  };
}

// Backward compatibility for previous caller path.
export async function generateCandidatesWithFallback(
  input: GenerateCandidatesInput
): Promise<{ candidates: ScheduleCandidate[]; source: EngineSource }> {
  const optimized = await optimizeCandidates(input);
  return { candidates: optimized.candidates, source: optimized.source };
}

export async function fetchInstructorOptionsByLevel(
  timeoutMs = 10_000
): Promise<InstructorOptionsByLevel> {
  const result: InstructorOptionsByLevel = { gl2: {}, gl3: {}, gl4: {} };

  const res = await fetch('/api/instructors', {
    method: 'GET',
    signal: AbortSignal.timeout(timeoutMs),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);

  const data = (await res.json()) as InstructorCatalogResponse;
  const levels = data.levels ?? {};

  (['gl2', 'gl3', 'gl4'] as const).forEach((level) => {
    const levelCatalog = levels[level];
    if (!levelCatalog) return;

    for (const [courseId, entry] of Object.entries(levelCatalog)) {
      const all = Array.isArray(entry.all)
        ? entry.all.filter((name): name is string => typeof name === 'string' && name.trim().length > 0)
        : [];
      if (all.length === 0) continue;
      result[level][courseId] = Array.from(new Set(all));
    }
  });

  return result;
}
