class ContractConstants {
  // ── Red ────────────────────────────────────────────────────────────────
  static const String sorobanRpcUrl =
      'https://soroban-testnet.stellar.org';
  static const String horizonUrl =
      'https://horizon-testnet.stellar.org';
  static const String networkPassphrase =
      'Test SDF Network ; September 2015';

  // ── IDs de contratos en Testnet ────────────────────────────────────────
  static const String tandaContractId =
      'CDJ6IFHWNLENDBYEYLS5MZJLKHSWZQBOR5YCUTJQZJZA6N2H7ESQZ5JL';
  static const String usdcContractId =
      'CBAGP2L3PVINJUJOMPTACPTINMRO5MHZEIWC3DYIIKLWM6XPRZHRO6OY';
  static const String cetesContractId =
      'CACGMVJODMCMLXH4KWURZZ7FWH4FA5EXE5P7KXZLBDB2BDEBD2AD6R6V';

  // ── Emisor USDC testnet (faucet) ───────────────────────────────────────
  static const String usdcIssuerPublic =
      'GCYX6CVR3LRHHJ42DZTL5D5UKEOAZZVJ3LHRTR7DG2VYHLLUNSEMH4F4';

  /// Secret key del emisor USDC en testnet. Solo para faucet de pruebas.
  /// Pásalo via --dart-define=USDC_FAUCET_SECRET=S...
  static const String usdcFaucetSecret = String.fromEnvironment(
    'USDC_FAUCET_SECRET',
    defaultValue: '',
  );

  /// Cantidad de USDC que el faucet envía a cuentas nuevas (5,000 USDC).
  static const int faucetAmountStroops = 5000000000;

  // ── Parámetros del contrato ────────────────────────────────────────────
  static const int usdcDecimals = 6;
  static const int paymentAmountStroops = 1000000000; // 1,000 USDC
  static const int collateralBps = 1000; // 10%
  static const int periodSecs = 2592000; // 30 días

  // ── Feature flag ────────────────────────────────────────────────────────
  /// true  → usa MockRepository (datos hardcodeados, sin red)
  /// false → usa SorobanRepository (Stellar Testnet real)
  static const bool useMock = true;
}
