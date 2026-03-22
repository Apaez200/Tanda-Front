import '../../repositories/wallet_repository.dart';

class MockWalletRepository implements WalletRepository {
  String? _savedPublicKey;
  String? _savedSecretKey;

  @override
  Future<String?> getConnectedPublicKey() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _savedPublicKey ?? 'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W';
  }

  @override
  Future<Map<String, String>> generateTestnetKeypair() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'publicKey': 'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W',
      'secretKey': 'SCZANGBA5YHTNYVVV3C7CAZMCLXPILHSE6PGYAY2TDGPMWRCKWUV354E',
    };
  }

  @override
  Future<bool> fundTestnetAccount(String publicKey) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  @override
  Future<int> getUsdcBalance(String publicKey) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 5000000000; // 5,000 USDC
  }

  @override
  Future<void> saveKeypair(String publicKey, String secretKey) async {
    _savedPublicKey = publicKey;
    _savedSecretKey = secretKey;
  }

  @override
  Future<String?> getSavedSecretKey() async {
    return _savedSecretKey ?? 'SCZANGBA5YHTNYVVV3C7CAZMCLXPILHSE6PGYAY2TDGPMWRCKWUV354E';
  }

  @override
  Future<void> clearKeypair() async {
    _savedPublicKey = null;
    _savedSecretKey = null;
  }
}
