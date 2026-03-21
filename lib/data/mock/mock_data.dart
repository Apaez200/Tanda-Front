import '../../models/participant_model.dart';
import '../../models/tanda_model.dart';
import '../../models/transaction_model.dart';

final Tanda mockTanda = Tanda(
  id: 'tanda_001',
  name: 'Tanda de los Amigos',
  amountPerPerson: 1000.0,
  cutoffDay: 30,
  currentRound: 1,
  totalParticipants: 5,
  poolTotal: 5000.0,
  accumulatedYield: 187.50,
  myTurn: 3,
);

final List<Participant> mockParticipants = [
  const Participant(name: 'Ana G.', hasDeposited: true, isMe: false, turn: 1),
  const Participant(name: 'Carlos M.', hasDeposited: true, isMe: false, turn: 2),
  const Participant(name: 'Tú', hasDeposited: false, isMe: true, turn: 3),
  const Participant(name: 'Laura P.', hasDeposited: true, isMe: false, turn: 4),
  const Participant(name: 'Roberto S.', hasDeposited: false, isMe: false, turn: 5),
];

final List<Transaction> mockTransactions = [
  const Transaction(type: 'deposit', amount: -1000, date: '15 Feb 2025', description: 'Depósito ronda 1'),
  const Transaction(type: 'yield', amount: 42.50, date: '28 Feb 2025', description: 'Rendimiento generado'),
  const Transaction(type: 'claim', amount: 5150.0, date: '30 Ene 2025', description: 'Cobro turno — Ronda anterior'),
];

const double mockDailyNetAPY = 0.000246;
const double retentionAmount = 200.0;

double projectedNetYield({required double amount, required int daysInvested}) =>
    amount * mockDailyNetAPY * daysInvested;
