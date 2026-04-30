import type { Room } from '../types';

// Subset of rooms used in the simulation (as specified in requirements)
export const ROOMS: Room[] = [
  { id: 'A1',    type: 'amphi',    capacity: 100, energyCost: 4 },
  { id: 'A2',    type: 'amphi',    capacity: 200, energyCost: 4 },
  { id: 'R103',  type: 'salle_td', capacity: 50,  energyCost: 3 },
  { id: 'R105',  type: 'salle_td', capacity: 50,  energyCost: 3 },
  { id: 'R115',  type: 'salle_td', capacity: 50,  energyCost: 3 },
  { id: 'Li013', type: 'labo_pc',  capacity: 50,  energyCost: 8 },
  { id: 'Li116', type: 'labo_pc',  capacity: 50,  energyCost: 8 },
];

export const ROOMS_BY_ID: Record<string, Room> = Object.fromEntries(
  ROOMS.map(r => [r.id, r])
);

export const ROOMS_BY_TYPE: Record<string, Room[]> = {
  amphi:    ROOMS.filter(r => r.type === 'amphi'),
  salle_td: ROOMS.filter(r => r.type === 'salle_td'),
  labo_pc:  ROOMS.filter(r => r.type === 'labo_pc'),
};
