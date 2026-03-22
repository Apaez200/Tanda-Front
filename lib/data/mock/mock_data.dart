import '../../models/participant_model.dart';
import '../../models/tanda_model.dart';
import '../../models/transaction_model.dart';

// Tanda avanzada: 10 personas, ronda 7 de 10, $1,000 por ronda
final Tanda mockTanda = Tanda(
  id: 'tanda_001',
  name: 'Rendix del Equipo',
  amountPerPerson: 1000.0,
  cutoffDay: 30,
  currentRound: 7,
  totalParticipants: 10,
  poolTotal: 63000.0, // 7 rondas x 10 personas x $1,000 x 90% invertido
  accumulatedYield: 3675.0, // ~5.25% acumulado en 7 meses (9% anual)
  myTurn: 5,
);

final List<Participant> mockParticipants = [
  const Participant(name: 'Ana L.', hasDeposited: true, isMe: false, turn: 1),
  const Participant(name: 'Carlos M.', hasDeposited: true, isMe: false, turn: 2),
  const Participant(name: 'Mariana P.', hasDeposited: true, isMe: false, turn: 3),
  const Participant(name: 'Fernando R.', hasDeposited: true, isMe: false, turn: 4),
  const Participant(name: 'Tú', hasDeposited: false, isMe: true, turn: 5),
  const Participant(name: 'Laura V.', hasDeposited: true, isMe: false, turn: 6),
  const Participant(name: 'Sofía R.', hasDeposited: true, isMe: false, turn: 7),
  const Participant(name: 'Roberto S.', hasDeposited: true, isMe: false, turn: 8),
  const Participant(name: 'Diana M.', hasDeposited: false, isMe: false, turn: 9),
  const Participant(name: 'Miguel A.', hasDeposited: true, isMe: false, turn: 10),
];

// Historial de 7 rondas de actividad
final List<Transaction> mockTransactions = [
  // Ronda 7 (actual)
  const Transaction(type: 'deposit', amount: -1000, date: '10 Mar 2026', description: 'Depósito ronda 7'),
  const Transaction(type: 'yield', amount: 525.00, date: '22 Mar 2026', description: 'Rendimiento CETES acumulado'),
  // Ronda 6
  const Transaction(type: 'deposit', amount: -1000, date: '08 Feb 2026', description: 'Depósito ronda 6'),
  const Transaction(type: 'yield', amount: 472.50, date: '28 Feb 2026', description: 'Rendimiento CETES'),
  // Ronda 5
  const Transaction(type: 'deposit', amount: -1000, date: '12 Ene 2026', description: 'Depósito ronda 5'),
  const Transaction(type: 'yield', amount: 393.75, date: '30 Ene 2026', description: 'Rendimiento CETES'),
  // Ronda 4
  const Transaction(type: 'deposit', amount: -1000, date: '10 Dic 2025', description: 'Depósito ronda 4'),
  const Transaction(type: 'yield', amount: 315.00, date: '30 Dic 2025', description: 'Rendimiento CETES'),
  // Ronda 3
  const Transaction(type: 'deposit', amount: -1000, date: '11 Nov 2025', description: 'Depósito ronda 3'),
  const Transaction(type: 'yield', amount: 236.25, date: '30 Nov 2025', description: 'Rendimiento CETES'),
  // Ronda 2
  const Transaction(type: 'deposit', amount: -1000, date: '14 Oct 2025', description: 'Depósito ronda 2'),
  const Transaction(type: 'yield', amount: 157.50, date: '30 Oct 2025', description: 'Rendimiento CETES'),
  // Ronda 1
  const Transaction(type: 'deposit', amount: -1000, date: '15 Sep 2025', description: 'Depósito ronda 1 (pago inicial)'),
  const Transaction(type: 'yield', amount: 78.75, date: '30 Sep 2025', description: 'Primer rendimiento CETES'),
  // Colateral retenido
  const Transaction(type: 'frozen', amount: -700, date: 'Activo', description: 'Colateral retenido (7 rondas)'),
];

const double mockDailyNetAPY = 0.000246;
const double retentionAmount = 10.0; // $10 por pago para CETES

double projectedNetYield({required double amount, required int daysInvested}) =>
    amount * mockDailyNetAPY * daysInvested;
