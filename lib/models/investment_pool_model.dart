class InvestmentPool {
  final int totalCetesTokens;
  final int totalUsdcInvested;
  final int accumulatedYield;

  double get totalUsdcInvestedMXN => totalUsdcInvested / 1000000000;
  double get accumulatedYieldMXN => accumulatedYield / 1000000000;
  double get yieldPercentage =>
      totalUsdcInvested > 0
          ? (accumulatedYield / totalUsdcInvested) * 100
          : 0.0;

  const InvestmentPool({
    required this.totalCetesTokens,
    required this.totalUsdcInvested,
    required this.accumulatedYield,
  });
}
