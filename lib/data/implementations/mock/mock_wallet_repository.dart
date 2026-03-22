import '../../mock/mock_state.dart';
import '../../repositories/wallet_repository.dart';

/// Mock wallet that reads balance from [MockState].
///
/// After a deposit, getUsdcBalance reflects the deduction immediately.
class MockWalletRepository implements WalletRepository {
  String? _savedPublicKey;
  String? _savedSecretKey;

  final _s = MockState.instance;

  static const _mockPublicKey =
      'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W';
  static const _mockSecretKey =
      'SCZANGBA5YHTNYVVV3C7CAZMCLXPILHSE6PGYAY2TDGPMWRCKWUV354E';

  @override
  Future<String?> getConnectedPublicKey() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _savedPublicKey;
  }

  @override
  Future<Map<String, String>> generateTestnetKeypair() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'publicKey': _mockPublicKey, 'secretKey': _mockSecretKey};
  }

  @override
  Future<bool> fundTestnetAccount(String publicKey) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  @override
  Future<int> getUsdcBalance(String publicKey) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _s.walletBalanceStroops;
  }

  @override
  Future<void> saveKeypair(String publicKey, String secretKey) async {
    _savedPublicKey = publicKey;
    _savedSecretKey = secretKey;
  }

  @override
  Future<String?> getSavedSecretKey() async {
    return _savedSecretKey ?? _mockSecretKey;
  }

  @override
  Future<void> clearKeypair() async {
    _savedPublicKey = null;
    _savedSecretKey = null;
  }
}
