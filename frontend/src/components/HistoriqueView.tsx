import React, { useState } from 'react';
import type { ConfirmedSchedule } from '../types';
import { LEVEL_ACCENTS, LEVEL_GROUPS } from '../data/courses';
import ScheduleGrid from './ScheduleGrid';

interface HistoriqueViewProps {
  confirmedSchedules: ConfirmedSchedule[];
}

export default function HistoriqueView({ confirmedSchedules }: HistoriqueViewProps) {
  if (confirmedSchedules.length === 0) {
    return (
      <div style={{
        height: 'calc(100vh - 60px)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '16px',
        opacity: 0.55,
      }}>
        <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
          <rect x="6" y="6" width="60" height="60" rx="12" fill="#141720" stroke="#1e2335" strokeWidth="1.5"/>
          <circle cx="36" cy="36" r="14" stroke="#252a3a" strokeWidth="1.5" fill="none"/>
          <path d="M36 28v8l5 5" stroke="#3a4055" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        <div style={{ textAlign: 'center' }}>
          <p style={{ fontSize: '15px', fontWeight: 600, color: '#dde1ed', marginBottom: '6px' }}>
            Aucun emploi confirmé
          </p>
          <p style={{ fontSize: '13px', color: '#4a5268' }}>
            Les emplois du temps confirmés apparaîtront ici.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: '24px', maxWidth: '1100px', margin: '0 auto' }}>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '4px' }}>Historique</h1>
        <p style={{ fontSize: '13px', color: '#4a5268' }}>
          {confirmedSchedules.length} emploi{confirmedSchedules.length > 1 ? 's' : ''} confirmé{confirmedSchedules.length > 1 ? 's' : ''}
        </p>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {[...confirmedSchedules].reverse().map((schedule, revIdx) => (
          <HistoriqueCard
            key={schedule.id}
            schedule={schedule}
            index={confirmedSchedules.length - revIdx}
          />
        ))}
      </div>
    </div>
  );
}

function HistoriqueCard({ schedule, index }: { schedule: ConfirmedSchedule; index: number }) {
  const [expandedGroup, setExpandedGroup] = useState<string | null>(null);
  const accent = LEVEL_ACCENTS[schedule.level];
  const groups = LEVEL_GROUPS[schedule.level];

  const ts = schedule.confirmedAt;
  const dateStr = ts.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' });
  const timeStr = ts.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });

  return (
    <div style={{
      background: '#141720',
      borderRadius: '14px',
      border: '1px solid #1e2335',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '16px 20px',
        borderBottom: expandedGroup ? '1px solid #1a1e2a' : 'none',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {/* Index badge */}
          <div style={{
            width: 32, height: 32, borderRadius: '9px',
            background: '#1a1e2a',
            border: '1px solid #252a3a',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: "'JetBrains Mono', monospace",
            fontSize: '12px',
            fontWeight: 700,
            color: '#4a5268',
          }}>
            {index}
          </div>

          {/* Level pill */}
          <span style={{
            padding: '4px 12px',
            borderRadius: '20px',
            fontSize: '12px',
            fontWeight: 700,
            background: `${accent}18`,
            color: accent,
            border: `1px solid ${accent}35`,
            letterSpacing: '0.04em',
          }}>
            {schedule.level.toUpperCase()}
          </span>

          <span style={{ fontSize: '12.5px', color: '#4a5268' }}>
            {groups.length} groupe{groups.length > 1 ? 's' : ''} · {schedule.metrics.sessionCount} séances
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <span style={{
            fontFamily: "'JetBrains Mono', monospace",
            fontSize: '10.5px',
            color: '#3a4055',
          }}>
            {dateStr} {timeStr}
          </span>
          <div style={{ display: 'flex', gap: '5px' }}>
            {groups.map(g => (
              <button
                key={g}
                type="button"
                onClick={() => setExpandedGroup(prev => prev === g ? null : g)}
                aria-pressed={expandedGroup === g}
                aria-label={`Voir emploi du temps ${g.toUpperCase()}`}
                style={{
                  padding: '5px 10px',
                  minHeight: '36px',
                  borderRadius: '6px',
                  fontSize: '11px',
                  fontWeight: 600,
                  background: expandedGroup === g ? `${accent}20` : '#1a1e2a',
                  color: expandedGroup === g ? accent : '#8892aa',
                  border: expandedGroup === g ? `1px solid ${accent}45` : '1px solid #252a3a',
                  transition: 'all 0.12s ease',
                  fontFamily: "'JetBrains Mono', monospace",
                  cursor: 'pointer',
                }}
              >
                {g.toUpperCase()}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Group grid */}
      {expandedGroup && (
        <div style={{ padding: '16px 20px' }}>
          <div style={{ marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{
              fontFamily: "'JetBrains Mono', monospace",
              fontSize: '10px',
              fontWeight: 600,
              color: accent,
              background: `${accent}15`,
              padding: '2px 8px',
              borderRadius: '4px',
            }}>
              {expandedGroup.toUpperCase()}
            </span>
            <span style={{ fontSize: '11px', color: '#3a4055' }}>
              Emploi du temps — Rang #{schedule.rank} · E={schedule.metrics.eTotal} · Imb={schedule.metrics.imbalance}
            </span>
          </div>
          <ScheduleGrid
            assignments={schedule.assignments}
            group={expandedGroup}
            level={schedule.level}
            compact={false}
          />
        </div>
      )}
    </div>
  );
}
