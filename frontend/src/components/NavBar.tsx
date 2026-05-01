import React from 'react';
import insatLogo from '../assets/insat-logo.jpg';

interface NavBarProps {
  activeTab: 'planifier' | 'historique';
  onTabChange: (tab: 'planifier' | 'historique') => void;
  confirmedCount: number;
  theme: 'light' | 'dark';
  onToggleTheme: () => void;
}

export default function NavBar({ activeTab, onTabChange, confirmedCount, theme, onToggleTheme }: NavBarProps) {
  return (
    <nav
      role="navigation"
      aria-label="Navigation principale"
      style={{
        position: 'fixed',
        top: 0, left: 0, right: 0,
        height: '60px',
        backgroundColor: 'var(--bg-surface)',
        borderBottom: '1px solid var(--bg-card-2)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 24px',
        zIndex: 100,
      }}>
      {/* Left: Logo */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
        <div style={{
          width: 42, height: 42, borderRadius: '50%',
          border: '1px solid var(--border-2)',
          background: 'var(--bg-card)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          overflow: 'hidden',
          flexShrink: 0,
        }}>
          <img
            src={insatLogo}
            alt="Logo INSAT"
            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
          />
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: '7px' }}>
          <span style={{ fontWeight: 700, fontSize: '14.5px', color: 'var(--text-primary)', letterSpacing: '-0.01em' }}>
            INSAT Scheduler
          </span>
          <span style={{
            fontFamily: "'JetBrains Mono', monospace",
            fontSize: '9px',
            fontWeight: 600,
            color: 'var(--accent-gl3)',
            background: 'rgba(143,43,46,0.12)',
            padding: '1px 6px',
            borderRadius: '4px',
            border: '1px solid rgba(143,43,46,0.25)',
            letterSpacing: '0.08em',
          }}>
            PROLOG
          </span>
        </div>
      </div>

      {/* Center: Tab pills */}
      <div style={{
        display: 'flex',
        gap: '4px',
        background: 'var(--bg-base)',
        padding: '4px',
        borderRadius: '10px',
        border: '1px solid var(--bg-card-2)',
      }}>
        {(['planifier', 'historique'] as const).map(tab => (
          <button
            key={tab}
            type="button"
            onClick={() => onTabChange(tab)}
            aria-current={activeTab === tab ? 'page' : undefined}
            aria-label={tab === 'planifier' ? 'Planifier un emploi du temps' : 'Historique des emplois confirmés'}
            style={{
              position: 'relative',
              padding: '6px 18px',
              minHeight: '36px',
              borderRadius: '7px',
              fontSize: '13px',
              fontWeight: 500,
              transition: 'all 0.15s ease',
              background: activeTab === tab ? 'var(--bg-card-2)' : 'transparent',
              color: activeTab === tab ? 'var(--text-primary)' : 'var(--text-muted-2)',
              border: activeTab === tab ? '1px solid var(--border-2)' : '1px solid transparent',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              cursor: 'pointer',
            }}
          >
            {tab === 'planifier' ? 'Planifier' : 'Historique'}
            {tab === 'historique' && confirmedCount > 0 && (
              <span style={{
                background: 'var(--accent-gl3)',
                color: 'white',
                fontSize: '10px',
                fontWeight: 700,
                borderRadius: '10px',
                minWidth: '18px',
                height: '18px',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '0 5px',
              }}>
                {confirmedCount}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Right: Theme + Engine status */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <button
          type="button"
          onClick={onToggleTheme}
          aria-label={theme === 'light' ? 'Activer le mode nuit' : 'Activer le mode jour'}
          style={{
            minHeight: '34px',
            padding: '6px 10px',
            borderRadius: '7px',
            fontSize: '11px',
            fontWeight: 600,
            background: 'var(--bg-card)',
            color: 'var(--text-primary)',
            border: '1px solid var(--border-2)',
            fontFamily: "'JetBrains Mono', monospace",
          }}
        >
          {theme === 'light' ? 'Nuit' : 'Jour'}
        </button>
        <div style={{
          width: 7, height: 7, borderRadius: '50%',
          background: 'var(--green)',
          boxShadow: '0 0 6px 2px rgba(47,125,99,0.35)',
        }} />
        <span style={{
          fontFamily: "'JetBrains Mono', monospace",
          fontSize: '11px',
          color: 'var(--green)',
          fontWeight: 500,
        }}>
          moteur actif
        </span>
      </div>
    </nav>
  );
}


