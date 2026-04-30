import React, { useState } from 'react';
import type { Level, Course } from '../types';
import { LEVEL_ACCENTS, COURSE_PALETTE, COURSES_BY_LEVEL } from '../data/courses';

interface GroupCardProps {
  groupId: string;  // e.g. "gl3_1"
  level: Level;
  courses: Course[];
  selectedCourseIds: Set<string>;
  instructorOverrides: Record<string, string>;
  onToggleCourse: (courseId: string) => void;
  onInstructorChange: (courseId: string, value: string) => void;
}

export default function GroupCard({
  groupId,
  level,
  courses,
  selectedCourseIds,
  instructorOverrides,
  onToggleCourse,
  onInstructorChange,
}: GroupCardProps) {
  const [open, setOpen] = useState(true);
  const accent = LEVEL_ACCENTS[level];

  const groupNum = groupId.split('_').pop();
  const levelLabel = level.toUpperCase();

  return (
    <div style={{
      background: '#1a1e2a',
      borderRadius: '12px',
      border: '1px solid #1e2335',
      overflow: 'hidden',
    }}>
      {/* Accordion header */}
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
          color: '#dde1ed',
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
          color: '#4a5268',
          fontSize: '14px',
          transition: 'transform 0.2s',
          display: 'inline-block',
          transform: open ? 'rotate(180deg)' : 'none',
        }}>▾</span>
      </button>

      {open && (
        <div id={`group-${groupId}-content`} style={{ padding: '0 16px 16px' }}>
          {/* Course chips */}
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginBottom: '12px' }}>
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
                    minHeight: '36px',
                    borderRadius: '20px',
                    fontSize: '11.5px',
                    fontWeight: isSelected ? 600 : 400,
                    background: isSelected ? `${color}20` : '#141720',
                    color: isSelected ? color : '#8892aa',
                    border: isSelected ? `1.5px solid ${color}60` : '1px solid #252a3a',
                    transition: 'background 0.15s ease, color 0.15s ease, border-color 0.15s ease',
                    cursor: 'pointer',
                  }}
                >
                  {course.label}
                </button>
              );
            })}
          </div>

          {/* Instructor inputs for selected courses */}
          {courses
            .filter(c => selectedCourseIds.has(c.id))
            .map((course, idx) => {
              const courseIdx = courses.findIndex(c => c.id === course.id);
              const color = COURSE_PALETTE[courseIdx % COURSE_PALETTE.length];
              const instructor = instructorOverrides[course.id] ?? course.defaultInstructor;
              return (
                <div key={course.id} style={{ marginBottom: '8px' }}>
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    marginBottom: '4px',
                  }}>
                    <div style={{
                      width: 8, height: 8, borderRadius: '50%',
                      background: color, flexShrink: 0,
                    }} />
                    <label style={{
                      fontSize: '11px',
                      color: '#4a5268',
                      fontWeight: 500,
                    }}>
                      {course.label}
                    </label>
                  </div>
                  <input
                    type="text"
                    value={instructor}
                    onChange={e => onInstructorChange(course.id, e.target.value)}
                    style={{
                      width: '100%',
                      background: '#141720',
                      border: `1px solid ${color}30`,
                      borderRadius: '7px',
                      padding: '7px 11px',
                      fontSize: '12px',
                      color: '#dde1ed',
                      outline: 'none',
                      transition: 'border-color 0.15s',
                    }}
                    onFocus={e => { e.currentTarget.style.borderColor = `${color}70`; }}
                    onBlur={e => { e.currentTarget.style.borderColor = `${color}30`; }}
                    placeholder="Nom de l'enseignant"
                  />
                </div>
              );
            })}
        </div>
      )}
    </div>
  );
}
