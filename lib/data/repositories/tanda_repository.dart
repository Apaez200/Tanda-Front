import '../../models/tanda_config_model.dart';
import '../../models/participant_info_model.dart';
import '../../models/round_info_model.dart';
import '../../models/investment_pool_model.dart';

/// Interfaz para el smart contract de Tanda (Soroban / Stellar).
///
/// Mapeo completo lib.rs → Dart:
///
/// | #  | Rust (lib.rs)              | Dart                      | Tipo  | Estado      |
/// |----|---------------------------|---------------------------|-------|-------------|
/// | 1  | get_config()              | getConfig()               | Query | OK          |
/// | 2  | get_participant(addr)     | getParticipant(addr)      | Query | OK          |
/// | 3  | get_participants()        | getAllParticipants()       | Query | OK          |
/// | 4  | get_round_info()          | getRoundInfo()            | Query | OK          |
/// | 5  | get_investment_pool()     | getCollateralPool()       | Query | OK          |
/// | 6  | get_collateral_pool()     | getCollateralPoolRaw()    | Query | NUEVO       |
/// | 7  | get_turn_order()          | getTurnOrder()            | Query | NUEVO       |
/// | 8  | get_round_cetes(round)    | getRoundCetes(round)      | Query | NUEVO       |
/// | 9  | register(addr)            | register(secret)          | TX    | OK          |
/// | 10 | make_payment(addr)        | makePayment(secret)       | TX    | OK          |
/// | 11 | handle_missed_payment(a)  | handleMissedPayment(addr) | TX    | NUEVO       |
/// | 12 | finalize_round(caller)    | finalizeRound(secret)     | TX    | OK (sin UI) |
/// | 13 | claim_payout(addr)        | claimPayout(secret)       | TX    | OK          |
/// | 14 | reinvest_payout(addr)     | reinvestPayout(secret)    | TX    | NUEVO       |
abstract class TandaRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // QUERIES — Solo lectura, sin firma
  // ═══════════════════════════════════════════════════════════════════════════

  /// #1 — get_config() → TandaConfig
  /// Retorna configuración completa: admin, participantes, monto, periodo, status, etc.
  Future<TandaConfig> getConfig();

  /// #2 — get_participant(address) → ParticipantInfo
  /// Info de un participante: turno, pagos totales, colateral, pagos perdidos.
  Future<ParticipantInfo> getParticipant(String participantAddress);

  /// #3 — get_participants() → Vec<Address> → List<ParticipantInfo>
  /// Lista completa de participantes con su info.
  Future<List<ParticipantInfo>> getAllParticipants();

  /// #4 — get_round_info() → RoundInfo
  /// Ronda actual: beneficiario, pagos recibidos, si está finalizada.
  Future<RoundInfo> getRoundInfo();

  /// #5 — get_investment_pool() → InvestmentPool
  /// Pool de inversión: CETES totales, USDC invertidos, rendimiento acumulado.
  Future<InvestmentPool> getCollateralPool();

  /// #6 — get_collateral_pool() → i128 (NUEVO)
  /// Total de USDC retenidos como colateral en el contrato.
  Future<int> getCollateralPoolRaw();

  /// #7 — get_turn_order() → Vec<Address> (NUEVO)
  /// Orden de turnos para cobrar (se define al llenarse la tanda).
  Future<List<String>> getTurnOrder();

  /// #8 — get_round_cetes(round) → i128 (NUEVO)
  /// CETES tokens acumulados para una ronda específica.
  Future<int> getRoundCetes(int round);

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSACCIONES — Requieren firma con secret key
  // ═══════════════════════════════════════════════════════════════════════════

  /// #9 — register(participant)
  /// Registra al usuario. Requiere balance >= 2x payment_amount (proof of funds).
  /// Errores: 4=NoRegistrando, 5=YaRegistrado, 6=Llena, 7=FondosInsuficientes
  Future<String> register({required String signerSecretKey});

  /// #10 — make_payment(participant)
  /// Pago mensual. Split: 10% colateral (USDC) + 90% inversión (CETES via Etherfuse).
  /// PREREQUISITO: llamar approveUsdcAllowance() antes.
  /// Errores: 8=NoActiva, 9=RondaFinalizada, 10=VentanaCerrada, 11=YaPagó, 13=NoEncontrado
  Future<String> makePayment({required String signerSecretKey});

  /// #11 — handle_missed_payment(missed_participant) (NUEVO)
  /// Cubre un pago perdido usando colateral del participante + pool compartido.
  /// Cualquiera puede llamarlo después de que cierre la ventana de pago.
  /// Errores: 8=NoActiva, 9=RondaFinalizada, 12=VentanaAbierta, 13=NoEncontrado, 11=YaPagó
  Future<String> handleMissedPayment({required String missedParticipantAddress});

  /// #12 — finalize_round(caller)
  /// Cierra la ronda actual e inicia la siguiente (o completa la tanda).
  /// Requiere que todos hayan pagado o sido cubiertos.
  /// Errores: 8=NoActiva, 9=YaFinalizada, 16=FaltanPagos
  Future<String> finalizeRound({required String adminSecretKey});

  /// #13 — claim_payout(participant)
  /// Cobra el turno: redime CETES de Etherfuse → USDC principal + rendimiento.
  /// Si la tanda está completada, también devuelve el colateral.
  /// Errores: 14=NoEsTuTurno, 15=YaCobrado, 13=NoEncontrado
  Future<String> claimPayout({required String signerSecretKey});

  /// #14 — reinvest_payout(participant) (NUEVO)
  /// Señala intención de dejar los CETES invertidos (no mueve fondos).
  /// Se puede llamar claim_payout() después para retirar.
  /// Errores: 14=NoEsTuTurno, 15=YaCobrado, 17=NoCETES
  Future<String> reinvestPayout({required String signerSecretKey});
}
