import React from 'react';

interface NavBarProps {
  activeTab: 'planifier' | 'historique';
  onTabChange: (tab: 'planifier' | 'historique') => void;
  confirmedCount: number;
}

export default function NavBar({ activeTab, onTabChange, confirmedCount }: NavBarProps) {
  return (
    <nav
      role="navigation"
      aria-label="Navigation principale"
      style={{
        position: 'fixed',
        top: 0, left: 0, right: 0,
        height: '60px',
        backgroundColor: '#0f1118',
        borderBottom: '1px solid #1a1e2a',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 24px',
        zIndex: 100,
      }}>
      {/* Left: Logo */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
        <div style={{
          width: 26, height: 26, borderRadius: 7,
          background: 'linear-gradient(135deg, #00c9b1, #7c6af7)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <rect x="1" y="1" width="5" height="5" rx="1.5" fill="white" fillOpacity="0.9"/>
            <rect x="8" y="1" width="5" height="5" rx="1.5" fill="white" fillOpacity="0.6"/>
            <rect x="1" y="8" width="5" height="5" rx="1.5" fill="white" fillOpacity="0.6"/>
            <rect x="8" y="8" width="5" height="5" rx="1.5" fill="white" fillOpacity="0.4"/>
          </svg>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: '7px' }}>
          <span style={{ fontWeight: 700, fontSize: '14.5px', color: '#dde1ed', letterSpacing: '-0.01em' }}>
            ProScheduler
          </span>
          <span style={{
            fontFamily: "'JetBrains Mono', monospace",
            fontSize: '9px',
            fontWeight: 600,
            color: '#7c6af7',
            background: 'rgba(124,106,247,0.12)',
            padding: '1px 6px',
            borderRadius: '4px',
            border: '1px solid rgba(124,106,247,0.25)',
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
        background: '#0b0d12',
        padding: '4px',
        borderRadius: '10px',
        border: '1px solid #1a1e2a',
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
              background: activeTab === tab ? '#1a1e2a' : 'transparent',
              color: activeTab === tab ? '#dde1ed' : '#8892aa',
              border: activeTab === tab ? '1px solid #252a3a' : '1px solid transparent',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              cursor: 'pointer',
            }}
          >
            {tab === 'planifier' ? 'Planifier' : 'Historique'}
            {tab === 'historique' && confirmedCount > 0 && (
              <span style={{
                background: '#7c6af7',
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

      {/* Right: Engine status */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <div style={{
          width: 7, height: 7, borderRadius: '50%',
          background: '#34d399',
          boxShadow: '0 0 6px 2px rgba(52,211,153,0.45)',
        }} />
        <span style={{
          fontFamily: "'JetBrains Mono', monospace",
          fontSize: '11px',
          color: '#34d399',
          fontWeight: 500,
        }}>
          moteur actif
        </span>
      </div>
    </nav>
  );
}
