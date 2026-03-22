import 'package:tandachain/core/constants/contract_constants.dart';
import 'package:tandachain/data/repositories/tanda_repository.dart';
import 'package:tandachain/data/repositories/wallet_repository.dart';
import 'package:tandachain/data/implementations/mock/mock_tanda_repository.dart';
import 'package:tandachain/data/implementations/mock/mock_wallet_repository.dart';
import 'package:tandachain/data/implementations/soroban/soroban_tanda_repository.dart';
import 'package:tandachain/data/implementations/soroban/soroban_wallet_repository.dart';
import 'package:tandachain/data/services/tanda_storage_service.dart';

// ── Repositorios globales ─────────────────────────────────────────
final TandaRepository tandaRepository = ContractConstants.useMock
    ? MockTandaRepository()
    : SorobanTandaRepository();

final WalletRepository walletRepository = ContractConstants.useMock
    ? MockWalletRepository()
    : SorobanWalletRepository();

// ── Servicios ─────────────────────────────────────────────────────
final TandaStorageService tandaStorage = TandaStorageService();

/// Switch the active tanda contract.
void setActiveTandaContract(String contractId) {
  if (tandaRepository is SorobanTandaRepository) {
    (tandaRepository as SorobanTandaRepository).setContractId(contractId);
  }
  tandaStorage.setActiveTanda(contractId);
}
