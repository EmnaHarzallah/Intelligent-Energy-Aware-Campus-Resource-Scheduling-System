import React, { useEffect, useMemo, useRef, useState } from 'react';
import type {
  ConfirmedSchedule,
  Course,
  GlobalOccupied,
  Level,
  ScheduleCandidate,
  SessionCountConfig,
  SessionKind,
} from '../types';
import { COURSES_BY_LEVEL, LEVEL_GROUPS, LEVEL_ACCENTS } from '../data/courses';
import {
  fetchInstructorOptionsByLevel,
  generateFeasibleCandidates,
  optimizeCandidates,
  type EngineSource,
  type InstructorOptionsByLevel,
} from '../scheduler/api';
import GroupCard from './GroupCard';
import SolutionCard from './SolutionCard';
import OptimizationReport from './OptimizationReport';
import type { GenerateOptions as ScheduleRequestPayload } from '../scheduler/engine';

interface PlanifierViewProps {
  globalOccupied: GlobalOccupied;
  onConfirm: (schedule: ConfirmedSchedule) => void;
}

type ViewState = 'idle' | 'loading' | 'results' | 'no-solution' | 'backend-error';
type ResultMode = 'explore' | 'optimize';

function defaultSessionCountsForCourse(course: Course): SessionCountConfig {
  return {
    cours: course.hasCours ? 1 : 0,
    td: course.hasTd ? 1 : 0,
    tp: course.hasTp ? 1 : 0,
  };
}

function normalizeCount(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(8, Math.floor(value)));
}

function fallbackInstructorOptions(): InstructorOptionsByLevel {
  const result: InstructorOptionsByLevel = { gl2: {}, gl3: {}, gl4: {} };
  (['gl2', 'gl3', 'gl4'] as const).forEach((level) => {
    for (const course of COURSES_BY_LEVEL[level]) {
      result[level][course.id] = [course.defaultInstructor];
    }
  });
  return result;
}

function mergeInstructorOptions(
  fallback: InstructorOptionsByLevel,
  remote: InstructorOptionsByLevel
): InstructorOptionsByLevel {
  const merged: InstructorOptionsByLevel = { gl2: {}, gl3: {}, gl4: {} };
  (['gl2', 'gl3', 'gl4'] as const).forEach((level) => {
    for (const course of COURSES_BY_LEVEL[level]) {
      const defaults = fallback[level][course.id] ?? [course.defaultInstructor];
      const options = remote[level][course.id];
      merged[level][course.id] = options && options.length > 0 ? options : defaults;
    }
  });
  return merged;
}

export default function PlanifierView({ globalOccupied, onConfirm }: PlanifierViewProps) {
  const [activeLevel, setActiveLevel] = useState<Level>('gl3');

  // État de sélection : clé = groupId (ex: "gl3_1"), valeur = Set des courseIds sélectionnées
  const [selectedCourseIds, setSelectedCourseIds] = useState<Record<string, Set<string>>>(
    () => {
      const init: Record<string, Set<string>> = {};
      (['gl2', 'gl3', 'gl4'] as Level[]).forEach(lvl => {
        LEVEL_GROUPS[lvl].forEach(g => { init[g] = new Set(); });
      });
      return init;
    }
  );

  // Overrides d'enseignant : clé = groupId, valeur = { courseId → instructor }
  const [instructorOverrides, setInstructorOverrides] = useState<Record<string, Record<string, string>>>(
    () => {
      const init: Record<string, Record<string, string>> = {};
      (['gl2', 'gl3', 'gl4'] as Level[]).forEach(lvl => {
        LEVEL_GROUPS[lvl].forEach(g => { init[g] = {}; });
      });
      return init;
    }
  );

  // Quantité demandée de séances par groupe -> matière -> {cours, td, tp}
  const [sessionCountsByGroup, setSessionCountsByGroup] = useState<Record<string, Record<string, SessionCountConfig>>>(
    () => {
      const init: Record<string, Record<string, SessionCountConfig>> = {};
      (['gl2', 'gl3', 'gl4'] as Level[]).forEach(lvl => {
        LEVEL_GROUPS[lvl].forEach(g => { init[g] = {}; });
      });
      return init;
    }
  );

  const [instructorOptionsByLevel, setInstructorOptionsByLevel] = useState<InstructorOptionsByLevel>(
    () => fallbackInstructorOptions()
  );

  const [viewState, setViewState] = useState<ViewState>('idle');
  const [backendError, setBackendError] = useState<string | null>(null);
  const [candidates, setCandidates] = useState<ScheduleCandidate[]>([]);
  const [resultMode, setResultMode] = useState<ResultMode | null>(null);
  const [selectedRank, setSelectedRank] = useState<number | null>(null);
  const [selectedExploreIndex, setSelectedExploreIndex] = useState(0);
  const [lastRequestPayload, setLastRequestPayload] = useState<ScheduleRequestPayload | null>(null);
  const [optimizationExplanation, setOptimizationExplanation] = useState<string | null>(null);
  const [evaluatedCandidates, setEvaluatedCandidates] = useState<number>(0);
  const [engineSource, setEngineSource] = useState<EngineSource | null>(null);
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    let alive = true;
    fetchInstructorOptionsByLevel()
      .then((remote) => {
        if (!alive) return;
        setInstructorOptionsByLevel((prev) => mergeInstructorOptions(prev, remote));
      })
      .catch(() => undefined);
    return () => {
      alive = false;
    };
  }, []);

  const currentCourses = COURSES_BY_LEVEL[activeLevel];
  const currentGroups = LEVEL_GROUPS[activeLevel];
  const currentInstructorOptions = instructorOptionsByLevel[activeLevel] ?? {};
  const accent = LEVEL_ACCENTS[activeLevel];

  const activeCandidate = candidates.length === 0
    ? null
    : resultMode === 'explore'
      ? (candidates[selectedExploreIndex] ?? candidates[0])
      : (selectedRank !== null
        ? (candidates.find(c => c.rank === selectedRank) ?? candidates[0])
        : candidates[0]);

  const occurrenceByGroup = useMemo(() => {
    const byGroup: Record<string, Record<string, number>> = {};
    for (const groupId of currentGroups) {
      byGroup[groupId] = {};
      if (!activeCandidate) continue;

      for (const asgn of activeCandidate.assignments) {
        const appliesToGroup = asgn.session.group === 'level' || asgn.session.group === groupId;
        if (!appliesToGroup) continue;

        const key = `${asgn.session.courseId}_${asgn.session.kind}`;
        byGroup[groupId][key] = (byGroup[groupId][key] ?? 0) + 1;
      }
    }
    return byGroup;
  }, [activeCandidate, currentGroups]);

  const totalRequestedForLevel = useMemo(() => {
    let tdTpTotal = 0;
    const coursByCourse: Record<string, number> = {};

    for (const groupId of currentGroups) {
      for (const courseId of selectedCourseIds[groupId]) {
        const course = currentCourses.find(c => c.id === courseId);
        if (!course) continue;
        const cfg = sessionCountsByGroup[groupId][courseId] ?? defaultSessionCountsForCourse(course);
        tdTpTotal += normalizeCount(cfg.td) + normalizeCount(cfg.tp);
        coursByCourse[courseId] = Math.max(coursByCourse[courseId] ?? 0, normalizeCount(cfg.cours));
      }
    }

    const coursTotal = Object.values(coursByCourse).reduce((sum, value) => sum + value, 0);
    return tdTpTotal + coursTotal;
  }, [currentCourses, currentGroups, selectedCourseIds, sessionCountsByGroup]);

  function resetResults() {
    setViewState('idle');
    setBackendError(null);
    setCandidates([]);
    setResultMode(null);
    setSelectedRank(null);
    setSelectedExploreIndex(0);
    setLastRequestPayload(null);
    setOptimizationExplanation(null);
    setEvaluatedCandidates(0);
  }

  function buildScheduleRequestPayload(): ScheduleRequestPayload {
    const allSelectedIds = new Set<string>();
    const overrides: Record<string, string> = {};
    const sessionDemands: Array<{ courseId: string; kind: SessionKind; group: string; count: number }> = [];
    const coursCountByCourse: Record<string, number> = {};

    for (const groupId of currentGroups) {
      for (const courseId of selectedCourseIds[groupId]) {
        const course = currentCourses.find(c => c.id === courseId);
        if (!course) continue;

        allSelectedIds.add(courseId);
        const selectedInstructor = instructorOverrides[groupId][courseId];
        const options = currentInstructorOptions[courseId] ?? [course.defaultInstructor];
        const fallbackInstructor = options[0] ?? course.defaultInstructor;
        if (selectedInstructor && selectedInstructor.trim().length > 0) {
          overrides[courseId] = selectedInstructor;
        } else if (!overrides[courseId]) {
          overrides[courseId] = fallbackInstructor;
        }

        const cfg = sessionCountsByGroup[groupId][courseId] ?? defaultSessionCountsForCourse(course);
        const tdCount = normalizeCount(cfg.td);
        const tpCount = normalizeCount(cfg.tp);
        const coursCount = normalizeCount(cfg.cours);

        if (tdCount > 0) {
          sessionDemands.push({ courseId, kind: 'td', group: groupId, count: tdCount });
        }
        if (tpCount > 0) {
          sessionDemands.push({ courseId, kind: 'tp', group: groupId, count: tpCount });
        }
        if (coursCount > 0) {
          coursCountByCourse[courseId] = Math.max(coursCountByCourse[courseId] ?? 0, coursCount);
        }
      }
    }

    for (const [courseId, count] of Object.entries(coursCountByCourse)) {
      sessionDemands.push({ courseId, kind: 'cours', group: 'level', count });
    }

    return {
      level: activeLevel,
      selectedCourseIds: Array.from(allSelectedIds),
      instructorOverrides: overrides,
      sessionDemands,
      globalOccupied,
    };
  }

  function toggleCourse(groupId: string, courseId: string) {
    const wasSelected = selectedCourseIds[groupId].has(courseId);

    setSelectedCourseIds(prev => {
      const updated = new Set(prev[groupId]);
      if (updated.has(courseId)) updated.delete(courseId);
      else updated.add(courseId);
      return { ...prev, [groupId]: updated };
    });

    if (!wasSelected) {
      const course = currentCourses.find(c => c.id === courseId);
      if (course) {
        let sharedCours = course.hasCours ? 1 : 0;
        for (const peerGroupId of currentGroups) {
          if (peerGroupId === groupId) continue;
          const peerCfg = sessionCountsByGroup[peerGroupId][courseId];
          if (peerCfg && Number.isFinite(peerCfg.cours)) {
            sharedCours = normalizeCount(peerCfg.cours);
            break;
          }
        }

        setSessionCountsByGroup(prev => ({
          ...prev,
          [groupId]: {
            ...prev[groupId],
            [courseId]: prev[groupId][courseId] ?? {
              ...defaultSessionCountsForCourse(course),
              cours: sharedCours,
            },
          },
        }));
      }
    }

    // Reset results when selection changes
    resetResults();
  }

  function setInstructor(groupId: string, courseId: string, value: string) {
    setInstructorOverrides(prev => ({
      ...prev,
      [groupId]: { ...prev[groupId], [courseId]: value },
    }));

    resetResults();
  }

  function setSessionCount(groupId: string, courseId: string, kind: SessionKind, count: number) {
    const nextCount = normalizeCount(count);
    setSessionCountsByGroup(prev => {
      if (kind === 'cours') {
        const updated = { ...prev };
        for (const g of currentGroups) {
          const current = updated[g][courseId] ?? { cours: 0, td: 0, tp: 0 };
          updated[g] = {
            ...updated[g],
            [courseId]: { ...current, cours: nextCount },
          };
        }
        return updated;
      }

      const current = prev[groupId][courseId] ?? { cours: 0, td: 0, tp: 0 };
      return {
        ...prev,
        [groupId]: {
          ...prev[groupId],
          [courseId]: { ...current, [kind]: nextCount },
        },
      };
    });

    resetResults();
  }

  async function handleGenerate() {
    if (totalRequestedForLevel === 0) return;

    // Cancel any in-flight request
    abortRef.current?.abort();
    abortRef.current = new AbortController();

    setViewState('loading');
    setBackendError(null);
    setCandidates([]);
    setResultMode(null);
    setSelectedRank(null);
    setSelectedExploreIndex(0);
    setOptimizationExplanation(null);
    setEvaluatedCandidates(0);
    setEngineSource(null);

    const payload = buildScheduleRequestPayload();
    setLastRequestPayload(payload);

    try {
      const { candidates: result, source } = await generateFeasibleCandidates(payload);

      if (result.length === 0) {
        setViewState('no-solution');
      } else {
        setCandidates(result);
        setEngineSource(source);
        setResultMode('explore');
        setSelectedExploreIndex(0);
        setSelectedRank(result[0].rank);
        setViewState('results');
      }
    } catch (err) {
      const message = err instanceof Error
        ? err.message
        : 'Le backend Prolog est indisponible.';
      setBackendError(message);
      setViewState('backend-error');
    }
  }

  async function handleOptimize() {
    if (!lastRequestPayload) return;

    abortRef.current?.abort();
    abortRef.current = new AbortController();

    setViewState('loading');
    setBackendError(null);

    try {
      const result = await optimizeCandidates(lastRequestPayload);
      if (result.candidates.length === 0) {
        setViewState('no-solution');
        return;
      }

      setCandidates(result.candidates);
      setEngineSource(result.source);
      setResultMode('optimize');
      setSelectedExploreIndex(0);
      setSelectedRank(result.bestRank ?? result.candidates[0].rank);
      setOptimizationExplanation(result.explanation);
      setEvaluatedCandidates(result.evaluatedCandidates);
      setViewState('results');
    } catch (err) {
      const message = err instanceof Error
        ? err.message
        : 'Le backend Prolog est indisponible.';
      setBackendError(message);
      setViewState('backend-error');
    }
  }

  function handleExploreNavigation(step: -1 | 1) {
    if (resultMode !== 'explore' || candidates.length === 0) return;
    const total = candidates.length;
    const nextIndex = (selectedExploreIndex + step + total) % total;
    setSelectedExploreIndex(nextIndex);
    setSelectedRank(candidates[nextIndex].rank);
  }

  function handleLevelChange(level: Level) {
    setActiveLevel(level);
    resetResults();
  }

  function handleConfirm() {
    const candidate = activeCandidate;
    if (!candidate) return;

    const schedule: ConfirmedSchedule = {
      id: `${activeLevel}_${Date.now()}`,
      level: activeLevel,
      assignments: candidate.assignments,
      confirmedAt: new Date(),
      rank: candidate.rank,
      metrics: candidate.metrics,
    };
    onConfirm(schedule);
  }

  const LEVEL_TABS: Level[] = ['gl2', 'gl3', 'gl4'];

  return (
    <div style={{
      display: 'flex',
      height: 'calc(100vh - 60px)',
      overflow: 'hidden',
    }}>
      {/* ─── Left Panel ─────────────────────────────────────────── */}
      <aside style={{
        width: 'clamp(430px, 42vw, 560px)',
        minWidth: '420px',
        maxWidth: '58vw',
        flexShrink: 0,
        borderRight: '1px solid var(--bg-card-2)',
        display: 'flex',
        flexDirection: 'column',
        resize: 'horizontal',
        overflowY: 'auto',
        overflowX: 'hidden',
        background: 'var(--bg-surface)',
      }}>
        {/* Level tabs */}
        <div style={{
          display: 'flex',
          gap: '4px',
          padding: '16px 18px 0',
        }}>
          {LEVEL_TABS.map(level => {
            const levelAccent = LEVEL_ACCENTS[level];
            const isActive = activeLevel === level;
            return (
              <button
                key={level}
                type="button"
                onClick={() => handleLevelChange(level)}
                aria-pressed={isActive}
                aria-label={`Sélectionner le niveau ${level.toUpperCase()}`}
                style={{
                  flex: 1,
                  padding: '9px 4px',
                  minHeight: '44px',
                  borderRadius: '9px',
                  fontSize: '12.5px',
                  fontWeight: 700,
                  letterSpacing: '0.04em',
                  background: isActive ? `${levelAccent}18` : 'var(--bg-card)',
                  color: isActive ? levelAccent : 'var(--text-muted-2)',
                  border: isActive ? `1.5px solid ${levelAccent}50` : '1px solid var(--border-1)',
                  transition: 'background 0.14s ease, color 0.14s ease, border-color 0.14s ease',
                  cursor: 'pointer',
                }}
              >
                {level.toUpperCase()}
                {(() => {
                  const count = LEVEL_GROUPS[level].reduce(
                    (acc, g) => acc + selectedCourseIds[g].size, 0
                  );
                  return isActive && count > 0 ? (
                    <span style={{
                      marginLeft: '5px',
                      fontSize: '10px',
                      background: `${levelAccent}30`,
                      padding: '0 5px',
                      borderRadius: '3px',
                    }}>
                      {count}
                    </span>
                  ) : null;
                })()}
              </button>
            );
          })}
        </div>

        {/* Group cards */}
        <div style={{ padding: '12px 18px', flex: 1, display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {currentGroups.map(g => (
            <GroupCard
              key={g}
              groupId={g}
              level={activeLevel}
              courses={currentCourses}
              selectedCourseIds={selectedCourseIds[g]}
              instructorOverrides={instructorOverrides[g]}
              instructorOptionsByCourse={currentInstructorOptions}
              sessionCountsByCourse={sessionCountsByGroup[g]}
              occurrenceBySession={occurrenceByGroup[g]}
              occurrenceLabel={activeCandidate ? `solution #${activeCandidate.rank}` : null}
              onToggleCourse={(courseId) => toggleCourse(g, courseId)}
              onInstructorChange={(courseId, value) => setInstructor(g, courseId, value)}
              onSessionCountChange={(courseId, kind, count) => setSessionCount(g, courseId, kind, count)}
            />
          ))}
        </div>

        {/* Generate button */}
        <div style={{ padding: '12px 18px', borderTop: '1px solid var(--bg-card-2)' }}>
          <button
            onClick={handleGenerate}
            disabled={totalRequestedForLevel === 0 || viewState === 'loading'}
            style={{
              width: '100%',
              padding: '13px',
              borderRadius: '11px',
              fontSize: '13.5px',
              fontWeight: 700,
              letterSpacing: '-0.01em',
              background: totalRequestedForLevel > 0
                ? `linear-gradient(135deg, ${accent}, ${accent}aa)`
                : 'var(--bg-card-2)',
              color: totalRequestedForLevel > 0 ? 'var(--bg-base)' : 'var(--text-faint)',
              border: totalRequestedForLevel > 0 ? 'none' : '1px solid var(--border-2)',
              cursor: totalRequestedForLevel > 0 ? 'pointer' : 'not-allowed',
              transition: 'all 0.15s ease',
              opacity: viewState === 'loading' ? 0.7 : 1,
            }}
          >
            {viewState === 'loading'
              ? 'Génération en cours...'
              : `Explorer ${totalRequestedForLevel} séance(s) ${activeLevel.toUpperCase()}`
            }
          </button>
        </div>
      </aside>

      {/* ─── Right Panel ─────────────────────────────────────────── */}
      <main
        aria-live="polite"
        aria-atomic="false"
        style={{
          flex: 1,
          overflowY: 'auto',
          padding: '18px 20px',
        }}
      >
        {viewState === 'idle' && (
          <EmptyState />
        )}

        {viewState === 'loading' && (
          <LoadingState />
        )}

        {viewState === 'no-solution' && (
          <NoSolutionState level={activeLevel} />
        )}

        {viewState === 'backend-error' && (
          <BackendErrorState message={backendError} />
        )}

        {viewState === 'results' && candidates.length > 0 && (
          <ResultsPanel
            candidates={candidates}
            level={activeLevel}
            resultMode={resultMode}
            selectedRank={selectedRank}
            selectedExploreIndex={selectedExploreIndex}
            optimizationExplanation={optimizationExplanation}
            evaluatedCandidates={evaluatedCandidates}
            engineSource={engineSource}
            onSelectRank={setSelectedRank}
            onOptimize={handleOptimize}
            onExplorePrev={() => handleExploreNavigation(-1)}
            onExploreNext={() => handleExploreNavigation(1)}
            onConfirm={handleConfirm}
          />
        )}
      </main>
    </div>
  );
}

// ─── Sub-components ───────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <div style={{
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: '20px',
      opacity: 0.6,
    }}>
      {/* Illustration */}
      <div style={{ position: 'relative' }}>
        <svg width="96" height="96" viewBox="0 0 96 96" fill="none">
          <rect x="8" y="8" width="80" height="80" rx="16" fill="var(--bg-card)" stroke="var(--border-1)" strokeWidth="1.5"/>
          {/* Grid lines */}
          {[24, 40, 56, 72].map(y => (
            <line key={y} x1="8" y1={y} x2="88" y2={y} stroke="var(--border-1)" strokeWidth="1"/>
          ))}
          {[24, 44, 64].map(x => (
            <line key={x} x1={x} y1="8" x2={x} y2="88" stroke="var(--border-1)" strokeWidth="1"/>
          ))}
          {/* Sample filled cells */}
          <rect x="25" y="9" width="18" height="14" rx="3" fill="#6f8f8630"/>
          <rect x="45" y="25" width="18" height="14" rx="3" fill="var(--accent-gl3)30"/>
          <rect x="9" y="41" width="14" height="14" rx="3" fill="#c17a4230"/>
          <rect x="65" y="57" width="22" height="14" rx="3" fill="#6f8f8630"/>
          {/* Center icon */}
          <circle cx="48" cy="48" r="12" fill="var(--bg-card-2)" stroke="var(--border-2)" strokeWidth="1"/>
          <path d="M44 48h8M48 44v8" stroke="var(--text-muted)" strokeWidth="1.5" strokeLinecap="round"/>
        </svg>
      </div>
      <div style={{ textAlign: 'center' }}>
        <p style={{ fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '6px' }}>
          Sélectionner des matières
        </p>
        <p style={{ fontSize: '13px', color: 'var(--text-muted)', maxWidth: '280px', lineHeight: 1.6 }}>
          Choisissez un niveau, sélectionnez les matières, puis réglez cours/TD/TP et le nombre de séances.
        </p>
      </div>
    </div>
  );
}

function LoadingState() {
  return (
    <div style={{
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: '24px',
    }}>
      <div style={{ display: 'flex', gap: '8px' }}>
        {[0, 1, 2].map(i => (
          <div
            key={i}
            style={{
              width: 8, height: 8, borderRadius: '50%',
              background: 'var(--accent-gl3)',
              animation: `pulse-dot 1.2s ease-in-out ${i * 0.2}s infinite`,
            }}
          />
        ))}
      </div>
      <div style={{ textAlign: 'center' }}>
        <p style={{
          fontFamily: "'JetBrains Mono', monospace",
          fontSize: '13px',
          color: 'var(--accent-gl3)',
          marginBottom: '6px',
        }}>
          schedule/3 · backtracking…
        </p>
        <p style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
          Recherche de solutions faisables en cours (max ~25s cote serveur)
        </p>
      </div>
      <style>{`
        @keyframes pulse-dot {
          0%, 80%, 100% { transform: scale(0.6); opacity: 0.4; }
          40% { transform: scale(1); opacity: 1; }
        }
      `}</style>
    </div>
  );
}

function NoSolutionState({ level }: { level: Level }) {
  return (
    <div style={{
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: '16px',
    }}>
      <div style={{
        width: 48, height: 48, borderRadius: '12px',
        background: 'rgba(177,75,82,0.14)',
        border: '1px solid rgba(177,75,82,0.32)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: '22px',
      }}>
        ✕
      </div>
      <div style={{ textAlign: 'center' }}>
        <p style={{ fontSize: '14px', fontWeight: 600, color: '#b14b52', marginBottom: '6px' }}>
          Aucune solution trouvée
        </p>
        <p style={{ fontSize: '12px', color: 'var(--text-muted)', maxWidth: '280px', lineHeight: 1.6 }}>
          Le moteur n'a pas pu satisfaire toutes les contraintes pour {level.toUpperCase()}.
          Essayez de réduire le nombre de matières sélectionnées.
        </p>
      </div>
    </div>
  );
}

function BackendErrorState({ message }: { message: string | null }) {
  return (
    <div style={{
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: '16px',
    }}>
      <div style={{
        width: 48, height: 48, borderRadius: '12px',
        background: 'rgba(143,43,46,0.14)',
        border: '1px solid rgba(143,43,46,0.32)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: '20px',
      }}>
        !
      </div>
      <div style={{ textAlign: 'center' }}>
        <p style={{ fontSize: '14px', fontWeight: 600, color: 'var(--accent-gl3)', marginBottom: '6px' }}>
          Serveur Prolog indisponible ou occupe
        </p>
        <p style={{ fontSize: '12px', color: 'var(--text-muted)', maxWidth: '420px', lineHeight: 1.6 }}>
          {message ?? "La génération n'a pas pu contacter l'API /api/schedule. Démarrez SWI-Prolog puis relancez la génération."}
        </p>
      </div>
    </div>
  );
}

interface ResultsPanelProps {
  candidates: ScheduleCandidate[];
  level: Level;
  resultMode: ResultMode | null;
  selectedRank: number | null;
  selectedExploreIndex: number;
  optimizationExplanation: string | null;
  evaluatedCandidates: number;
  engineSource: import('../scheduler/api').EngineSource | null;
  onSelectRank: (rank: number) => void;
  onOptimize: () => void;
  onExplorePrev: () => void;
  onExploreNext: () => void;
  onConfirm: () => void;
}

function ResultsPanel({
  candidates,
  level,
  resultMode,
  selectedRank,
  selectedExploreIndex,
  optimizationExplanation,
  evaluatedCandidates,
  engineSource,
  onSelectRank,
  onOptimize,
  onExplorePrev,
  onExploreNext,
  onConfirm,
}: ResultsPanelProps) {
  const accent = LEVEL_ACCENTS[level];
  const top3 = candidates.slice(0, 3);
  const currentExplore = candidates[selectedExploreIndex] ?? candidates[0];
  const currentOptimized = selectedRank !== null
    ? (candidates.find(c => c.rank === selectedRank) ?? candidates[0])
    : candidates[0];
  const activeCandidate = resultMode === 'explore' ? currentExplore : currentOptimized;
  const isProlog = engineSource === 'prolog';

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '4px' }}>
            <h2 style={{ fontSize: '17px', fontWeight: 700 }}>
              Emplois du temps générés
            </h2>
            {engineSource && (
              <span style={{
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: '9px',
                fontWeight: 700,
                letterSpacing: '0.06em',
                padding: '2px 8px',
                borderRadius: '4px',
                background: isProlog ? 'rgba(47,125,99,0.12)' : 'rgba(143,43,46,0.12)',
                color: isProlog ? 'var(--green)' : 'var(--accent-gl3)',
                border: `1px solid ${isProlog ? 'rgba(47,125,99,0.3)' : 'rgba(143,43,46,0.3)'}`,
              }}>
                {isProlog ? 'SWI-PROLOG' : 'TYPESCRIPT'}
              </span>
            )}
          </div>
          <p style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
            {resultMode === 'optimize'
              ? `${candidates.length} solutions optimisees (top 10)`
              : `${candidates.length} solutions faisables — navigation pas a pas`
            }
          </p>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          {resultMode === 'explore' && (
            <button
              onClick={onOptimize}
              style={{
                padding: '10px 14px',
                borderRadius: '10px',
                fontSize: '12px',
                fontWeight: 700,
                border: `1px solid ${accent}55`,
                background: 'var(--bg-card)',
                color: accent,
                cursor: 'pointer',
              }}
            >
              Filtrer (optimiser)
            </button>
          )}
          {activeCandidate && (
            <button
              onClick={onConfirm}
              style={{
                padding: '10px 20px',
                borderRadius: '10px',
                fontSize: '13.5px',
                fontWeight: 700,
                background: `linear-gradient(135deg, ${accent}, ${accent}bb)`,
                color: 'var(--bg-base)',
                border: 'none',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
              }}
            >
              ✓ Confirmer #{activeCandidate.rank}
            </button>
          )}
        </div>
      </div>

      {resultMode === 'explore' && activeCandidate && (
        <>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '8px 2px 0',
          }}>
            <button
              onClick={onExplorePrev}
              style={{
                padding: '7px 12px',
                borderRadius: '8px',
                border: '1px solid var(--border-1)',
                background: 'var(--bg-card)',
                color: 'var(--text-muted-2)',
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: '11px',
                cursor: 'pointer',
              }}
            >
              ← Precedent
            </button>
            <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
              Solution {selectedExploreIndex + 1} / {candidates.length}
            </span>
            <button
              onClick={onExploreNext}
              style={{
                padding: '7px 12px',
                borderRadius: '8px',
                border: '1px solid var(--border-1)',
                background: 'var(--bg-card)',
                color: 'var(--text-muted-2)',
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: '11px',
                cursor: 'pointer',
              }}
            >
              Suivant →
            </button>
          </div>

          <SolutionCard
            key={activeCandidate.rank}
            candidate={activeCandidate}
            level={level}
            isSelected
            onSelect={() => undefined}
          />
        </>
      )}

      {resultMode === 'optimize' && (
        <>
          {top3.map(c => (
            <SolutionCard
              key={c.rank}
              candidate={c}
              level={level}
              isSelected={selectedRank === c.rank}
              onSelect={() => onSelectRank(c.rank)}
            />
          ))}

          <OptimizationReport
            candidates={candidates}
            level={level}
            selectedRank={selectedRank ?? 1}
            explanation={optimizationExplanation ?? undefined}
            evaluatedCandidates={evaluatedCandidates}
          />
        </>
      )}
    </div>
  );
}


