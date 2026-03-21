class Transaction {
  const Transaction({
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
  });

  final String type;
  final double amount;
  final String date;
  final String description;
}
