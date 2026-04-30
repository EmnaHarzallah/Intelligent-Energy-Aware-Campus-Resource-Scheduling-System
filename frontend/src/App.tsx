import React, { useState } from 'react';
import type { ConfirmedSchedule, GlobalOccupied } from './types';
import NavBar from './components/NavBar';
import PlanifierView from './components/PlanifierView';
import HistoriqueView from './components/HistoriqueView';

type ActiveTab = 'planifier' | 'historique';

export default function App() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('planifier');
  const [confirmedSchedules, setConfirmedSchedules] = useState<ConfirmedSchedule[]>([]);
  const [globalOccupied, setGlobalOccupied] = useState<GlobalOccupied>({
    roomSlots: new Set<string>(),
    instructorSlots: new Set<string>(),
  });

  function handleConfirm(schedule: ConfirmedSchedule) {
    const newRoomSlots = new Set(globalOccupied.roomSlots);
    const newInstrSlots = new Set(globalOccupied.instructorSlots);

    for (const asgn of schedule.assignments) {
      newRoomSlots.add(`${asgn.roomId}_${asgn.day}_${asgn.slot}`);
      newInstrSlots.add(`${asgn.session.instructor}_${asgn.day}_${asgn.slot}`);
    }

    setGlobalOccupied({ roomSlots: newRoomSlots, instructorSlots: newInstrSlots });
    setConfirmedSchedules(prev => [...prev, schedule]);
    setActiveTab('historique');
  }

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#0b0d12', color: '#dde1ed', fontFamily: "'Outfit', sans-serif" }}>
      <NavBar
        activeTab={activeTab}
        onTabChange={setActiveTab}
        confirmedCount={confirmedSchedules.length}
      />
      <main style={{ paddingTop: '60px' }}>
        {activeTab === 'planifier' ? (
          <PlanifierView
            globalOccupied={globalOccupied}
            onConfirm={handleConfirm}
          />
        ) : (
          <HistoriqueView confirmedSchedules={confirmedSchedules} />
        )}
      </main>
    </div>
  );
}
