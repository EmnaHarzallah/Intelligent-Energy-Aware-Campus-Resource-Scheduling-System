import React, { useEffect, useState } from 'react';
import type { ScheduleCandidate, Level } from '../types';
import { LEVEL_ACCENTS, LEVEL_GROUPS } from '../data/courses';
import ScheduleGrid from './ScheduleGrid';

interface SolutionCardProps {
  candidate: ScheduleCandidate;
  level: Level;
  isSelected: boolean;
  onSelect: () => void;
}

export default function SolutionCard({ candidate, level, isSelected, onSelect }: SolutionCardProps) {
  const accent = LEVEL_ACCENTS[level];
  const groups = LEVEL_GROUPS[level];
  const [expandedGroup, setExpandedGroup] = useState<string | null>(groups[0] ?? null);
  const isBest = candidate.rank === 1;

  useEffect(() => {
    if (isSelected && !expandedGroup) {
      setExpandedGroup(groups[0] ?? null);
    }
  }, [expandedGroup, groups, isSelected]);

  return (
    <div
      onClick={onSelect}
      style={{
        background: 'var(--bg-card)',
        borderRadius: '14px',
        border: isSelected
          ? `1.5px solid ${accent}`
          : isBest
            ? `1px solid ${accent}50`
            : '1px solid var(--border-1)',
        cursor: 'pointer',
        transition: 'all 0.18s ease',
        overflow: 'hidden',
        boxShadow: isSelected ? `0 0 0 2px ${accent}25, 0 4px 24px rgba(143, 43, 46, 0.12)` : 'none',
      }}
    >
      {/* Header */}
      <div style={{
        padding: '14px 18px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        borderBottom: '1px solid var(--bg-card-2)',
        background: isBest ? `${accent}08` : 'transparent',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {/* Rank badge */}
          <div style={{
            width: 28, height: 28,
            borderRadius: '8px',
            background: isBest ? accent : 'var(--bg-card-2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: "'JetBrains Mono', monospace",
            fontSize: '12px',
            fontWeight: 700,
            color: isBest ? 'var(--bg-base)' : 'var(--text-muted)',
            border: isBest ? 'none' : '1px solid var(--border-2)',
          }}>
            #{candidate.rank}
          </div>
          {isBest && (
            <span style={{
              fontSize: '10px',
              fontWeight: 600,
              color: accent,
              background: `${accent}18`,
              padding: '2px 8px',
              borderRadius: '4px',
              border: `1px solid ${accent}30`,
            }}>
              OPTIMAL
            </span>
          )}
          {isSelected && (
            <span style={{
              fontSize: '10px',
              fontWeight: 600,
              color: 'var(--green)',
              background: 'rgba(47,125,99,0.14)',
              padding: '2px 8px',
              borderRadius: '4px',
            }}>
              ✓ SÉLECTIONNÉ
            </span>
          )}
        </div>

        {/* Metrics */}
        <div style={{ display: 'flex', gap: '16px' }}>
          {[
            { label: 'E', value: candidate.metrics.eTotal, unit: 'kWh' },
            { label: 'Imb', value: candidate.metrics.imbalance },
            { label: 'Fair', value: candidate.metrics.fairness },
          ].map(m => (
            <div key={m.label} style={{ textAlign: 'right' }}>
              <div style={{
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: '13px',
                fontWeight: 600,
                color: isBest && m.label === 'E' ? 'var(--green)' : 'var(--text-primary)',
              }}>
                {m.value}{m.unit ? <span style={{ fontSize: '9px', color: 'var(--text-muted)', marginLeft: '2px' }}>{m.unit}</span> : ''}
              </div>
              <div style={{
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: '9px',
                color: 'var(--text-faint)',
                letterSpacing: '0.04em',
              }}>
                {m.label}
              </div>
            </div>
          ))}
          <div style={{ textAlign: 'right' }}>
            <div style={{
              fontFamily: "'JetBrains Mono', monospace",
              fontSize: '13px',
              fontWeight: 600,
              color: 'var(--text-primary)',
            }}>
              {candidate.metrics.sessionCount}
            </div>
            <div style={{
              fontFamily: "'JetBrains Mono', monospace",
              fontSize: '9px',
              color: 'var(--text-faint)',
              letterSpacing: '0.04em',
            }}>
              séances
            </div>
          </div>
        </div>
      </div>

      {/* Group tabs + grid */}
      <div style={{ padding: '14px 18px' }} onClick={e => e.stopPropagation()}>
        {/* Group selector */}
        {isSelected ? (
          <>
            <div style={{ display: 'flex', gap: '6px', marginBottom: '12px', flexWrap: 'wrap' }}>
              {groups.map(g => (
                <button
                  key={g}
                  type="button"
                  onClick={() => setExpandedGroup(prev => prev === g ? null : g)}
                  aria-pressed={expandedGroup === g}
                  aria-label={`Voir emploi du temps ${g.toUpperCase()}`}
                  style={{
                    padding: '5px 12px',
                    minHeight: '36px',
                    borderRadius: '6px',
                    fontSize: '11.5px',
                    fontWeight: 600,
                    background: expandedGroup === g ? `${accent}20` : 'var(--bg-card-2)',
                    color: expandedGroup === g ? accent : 'var(--text-muted-2)',
                    border: expandedGroup === g ? `1px solid ${accent}50` : '1px solid var(--border-2)',
                    transition: 'all 0.12s ease',
                    fontFamily: "'JetBrains Mono', monospace",
                    cursor: 'pointer',
                  }}
                >
                  {g.toUpperCase()}
                </button>
              ))}
            </div>

            {expandedGroup && (
              <div style={{
                background: 'var(--bg-base)',
                border: '1px solid var(--border-1)',
                borderRadius: '10px',
                padding: '8px',
              }}>
                <ScheduleGrid
                  assignments={candidate.assignments}
                  group={expandedGroup}
                  level={level}
                  compact={false}
                />
              </div>
            )}
          </>
        ) : (
          <div style={{
            padding: '10px 12px',
            borderRadius: '8px',
            background: 'var(--bg-base)',
            border: '1px solid var(--border-1)',
            fontSize: '12px',
            color: 'var(--text-muted)',
          }}>
            Sélectionner cette solution pour afficher la planification en grand format.
          </div>
        )}
      </div>
    </div>
  );
}


