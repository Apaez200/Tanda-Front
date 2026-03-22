/// Interfaz para operaciones de wallet Stellar + USDC SAC.
///
/// | #  | Operación                    | Destino              | Usado en             |
/// |----|------------------------------|----------------------|----------------------|
/// | A  | getConnectedPublicKey()      | SharedPreferences    | Splash, Login, Hub…  |
/// | B  | saveKeypair()                | SharedPreferences    | Login                |
/// | C  | getSavedSecretKey()          | SharedPreferences    | Deposit, Claim, Reg  |
/// | D  | clearKeypair()               | SharedPreferences    | Logout               |
/// | E  | generateTestnetKeypair()     | KeyPair.random()     | Login (crear)        |
/// | F  | fundTestnetAccount()         | FriendBot            | Login (crear)        |
/// | G  | getUsdcBalance()             | Horizon API          | Hub (balance)        |
/// | H  | approveUsdcAllowance()       | USDC SAC approve()   | Deposit (pre-pago)   |
abstract class WalletRepository {
  /// A — Public key guardada localmente (null si no hay wallet).
  Future<String?> getConnectedPublicKey();

  /// B — Persistir par de llaves en el dispositivo.
  Future<void> saveKeypair(String publicKey, String secretKey);

  /// C — Secret key para firmar transacciones.
  Future<String?> getSavedSecretKey();

  /// D — Borrar wallet del dispositivo (logout).
  Future<void> clearKeypair();

  /// E — Generar keypair aleatorio para Stellar testnet.
  Future<Map<String, String>> generateTestnetKeypair();

  /// F — Fondear cuenta en testnet via FriendBot.
  Future<bool> fundTestnetAccount(String publicKey);

  /// G — Balance USDC de una cuenta (en stroops: /1,000,000 para MXN).
  Future<int> getUsdcBalance(String publicKey);
}
