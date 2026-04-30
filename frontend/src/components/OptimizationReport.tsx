import React, { useState } from 'react';
import type { ScheduleCandidate, Level } from '../types';
import { LEVEL_ACCENTS } from '../data/courses';

interface OptimizationReportProps {
  candidates: ScheduleCandidate[];
  level: Level;
  selectedRank: number;
}

export default function OptimizationReport({ candidates, level, selectedRank }: OptimizationReportProps) {
  const [expanded, setExpanded] = useState(false);
  const accent = LEVEL_ACCENTS[level];
  const best = candidates[0];

  const explanation = best
    ? `Solution #${best.rank} sélectionnée par ordre lexicographique : E_total=${best.metrics.eTotal} (minimal parmi ${candidates.length} candidats), Imbalance=${best.metrics.imbalance}, Fairness=${best.metrics.fairness}.`
    : '';

  return (
    <div style={{
      background: '#141720',
      borderRadius: '12px',
      border: '1px solid #1e2335',
      overflow: 'hidden',
    }}>
      <button
        type="button"
        onClick={() => setExpanded(e => !e)}
        aria-expanded={expanded}
        aria-controls="optimization-report-content"
        style={{
          width: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '14px 18px',
          minHeight: '48px',
          background: 'transparent',
          color: '#dde1ed',
          fontSize: '13px',
          fontWeight: 600,
          cursor: 'pointer',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span style={{
            fontFamily: "'JetBrains Mono', monospace",
            fontSize: '10px',
            color: accent,
            background: `${accent}18`,
            padding: '2px 8px',
            borderRadius: '4px',
            border: `1px solid ${accent}30`,
          }}>
            OPTIMISATION
          </span>
          <span style={{ color: '#4a5268', fontSize: '12px', fontWeight: 400 }}>
            {candidates.length} candidats analysés
          </span>
        </div>
        <span style={{ color: '#4a5268', fontSize: '16px', transition: 'transform 0.2s', display: 'inline-block', transform: expanded ? 'rotate(180deg)' : 'none' }}>
          ▾
        </span>
      </button>

      {expanded && (
        <div id="optimization-report-content" style={{ padding: '0 18px 18px' }}>
          {/* Explanation */}
          <div style={{
            padding: '10px 14px',
            background: `${accent}0d`,
            borderRadius: '8px',
            border: `1px solid ${accent}25`,
            marginBottom: '14px',
          }}>
            <p style={{ fontSize: '12px', color: '#dde1ed', lineHeight: 1.6 }}>
              {explanation}
            </p>
          </div>

          {/* Table */}
          <div style={{ overflowX: 'auto' }}>
            <table aria-label="Rapport d'optimisation" style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr>
                  {['Rang', 'E_total', 'Déséquilibre', 'Équité', 'Séances'].map(col => (
                    <th key={col} scope="col" style={{
                      padding: '8px 12px',
                      textAlign: 'left',
                      fontSize: '10.5px',
                      fontWeight: 600,
                      color: '#4a5268',
                      fontFamily: "'JetBrains Mono', monospace",
                      letterSpacing: '0.04em',
                      borderBottom: '1px solid #1e2335',
                    }}>
                      {col}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {candidates.map(c => {
                  const isSelected = c.rank === selectedRank;
                  const isBest = c.rank === 1;
                  return (
                    <tr key={c.rank} style={{
                      background: isBest ? `${accent}10` : 'transparent',
                      borderBottom: '1px solid #1a1e2a',
                    }}>
                      <td style={{ padding: '9px 12px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <span style={{
                            fontFamily: "'JetBrains Mono', monospace",
                            fontSize: '11px',
                            fontWeight: 700,
                            color: isBest ? accent : '#4a5268',
                          }}>
                            #{c.rank}
                          </span>
                          {isSelected && (
                            <span style={{
                              fontSize: '9px',
                              color: accent,
                              background: `${accent}20`,
                              padding: '1px 5px',
                              borderRadius: '3px',
                              fontWeight: 600,
                            }}>
                              choisi
                            </span>
                          )}
                        </div>
                      </td>
                      <td style={{ padding: '9px 12px', fontFamily: "'JetBrains Mono', monospace", fontSize: '12px', color: isBest ? '#34d399' : '#dde1ed' }}>
                        {c.metrics.eTotal}
                      </td>
                      <td style={{ padding: '9px 12px', fontFamily: "'JetBrains Mono', monospace", fontSize: '12px', color: '#dde1ed' }}>
                        {c.metrics.imbalance}
                      </td>
                      <td style={{ padding: '9px 12px', fontFamily: "'JetBrains Mono', monospace", fontSize: '12px', color: '#dde1ed' }}>
                        {c.metrics.fairness}
                      </td>
                      <td style={{ padding: '9px 12px', fontFamily: "'JetBrains Mono', monospace", fontSize: '12px', color: '#dde1ed' }}>
                        {c.metrics.sessionCount}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
