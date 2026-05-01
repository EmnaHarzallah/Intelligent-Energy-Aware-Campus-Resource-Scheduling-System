import React, { useState } from 'react';
import type { Course, Level, SessionCountConfig, SessionKind } from '../types';
import { COURSE_PALETTE, LEVEL_ACCENTS } from '../data/courses';

interface GroupCardProps {
  groupId: string;  // e.g. "gl3_1"
  level: Level;
  courses: Course[];
  selectedCourseIds: Set<string>;
  instructorOverrides: Record<string, string>;
  instructorOptionsByCourse: Record<string, string[]>;
  sessionCountsByCourse: Record<string, SessionCountConfig>;
  occurrenceBySession?: Record<string, number> | null;
  occurrenceLabel?: string | null;
  onToggleCourse: (courseId: string) => void;
  onInstructorChange: (courseId: string, value: string) => void;
  onSessionCountChange: (courseId: string, kind: SessionKind, count: number) => void;
}

const SESSION_KINDS: SessionKind[] = ['cours', 'td', 'tp'];

function supportsKind(course: Course, kind: SessionKind): boolean {
  if (kind === 'cours') return course.hasCours;
  if (kind === 'td') return course.hasTd;
  return course.hasTp;
}

function getKindColor(kind: SessionKind): string {
  if (kind === 'cours') return 'var(--green)';
  if (kind === 'td') return 'var(--text-muted-2)';
  return '#f59e0b';
}

export default function GroupCard({
  groupId,
  level,
  courses,
  selectedCourseIds,
  instructorOverrides,
  instructorOptionsByCourse,
  sessionCountsByCourse,
  occurrenceBySession,
  occurrenceLabel,
  onToggleCourse,
  onInstructorChange,
  onSessionCountChange,
}: GroupCardProps) {
  const [open, setOpen] = useState(true);
  const [showInstructors, setShowInstructors] = useState(false);
  const accent = LEVEL_ACCENTS[level];

  const groupNum = groupId.split('_').pop();
  const levelLabel = level.toUpperCase();
  const selectedCourses = courses.filter(c => selectedCourseIds.has(c.id));

  return (
    <div style={{
      background: 'var(--bg-card-2)',
      borderRadius: '12px',
      border: '1px solid var(--border-1)',
      overflow: 'hidden',
    }}>
      <button
        type="button"
        onClick={() => setOpen(o => !o)}
        aria-expanded={open}
        aria-controls={`group-${groupId}-content`}
        style={{
          width: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '12px 16px',
          minHeight: '48px',
          background: 'transparent',
          color: 'var(--text-primary)',
          fontSize: '13px',
          fontWeight: 600,
          cursor: 'pointer',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div style={{
            width: 24, height: 24, borderRadius: '6px',
            background: `${accent}20`,
            border: `1px solid ${accent}40`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <span style={{
              fontFamily: "'JetBrains Mono', monospace",
              fontSize: '9px',
              fontWeight: 700,
              color: accent,
            }}>
              {groupNum}
            </span>
          </div>
          <span>{levelLabel} Groupe {groupNum}</span>
          {selectedCourseIds.size > 0 && (
            <span style={{
              fontSize: '10px',
              color: accent,
              background: `${accent}15`,
              padding: '1px 7px',
              borderRadius: '4px',
              fontWeight: 600,
            }}>
              {selectedCourseIds.size}/{courses.length}
            </span>
          )}
        </div>
        <span style={{
          color: 'var(--text-muted)',
          fontSize: '14px',
          transition: 'transform 0.2s',
          display: 'inline-block',
          transform: open ? 'rotate(180deg)' : 'none',
        }}>▾</span>
      </button>

      {open && (
        <div id={`group-${groupId}-content`} style={{ padding: '0 18px 18px' }}>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: '12px' }}>
            {courses.map((course, idx) => {
              const isSelected = selectedCourseIds.has(course.id);
              const color = COURSE_PALETTE[idx % COURSE_PALETTE.length];
              return (
                <button
                  key={course.id}
                  type="button"
                  onClick={() => onToggleCourse(course.id)}
                  aria-pressed={isSelected}
                  aria-label={`${isSelected ? 'Désélectionner' : 'Sélectionner'} ${course.label}`}
                  style={{
                    padding: '7px 13px',
                    minHeight: '38px',
                    borderRadius: '19px',
                    fontSize: '12px',
                    fontWeight: isSelected ? 600 : 400,
                    background: isSelected ? `${color}1f` : 'var(--bg-card)',
                    color: isSelected ? color : 'var(--text-muted-2)',
                    border: isSelected ? `1px solid ${color}66` : '1px solid var(--border-2)',
                    cursor: 'pointer',
                  }}
                >
                  {course.label}
                </button>
              );
            })}
          </div>

          {selectedCourses.length > 0 && (
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '10px',
            }}>
              <span style={{ fontSize: '12px', fontWeight: 600, color: 'var(--text-primary)' }}>
                Séances
              </span>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                {occurrenceLabel && (
                  <span style={{
                    fontSize: '10.5px',
                    color: 'var(--text-muted)',
                    fontFamily: "'JetBrains Mono', monospace",
                  }}>
                    {occurrenceLabel}
                  </span>
                )}
                <button
                  type="button"
                  onClick={() => setShowInstructors(v => !v)}
                  style={{
                    background: 'var(--bg-card)',
                    border: '1px solid var(--border-2)',
                    borderRadius: '6px',
                    fontSize: '11px',
                    color: 'var(--text-muted)',
                    padding: '5px 9px',
                  }}
                >
                  {showInstructors ? 'Masquer enseignants' : 'Voir enseignants'}
                </button>
              </div>
            </div>
          )}

          {selectedCourses.length > 0 && (
            <div style={{
              display: 'flex',
              flexDirection: 'column',
              gap: '8px',
              marginBottom: showInstructors ? '10px' : 0,
            }}>
              {selectedCourses.map((course) => {
                const courseIdx = courses.findIndex(c => c.id === course.id);
                const color = COURSE_PALETTE[courseIdx % COURSE_PALETTE.length];
                const counts = sessionCountsByCourse[course.id] ?? { cours: 0, td: 0, tp: 0 };

                return (
                  <div
                    key={course.id}
                    style={{
                      display: 'grid',
                      gridTemplateColumns: 'minmax(180px, 1fr) repeat(3, 88px)',
                      gap: '8px',
                      alignItems: 'center',
                      background: 'var(--bg-card)',
                      border: '1px solid var(--border-1)',
                      borderRadius: '8px',
                      padding: '9px 10px',
                    }}
                  >
                    <div style={{ minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <div style={{
                          width: 7,
                          height: 7,
                          borderRadius: '50%',
                          background: color,
                          flexShrink: 0,
                        }} />
                        <span style={{
                          fontSize: '12px',
                          color: 'var(--text-primary)',
                          whiteSpace: 'nowrap',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                        }}>
                          {course.label}
                        </span>
                      </div>
                    </div>

                    {SESSION_KINDS.map((kind) => {
                      const enabled = supportsKind(course, kind);
                      const requested = counts[kind] ?? 0;
                      const sessionKey = `${course.id}_${kind}`;
                      const occurrence = occurrenceBySession ? (occurrenceBySession[sessionKey] ?? 0) : null;

                      const occColor = occurrence === null || requested === 0
                        ? 'var(--text-muted)'
                        : occurrence === requested
                          ? 'var(--green)'
                          : '#b14b52';

                      return (
                        <div key={`${course.id}_${kind}`} style={{ display: 'flex', flexDirection: 'column', gap: '3px' }}>
                          <span style={{
                            fontSize: '10px',
                            textTransform: 'uppercase',
                            letterSpacing: '0.04em',
                            color: getKindColor(kind),
                            fontWeight: 700,
                            textAlign: 'center',
                          }}>
                            {kind}
                          </span>
                          <input
                            type="number"
                            min={0}
                            max={8}
                            step={1}
                            value={enabled ? requested : 0}
                            onChange={(e) => {
                              const raw = Number.parseInt(e.target.value, 10);
                              const next = Number.isNaN(raw) ? 0 : raw;
                              onSessionCountChange(course.id, kind, next);
                            }}
                            disabled={!enabled}
                            style={{
                              width: '100%',
                              background: enabled ? 'var(--input-bg)' : 'var(--input-bg-disabled)',
                              color: enabled ? 'var(--text-primary)' : 'var(--text-muted)',
                              border: '1px solid var(--border-2)',
                              borderRadius: '6px',
                              padding: '6px 6px',
                              fontSize: '12px',
                              fontFamily: "'JetBrains Mono', monospace",
                              textAlign: 'center',
                            }}
                          />
                          <span style={{
                            fontSize: '10px',
                            color: enabled ? occColor : 'var(--text-muted)',
                            fontFamily: "'JetBrains Mono', monospace",
                            textAlign: 'center',
                          }}>
                            {enabled ? `${occurrence === null ? '--' : occurrence}/${requested}` : '--'}
                          </span>
                        </div>
                      );
                    })}
                  </div>
                );
              })}
            </div>
          )}

          {showInstructors && selectedCourses.length > 0 && (
            <div style={{
              borderTop: '1px solid var(--border-1)',
              paddingTop: '12px',
              display: 'flex',
              flexDirection: 'column',
              gap: '8px',
            }}>
              {selectedCourses.map((course) => {
                const courseIdx = courses.findIndex(c => c.id === course.id);
                const color = COURSE_PALETTE[courseIdx % COURSE_PALETTE.length];
                const options = instructorOptionsByCourse[course.id] ?? [course.defaultInstructor];
                const uniqueOptions = Array.from(new Set(options));
                const fallbackInstructor = uniqueOptions[0] ?? course.defaultInstructor;
                const currentValue = instructorOverrides[course.id] ?? fallbackInstructor;
                const selectOptions = uniqueOptions.includes(currentValue)
                  ? uniqueOptions
                  : [currentValue, ...uniqueOptions];
                return (
                  <div key={`ins_${course.id}`} style={{ display: 'grid', gridTemplateColumns: 'minmax(160px, 1fr) 1.3fr', gap: '10px', alignItems: 'center' }}>
                    <span style={{ fontSize: '11.5px', color: 'var(--text-muted)' }}>{course.label}</span>
                    <select
                      value={currentValue}
                      onChange={(e) => onInstructorChange(course.id, e.target.value)}
                      style={{
                        width: '100%',
                        background: 'var(--input-bg)',
                        border: `1px solid ${color}35`,
                        borderRadius: '6px',
                        padding: '7px 10px',
                        fontSize: '12px',
                        color: 'var(--text-primary)',
                        outline: 'none',
                      }}
                    >
                      {selectOptions.map((name) => (
                        <option key={`${course.id}_${name}`} value={name}>
                          {name}
                        </option>
                      ))}
                    </select>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

