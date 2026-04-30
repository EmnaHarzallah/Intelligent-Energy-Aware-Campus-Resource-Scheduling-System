import React from 'react';
import type { Assignment, Level } from '../types';
import { DAYS, TIMESLOTS, COURSES_BY_LEVEL, COURSE_PALETTE } from '../data/courses';

interface ScheduleGridProps {
  assignments: Assignment[];
  group: string;  // e.g. "gl3_1" — used to filter relevant sessions
  level: Level;
  compact?: boolean;
}

function getCourseColor(courseId: string, level: Level): string {
  const courses = COURSES_BY_LEVEL[level];
  const idx = courses.findIndex(c => c.id === courseId);
  return COURSE_PALETTE[idx >= 0 ? idx % COURSE_PALETTE.length : 0];
}

function hexToRgba(hex: string, alpha: number): string {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

export default function ScheduleGrid({ assignments, group, level, compact = false }: ScheduleGridProps) {
  const cellHeight = compact ? 56 : 72;

  // Filter: cours sessions (group='level') visible for all groups of this level
  //         td/tp sessions only for their specific group
  const relevantAssignments = assignments.filter(a => {
    const g = a.session.group;
    return g === 'level' || g === group;
  });

  function getCell(day: string, slot: number): Assignment | undefined {
    return relevantAssignments.find(a => a.day === day && a.slot === slot);
  }

  return (
    <div style={{ overflowX: 'auto' }}>
      <table
        role="grid"
        aria-label={`Emploi du temps ${group}`}
        style={{
          width: '100%',
          borderCollapse: 'separate',
          borderSpacing: '3px',
          tableLayout: 'fixed',
          minWidth: '420px',
        }}
      >
        <thead>
          <tr>
            <th
              scope="col"
              style={{
                width: compact ? '44px' : '52px',
                padding: '4px 2px',
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: '10px',
                color: '#3a4055',
                fontWeight: 500,
                textAlign: 'center',
              }}
            >
              <span aria-hidden="true">—</span>
              <span className="sr-only">Heure</span>
            </th>
            {DAYS.map(d => (
              <th key={d.id} scope="col" style={{
                padding: '4px 4px',
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: '10px',
                fontWeight: 600,
                color: '#4a5268',
                textAlign: 'center',
                letterSpacing: '0.04em',
              }}>
                {d.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {TIMESLOTS.map(ts => (
            <tr key={ts.slot}>
              <th
                scope="row"
                style={{
                  padding: '2px 4px',
                  fontFamily: "'JetBrains Mono', monospace",
                  fontSize: '9.5px',
                  color: '#3a4055',
                  textAlign: 'right',
                  verticalAlign: 'middle',
                  fontWeight: 500,
                  whiteSpace: 'nowrap',
                }}
              >
                {ts.label}
              </th>
              {DAYS.map(d => {
                const cell = getCell(d.id, ts.slot);
                if (!cell) {
                  return (
                    <td key={d.id} style={{
                      height: `${cellHeight}px`,
                      background: 'rgba(255,255,255,0.015)',
                      borderRadius: '5px',
                      border: '1px solid #1a1e2a',
                    }} />
                  );
                }

                const color = getCourseColor(cell.session.courseId, level);
                const bg = hexToRgba(color, 0.09);
                const kindBadgeColor = cell.session.kind === 'cours'
                  ? hexToRgba(color, 0.3)
                  : hexToRgba(color, 0.2);

                return (
                  <td key={d.id} style={{
                    height: `${cellHeight}px`,
                    background: bg,
                    borderRadius: '7px',
                    borderLeft: `3px solid ${color}`,
                    border: `1px solid ${hexToRgba(color, 0.18)}`,
                    borderLeftWidth: '3px',
                    borderLeftColor: color,
                    padding: compact ? '5px 6px' : '7px 8px',
                    verticalAlign: 'top',
                    overflow: 'hidden',
                  }}>
                    <div style={{
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '2px',
                      height: '100%',
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                        <span style={{
                          fontFamily: "'JetBrains Mono', monospace",
                          fontSize: '8px',
                          fontWeight: 600,
                          color: color,
                          background: kindBadgeColor,
                          padding: '1px 4px',
                          borderRadius: '3px',
                          textTransform: 'uppercase',
                          letterSpacing: '0.06em',
                          flexShrink: 0,
                        }}>
                          {cell.session.kind}
                        </span>
                      </div>
                      <div style={{
                        fontWeight: 600,
                        fontSize: compact ? '10.5px' : '11px',
                        color: color,
                        lineHeight: 1.2,
                        overflow: 'hidden',
                        display: '-webkit-box',
                        WebkitLineClamp: compact ? 1 : 2,
                        WebkitBoxOrient: 'vertical',
                      }}>
                        {cell.session.courseLabel}
                      </div>
                      {!compact && (
                        <div style={{
                          fontSize: '9.5px',
                          color: '#4a5268',
                          lineHeight: 1.2,
                          overflow: 'hidden',
                          whiteSpace: 'nowrap',
                          textOverflow: 'ellipsis',
                        }}>
                          {cell.session.instructor}
                        </div>
                      )}
                      <div style={{
                        fontFamily: "'JetBrains Mono', monospace",
                        fontSize: '9px',
                        color: '#3a4055',
                        marginTop: 'auto',
                      }}>
                        {cell.roomId}
                      </div>
                    </div>
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
