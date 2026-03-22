import 'dart:async';

/// Stub implementation of AcceslyService for non-web platforms.
/// All web-specific functionality is a no-op.
class AcceslyService {
  static final AcceslyService _instance = AcceslyService._internal();
  factory AcceslyService() => _instance;
  AcceslyService._internal();

  final _walletController = StreamController<AcceslyWallet?>.broadcast();
  Stream<AcceslyWallet?> get walletStream => _walletController.stream;

  AcceslyWallet? get currentWallet => null;
  bool get isConnected => false;

  void registerViewFactory() {
    // No-op on non-web platforms
  }

  Future<AcceslySignResult> signAndSubmit(String unsignedXdr) async {
    throw UnsupportedError('Accesly is only available on web');
  }

  Future<AcceslySignResult> signTransaction(String unsignedXdr) async {
    throw UnsupportedError('Accesly is only available on web');
  }

  void dispose() {
    _walletController.close();
  }
}

class AcceslyWallet {
  final String stellarAddress;
  final String email;
  const AcceslyWallet({required this.stellarAddress, required this.email});
}

class AcceslySignResult {
  final String signedXdr;
  final String txHash;
  const AcceslySignResult({required this.signedXdr, required this.txHash});
}
