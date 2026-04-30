import React, { useState } from 'react';
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
  const [expandedGroup, setExpandedGroup] = useState<string | null>(null);
  const accent = LEVEL_ACCENTS[level];
  const groups = LEVEL_GROUPS[level];
  const isBest = candidate.rank === 1;

  return (
    <div
      onClick={onSelect}
      style={{
        background: '#141720',
        borderRadius: '14px',
        border: isSelected
          ? `1.5px solid ${accent}`
          : isBest
            ? `1px solid ${accent}50`
            : '1px solid #1e2335',
        cursor: 'pointer',
        transition: 'all 0.18s ease',
        overflow: 'hidden',
        boxShadow: isSelected ? `0 0 0 2px ${accent}25, 0 4px 24px rgba(0,0,0,0.3)` : 'none',
      }}
    >
      {/* Header */}
      <div style={{
        padding: '14px 18px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        borderBottom: '1px solid #1a1e2a',
        background: isBest ? `${accent}08` : 'transparent',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {/* Rank badge */}
          <div style={{
            width: 28, height: 28,
            borderRadius: '8px',
            background: isBest ? accent : '#1a1e2a',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: "'JetBrains Mono', monospace",
            fontSize: '12px',
            fontWeight: 700,
            color: isBest ? '#0b0d12' : '#4a5268',
            border: isBest ? 'none' : '1px solid #252a3a',
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
              color: '#34d399',
              background: 'rgba(52,211,153,0.15)',
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
                color: isBest && m.label === 'E' ? '#34d399' : '#dde1ed',
              }}>
                {m.value}{m.unit ? <span style={{ fontSize: '9px', color: '#4a5268', marginLeft: '2px' }}>{m.unit}</span> : ''}
              </div>
              <div style={{
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: '9px',
                color: '#3a4055',
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
              color: '#dde1ed',
            }}>
              {candidate.metrics.sessionCount}
            </div>
            <div style={{
              fontFamily: "'JetBrains Mono', monospace",
              fontSize: '9px',
              color: '#3a4055',
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
                background: expandedGroup === g ? `${accent}20` : '#1a1e2a',
                color: expandedGroup === g ? accent : '#8892aa',
                border: expandedGroup === g ? `1px solid ${accent}50` : '1px solid #252a3a',
                transition: 'all 0.12s ease',
                fontFamily: "'JetBrains Mono', monospace",
                cursor: 'pointer',
              }}
            >
              {g.toUpperCase()}
            </button>
          ))}
          {expandedGroup === null && (
            <span style={{ fontSize: '11px', color: '#3a4055', display: 'flex', alignItems: 'center', padding: '0 4px' }}>
              ← cliquer un groupe pour voir son emploi du temps
            </span>
          )}
        </div>

        {expandedGroup && (
          <ScheduleGrid
            assignments={candidate.assignments}
            group={expandedGroup}
            level={level}
            compact={true}
          />
        )}
      </div>
    </div>
  );
}
