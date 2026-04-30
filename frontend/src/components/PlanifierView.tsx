import React, { useState, useRef } from 'react';
import type { Level, ConfirmedSchedule, GlobalOccupied, ScheduleCandidate } from '../types';
import { COURSES_BY_LEVEL, LEVEL_GROUPS, LEVEL_ACCENTS } from '../data/courses';
import { generateCandidatesWithFallback, type EngineSource } from '../scheduler/api';
import GroupCard from './GroupCard';
import SolutionCard from './SolutionCard';
import OptimizationReport from './OptimizationReport';

interface PlanifierViewProps {
  globalOccupied: GlobalOccupied;
  onConfirm: (schedule: ConfirmedSchedule) => void;
}

type ViewState = 'idle' | 'loading' | 'results' | 'no-solution';

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

  const [viewState, setViewState] = useState<ViewState>('idle');
  const [candidates, setCandidates] = useState<ScheduleCandidate[]>([]);
  const [selectedRank, setSelectedRank] = useState<number | null>(null);
  const [engineSource, setEngineSource] = useState<EngineSource | null>(null);
  const abortRef = useRef<AbortController | null>(null);

  const currentCourses = COURSES_BY_LEVEL[activeLevel];
  const currentGroups = LEVEL_GROUPS[activeLevel];
  const accent = LEVEL_ACCENTS[activeLevel];

  // Nombre total de matières sélectionnées pour le niveau actif (union de tous les groupes)
  const totalSelectedForLevel = currentGroups.reduce(
    (acc, g) => acc + selectedCourseIds[g].size, 0
  );

  function toggleCourse(groupId: string, courseId: string) {
    setSelectedCourseIds(prev => {
      const updated = new Set(prev[groupId]);
      if (updated.has(courseId)) updated.delete(courseId);
      else updated.add(courseId);
      return { ...prev, [groupId]: updated };
    });
    // Reset results when selection changes
    setViewState('idle');
    setCandidates([]);
    setSelectedRank(null);
  }

  function setInstructor(groupId: string, courseId: string, value: string) {
    setInstructorOverrides(prev => ({
      ...prev,
      [groupId]: { ...prev[groupId], [courseId]: value },
    }));
  }

  async function handleGenerate() {
    if (totalSelectedForLevel === 0) return;

    // Cancel any in-flight request
    abortRef.current?.abort();
    abortRef.current = new AbortController();

    setViewState('loading');
    setCandidates([]);
    setSelectedRank(null);
    setEngineSource(null);

    // Agréger toutes les matières sélectionnées (union) + overrides pour ce niveau
    const allSelectedIds = new Set<string>();
    const overrides: Record<string, string> = {};

    for (const groupId of currentGroups) {
      for (const courseId of selectedCourseIds[groupId]) {
        allSelectedIds.add(courseId);
        const course = currentCourses.find(c => c.id === courseId);
        overrides[courseId] = instructorOverrides[groupId][courseId] ?? course?.defaultInstructor ?? '';
      }
    }

    const { candidates: result, source } = await generateCandidatesWithFallback({
      level: activeLevel,
      selectedCourseIds: Array.from(allSelectedIds),
      instructorOverrides: overrides,
      globalOccupied,
    });

    if (result.length === 0) {
      setViewState('no-solution');
    } else {
      setCandidates(result);
      setEngineSource(source);
      setViewState('results');
    }
  }

  function handleLevelChange(level: Level) {
    setActiveLevel(level);
    setViewState('idle');
    setCandidates([]);
    setSelectedRank(null);
  }

  function handleConfirm() {
    if (selectedRank === null) return;
    const candidate = candidates.find(c => c.rank === selectedRank);
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
        width: '390px',
        flexShrink: 0,
        borderRight: '1px solid #1a1e2a',
        display: 'flex',
        flexDirection: 'column',
        overflowY: 'auto',
        background: '#0f1118',
      }}>
        {/* Level tabs */}
        <div style={{
          display: 'flex',
          gap: '4px',
          padding: '16px 16px 0',
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
                  background: isActive ? `${levelAccent}18` : '#141720',
                  color: isActive ? levelAccent : '#8892aa',
                  border: isActive ? `1.5px solid ${levelAccent}50` : '1px solid #1e2335',
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
        <div style={{ padding: '12px 16px', flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {currentGroups.map(g => (
            <GroupCard
              key={g}
              groupId={g}
              level={activeLevel}
              courses={currentCourses}
              selectedCourseIds={selectedCourseIds[g]}
              instructorOverrides={instructorOverrides[g]}
              onToggleCourse={(courseId) => toggleCourse(g, courseId)}
              onInstructorChange={(courseId, value) => setInstructor(g, courseId, value)}
            />
          ))}
        </div>

        {/* Generate button */}
        <div style={{ padding: '12px 16px', borderTop: '1px solid #1a1e2a' }}>
          <button
            onClick={handleGenerate}
            disabled={totalSelectedForLevel === 0 || viewState === 'loading'}
            style={{
              width: '100%',
              padding: '13px',
              borderRadius: '11px',
              fontSize: '13.5px',
              fontWeight: 700,
              letterSpacing: '-0.01em',
              background: totalSelectedForLevel > 0
                ? `linear-gradient(135deg, ${accent}, ${accent}aa)`
                : '#1a1e2a',
              color: totalSelectedForLevel > 0 ? '#0b0d12' : '#3a4055',
              border: totalSelectedForLevel > 0 ? 'none' : '1px solid #252a3a',
              cursor: totalSelectedForLevel > 0 ? 'pointer' : 'not-allowed',
              transition: 'all 0.15s ease',
              opacity: viewState === 'loading' ? 0.7 : 1,
            }}
          >
            {viewState === 'loading'
              ? 'Génération en cours...'
              : `Générer les emplois du temps ${activeLevel.toUpperCase()}`
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
          padding: '24px',
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

        {viewState === 'results' && candidates.length > 0 && (
          <ResultsPanel
            candidates={candidates}
            level={activeLevel}
            selectedRank={selectedRank}
            engineSource={engineSource}
            onSelectRank={setSelectedRank}
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
          <rect x="8" y="8" width="80" height="80" rx="16" fill="#141720" stroke="#1e2335" strokeWidth="1.5"/>
          {/* Grid lines */}
          {[24, 40, 56, 72].map(y => (
            <line key={y} x1="8" y1={y} x2="88" y2={y} stroke="#1e2335" strokeWidth="1"/>
          ))}
          {[24, 44, 64].map(x => (
            <line key={x} x1={x} y1="8" x2={x} y2="88" stroke="#1e2335" strokeWidth="1"/>
          ))}
          {/* Sample filled cells */}
          <rect x="25" y="9" width="18" height="14" rx="3" fill="#00c9b130"/>
          <rect x="45" y="25" width="18" height="14" rx="3" fill="#7c6af730"/>
          <rect x="9" y="41" width="14" height="14" rx="3" fill="#f9731630"/>
          <rect x="65" y="57" width="22" height="14" rx="3" fill="#00c9b130"/>
          {/* Center icon */}
          <circle cx="48" cy="48" r="12" fill="#1a1e2a" stroke="#252a3a" strokeWidth="1"/>
          <path d="M44 48h8M48 44v8" stroke="#4a5268" strokeWidth="1.5" strokeLinecap="round"/>
        </svg>
      </div>
      <div style={{ textAlign: 'center' }}>
        <p style={{ fontSize: '15px', fontWeight: 600, color: '#dde1ed', marginBottom: '6px' }}>
          Sélectionner des matières
        </p>
        <p style={{ fontSize: '13px', color: '#4a5268', maxWidth: '280px', lineHeight: 1.6 }}>
          Choisissez un niveau et cochez les matières à planifier, puis cliquez sur Générer.
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
              background: '#7c6af7',
              animation: `pulse-dot 1.2s ease-in-out ${i * 0.2}s infinite`,
            }}
          />
        ))}
      </div>
      <div style={{ textAlign: 'center' }}>
        <p style={{
          fontFamily: "'JetBrains Mono', monospace",
          fontSize: '13px',
          color: '#7c6af7',
          marginBottom: '6px',
        }}>
          schedule/3 · backtracking…
        </p>
        <p style={{ fontSize: '12px', color: '#4a5268' }}>
          Génération de 10 candidats en cours
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
        background: 'rgba(251,113,133,0.12)',
        border: '1px solid rgba(251,113,133,0.3)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: '22px',
      }}>
        ✕
      </div>
      <div style={{ textAlign: 'center' }}>
        <p style={{ fontSize: '14px', fontWeight: 600, color: '#fb7185', marginBottom: '6px' }}>
          Aucune solution trouvée
        </p>
        <p style={{ fontSize: '12px', color: '#4a5268', maxWidth: '280px', lineHeight: 1.6 }}>
          Le moteur n'a pas pu satisfaire toutes les contraintes pour {level.toUpperCase()}.
          Essayez de réduire le nombre de matières sélectionnées.
        </p>
      </div>
    </div>
  );
}

interface ResultsPanelProps {
  candidates: ScheduleCandidate[];
  level: Level;
  selectedRank: number | null;
  engineSource: import('../scheduler/api').EngineSource | null;
  onSelectRank: (rank: number) => void;
  onConfirm: () => void;
}

function ResultsPanel({ candidates, level, selectedRank, engineSource, onSelectRank, onConfirm }: ResultsPanelProps) {
  const accent = LEVEL_ACCENTS[level];
  const top3 = candidates.slice(0, 3);
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
                background: isProlog ? 'rgba(52,211,153,0.12)' : 'rgba(124,106,247,0.12)',
                color: isProlog ? '#34d399' : '#7c6af7',
                border: `1px solid ${isProlog ? 'rgba(52,211,153,0.3)' : 'rgba(124,106,247,0.3)'}`,
              }}>
                {isProlog ? 'SWI-PROLOG' : 'TYPESCRIPT'}
              </span>
            )}
          </div>
          <p style={{ fontSize: '12px', color: '#4a5268' }}>
            {candidates.length} solutions trouvées — sélectionnez une pour confirmer
          </p>
        </div>
        {selectedRank !== null && (
          <button
            onClick={onConfirm}
            style={{
              padding: '10px 20px',
              borderRadius: '10px',
              fontSize: '13.5px',
              fontWeight: 700,
              background: `linear-gradient(135deg, ${accent}, ${accent}bb)`,
              color: '#0b0d12',
              border: 'none',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            ✓ Confirmer #{selectedRank}
          </button>
        )}
      </div>

      {/* Top 3 solution cards */}
      {top3.map(c => (
        <SolutionCard
          key={c.rank}
          candidate={c}
          level={level}
          isSelected={selectedRank === c.rank}
          onSelect={() => onSelectRank(c.rank)}
        />
      ))}

      {/* Optimization report */}
      <OptimizationReport
        candidates={candidates}
        level={level}
        selectedRank={selectedRank ?? 1}
      />
    </div>
  );
}
