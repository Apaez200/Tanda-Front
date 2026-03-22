# Smart Contract Integration — TandaChain

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter App (Dart)                                             │
│                                                                 │
│  Screens ──► TandaRepository (abstract) ──► SorobanTandaRepo   │
│              WalletRepository (abstract) ──► SorobanWalletRepo  │
│                                                                 │
│  SorobanTandaRepo ──► Soroban RPC ──► Smart Contract (Rust)     │
│  SorobanWalletRepo ──► Horizon API + USDC SAC                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Smart Contract (Rust / Soroban)                                │
│  Ubicación: C:\Users\Admin\Desktop\tanda-contract               │
│                                                                 │
│  contracts/tanda/src/                                           │
│  ├── lib.rs        ← Lógica principal (14 funciones públicas)   │
│  ├── types.rs      ← TandaConfig, ParticipantInfo, RoundInfo   │
│  ├── errors.rs     ← TandaError (códigos 4-17)                 │
│  ├── events.rs     ← 7 eventos on-chain                        │
│  ├── etherfuse.rs  ← Cliente cross-contract (CETES)            │
│  └── test.rs       ← Suite de tests                            │
└─────────────────────────────────────────────────────────────────┘
```

## Contratos Desplegados (Stellar Testnet)

| Contrato     | Contract ID                                            |
|-------------|--------------------------------------------------------|
| **Tanda**   | `CCMSKXEV5AYD6QZOXNASKGBZX3ERUAH2K2CD2H3ZE4NFJ3ANCXHFLTAU` |
| **USDC**    | `CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA` |
| **CETES**   | `CD7MNVVTG3V3C7QRLLPOTKRLKJBXNEFZRHSHRZJYMNW2UTOMIMVZB32X` |

**RPC**: `https://soroban-testnet.stellar.org`
**Horizon**: `https://horizon-testnet.stellar.org`

---

## Mapeo completo: lib.rs → Dart

### QUERIES (Solo lectura, sin firma)

| #  | Rust `lib.rs`             | Dart `TandaRepository`     | Pantallas              | Estado |
|----|--------------------------|---------------------------|------------------------|--------|
| 1  | `get_config()`           | `getConfig()`             | Hub, Dashboard, Join, Deposit, Claim, MyTandas | ✅ |
| 2  | `get_participant(addr)`  | `getParticipant(addr)`    | Dashboard, History     | ✅ |
| 3  | `get_participants()`     | `getAllParticipants()`     | Dashboard, Join, Hub   | ✅ |
| 4  | `get_round_info()`       | `getRoundInfo()`          | Dashboard, Claim       | ✅ |
| 5  | `get_investment_pool()`  | `getCollateralPool()`     | Dashboard, Claim, History | ✅ |
| 6  | `get_collateral_pool()`  | `getCollateralPoolRaw()`  | —                      | ✅ nuevo |
| 7  | `get_turn_order()`       | `getTurnOrder()`          | —                      | ✅ nuevo |
| 8  | `get_round_cetes(round)` | `getRoundCetes(round)`    | —                      | ✅ nuevo |

### TRANSACCIONES (Requieren firma)

| #  | Rust `lib.rs`                    | Dart `TandaRepository`           | Pantalla     | Estado |
|----|----------------------------------|----------------------------------|-------------|--------|
| 9  | `register(participant)`          | `register(secret)`               | Join, Dashboard | ✅ |
| 10 | `make_payment(participant)`      | `makePayment(secret)`            | Deposit     | ✅ |
| 11 | `handle_missed_payment(addr)`    | `handleMissedPayment(addr)`      | —           | ✅ nuevo |
| 12 | `finalize_round(caller)`         | `finalizeRound(secret)`          | sin UI      | ✅ |
| 13 | `claim_payout(participant)`      | `claimPayout(secret)`            | Claim       | ✅ |
| 14 | `reinvest_payout(participant)`   | `reinvestPayout(secret)`         | —           | ✅ nuevo |

### WALLET / USDC SAC

| #  | Operación                    | Dart `WalletRepository`       | Pantalla   | Estado |
|----|------------------------------|-------------------------------|-----------|--------|
| A  | Leer public key              | `getConnectedPublicKey()`     | Todas     | ✅ |
| B  | Guardar keypair              | `saveKeypair(pub, sec)`       | Login     | ✅ |
| C  | Leer secret key              | `getSavedSecretKey()`         | TX screens | ✅ |
| D  | Borrar keypair               | `clearKeypair()`              | Logout    | ✅ |
| E  | Generar keypair              | `generateTestnetKeypair()`    | Login     | ✅ |
| F  | Fondear testnet              | `fundTestnetAccount(pub)`     | Login     | ✅ |
| G  | Balance USDC                 | `getUsdcBalance(pub)`         | Hub       | ✅ |
| H  | Aprobar USDC allowance       | `approveUsdcAllowance(sec,amt)` | Deposit | ✅ |

---

## Flujos de transacción detallados

### Registrarse (Join → register)
```
1. Usuario toca "Registrarme" en JoinTandaScreen
2. walletRepository.getSavedSecretKey() → secretKey
3. tandaRepository.register(signerSecretKey: secretKey)
   └── lib.rs::register(participant)
       ├── require_auth()
       ├── Verificar status == Registering
       ├── Verificar no esté registrado
       ├── Verificar balance >= 2 × payment_amount
       ├── Guardar ParticipantInfo
       ├── Si se llenó → auto-start (status = Active, crear RoundInfo)
       └── Emitir RegisteredEvent
4. tandaStorage.saveTanda(contractId, name, role='member')
5. Navegar a /dashboard
```

### Depositar (Deposit → approve + make_payment)
```
1. Usuario toca "Depositar" en DepositScreen
2. walletRepository.getSavedSecretKey() → secretKey
3. walletRepository.approveUsdcAllowance(secretKey, paymentAmount)
   └── USDC SAC::approve(from, spender=tanda, amount, expiry)
4. tandaRepository.makePayment(signerSecretKey: secretKey)
   └── lib.rs::make_payment(participant)
       ├── require_auth()
       ├── Verificar status == Active, ventana abierta, no pagó
       ├── Split: 10% colateral (USDC) + 90% inversión
       ├── token.transfer(participant → contrato, payment_amount)
       ├── token.transfer(contrato → etherfuse, invest_amount)
       ├── etherfuse.deposit() → cetes_minted
       ├── Actualizar pools + participante + ronda
       └── Emitir PaymentMadeEvent
5. Mostrar modal de éxito con TX hash
```

### Cobrar turno (Claim → claim_payout)
```
1. Usuario toca "Cobrar" en ClaimScreen
2. walletRepository.getSavedSecretKey() → secretKey
3. tandaRepository.claimPayout(signerSecretKey: secretKey)
   └── lib.rs::claim_payout(participant)
       ├── require_auth()
       ├── Verificar payout_round < current_round O tanda completada
       ├── Verificar no ha cobrado
       ├── etherfuse.redeem(cetes_balance) → usdc_from_cetes
       ├── yield = usdc_from_cetes - principal
       ├── Si completada: + devolver colateral
       ├── token.transfer(contrato → participant, total_payout)
       └── Emitir PayoutClaimedEvent
4. Mostrar modal + confetti
```

### Pago perdido (handle_missed_payment) — SIN UI
```
1. Después de que cierra la ventana de pago
2. Cualquier participante puede llamar:
   tandaRepository.handleMissedPayment(missedAddress)
   └── lib.rs::handle_missed_payment(missed_participant)
       ├── Verificar ventana cerrada
       ├── Usar colateral personal primero
       ├── Si no alcanza → usar pool compartido
       ├── Incrementar missed_payments
       └── Emitir PaymentMissedEvent
```

### Finalizar ronda (finalize_round) — SIN UI
```
1. Admin o participante llama cuando todos pagaron:
   tandaRepository.finalizeRound(adminSecretKey)
   └── lib.rs::finalize_round(caller)
       ├── require_auth()
       ├── Verificar payments_received >= max_participants
       ├── Marcar ronda como finalizada
       ├── Si hay más rondas → crear siguiente RoundInfo
       ├── Si era última → status = Completed
       └── Emitir RoundFinalizedEvent
```

---

## Errores del contrato (errors.rs → Dart)

| Código | Rust                    | Dart                        | Mensaje usuario                                    |
|--------|-------------------------|-----------------------------|----------------------------------------------------|
| 4      | TandaNotRegistering     | tandaNotRegistering         | La tanda ya no acepta nuevos participantes.         |
| 5      | AlreadyRegistered       | alreadyRegistered           | Ya estás registrado en esta tanda.                  |
| 6      | TandaFull               | tandaFull                   | La tanda está llena, no hay lugares disponibles.    |
| 7      | InsufficientBalance     | insufficientBalance         | Saldo insuficiente. Necesitas USDC en tu wallet.    |
| 8      | TandaNotActive          | tandaNotActive              | La tanda aún no ha comenzado.                       |
| 9      | RoundAlreadyFinalized   | roundAlreadyFinalized       | La ronda ya fue finalizada.                         |
| 10     | PaymentWindowClosed     | paymentWindowClosed         | El periodo de pago ya cerró.                        |
| 11     | AlreadyPaid             | alreadyPaid                 | Ya realizaste tu pago de este mes.                  |
| 12     | PaymentWindowOpen       | paymentWindowOpen           | El periodo de pago aún está abierto.                |
| 13     | ParticipantNotFound     | participantNotFound         | No se encontró tu registro en la tanda.             |
| 14     | NotYourTurn             | notYourTurn                 | Aún no es tu turno de cobrar.                       |
| 15     | AlreadyReceivedPayout   | alreadyReceivedPayout       | Ya cobraste tu turno en esta tanda.                 |
| 16     | RoundNotFinalized       | roundNotFinalized           | La ronda aún no ha sido finalizada.                 |
| 17     | NoCetesToReinvest       | noCetesToReinvest           | No hay CETES disponibles para reinvertir.           |

---

## Eventos on-chain (events.rs)

| Evento                 | Topic          | Datos                                              |
|------------------------|----------------|-----------------------------------------------------|
| RegisteredEvent        | `registered`   | participant, turn                                   |
| TandaStartedEvent      | `tanda_start`  | start_time, max_participants                        |
| PaymentMadeEvent       | `paid`         | participant, round, amount, collateral, invested, cetes_minted |
| PaymentMissedEvent     | `missed`       | participant, round, own_collateral_used, pool_used  |
| RoundFinalizedEvent    | `round_end`    | round, beneficiary                                  |
| PayoutClaimedEvent     | `claimed`      | participant, payout_round, principal, yield_amount, collateral_returned |
| PayoutReinvestedEvent  | `reinvested`   | participant, payout_round, cetes_kept               |

---

## Archivos clave

### Smart Contract (Rust)
```
C:\Users\Admin\Desktop\tanda-contract\contracts\tanda\src\
├── lib.rs          685 líneas — 14 funciones públicas
├── types.rs         82 líneas — TandaConfig, ParticipantInfo, RoundInfo, InvestmentPool
├── errors.rs        25 líneas — TandaError enum (códigos 4-17)
├── events.rs        68 líneas — 7 eventos on-chain
├── etherfuse.rs     50 líneas — Cliente cross-contract deposit/redeem
└── test.rs         377 líneas — Suite de tests
```

### Flutter (Dart)
```
C:\Users\Admin\Desktop\Proyecto\lib\
├── data\repositories\
│   ├── tanda_repository.dart         ← Interfaz abstracta (14 métodos)
│   └── wallet_repository.dart        ← Interfaz abstracta (7 métodos)
├── data\implementations\soroban\
│   ├── soroban_tanda_repository.dart ← Implementación real Soroban
│   └── soroban_wallet_repository.dart← Wallet + USDC approval
├── data\implementations\mock\
│   ├── mock_tanda_repository.dart    ← Mock para testing
│   └── mock_wallet_repository.dart   ← Mock wallet
├── core\constants\
│   └── contract_constants.dart       ← Contract IDs, parámetros
├── models\
│   ├── tanda_config_model.dart       ← Espejo de types.rs::TandaConfig
│   ├── participant_info_model.dart   ← Espejo de types.rs::ParticipantInfo
│   ├── round_info_model.dart         ← Espejo de types.rs::RoundInfo
│   ├── investment_pool_model.dart    ← Espejo de types.rs::InvestmentPool
│   └── tanda_error_model.dart        ← Espejo de errors.rs::TandaError
└── injection.dart                    ← DI: mock vs soroban (useMock flag)
```

---

## Comandos utilizados

### Desarrollo Flutter
```bash
# Correr app en Chrome
flutter run -d chrome

# Correr con Accesly App ID
flutter run -d chrome --dart-define=ACCESLY_APP_ID=acc_d3480b81eb11e101f8709561

# Hot restart (en terminal activa)
R
```

### Smart Contract (Rust/Soroban)
```bash
# Compilar contrato
cd C:\Users\Admin\Desktop\tanda-contract
stellar contract build

# Deploy en testnet
stellar contract deploy \
  --wasm target/wasm32-unknown-unknown/release/tanda.wasm \
  --network testnet \
  --source <ADMIN_SECRET_KEY>

# Inicializar contrato
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  --source <ADMIN_SECRET_KEY> \
  -- __constructor \
  --admin <ADMIN_ADDRESS> \
  --max_participants 5 \
  --payment_amount 1000000000 \
  --period_secs 2592000 \
  --payment_token <USDC_CONTRACT_ID> \
  --cetes_token <CETES_CONTRACT_ID>

# Consultar configuración
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- get_config

# Registrar participante
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  --source <PARTICIPANT_SECRET> \
  -- register \
  --participant <PARTICIPANT_ADDRESS>

# Hacer pago
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  --source <PARTICIPANT_SECRET> \
  -- make_payment \
  --participant <PARTICIPANT_ADDRESS>

# Finalizar ronda
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  --source <ADMIN_SECRET> \
  -- finalize_round \
  --caller <ADMIN_ADDRESS>

# Cobrar turno
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  --source <PARTICIPANT_SECRET> \
  -- claim_payout \
  --participant <PARTICIPANT_ADDRESS>

# Reinvertir
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  --source <PARTICIPANT_SECRET> \
  -- reinvest_payout \
  --participant <PARTICIPANT_ADDRESS>

# Cubrir pago perdido
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- handle_missed_payment \
  --missed_participant <ADDRESS>

# Consultar participante
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- get_participant \
  --participant <ADDRESS>

# Consultar ronda
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- get_round_info

# Consultar pool de inversión
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- get_investment_pool

# Consultar colateral
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- get_collateral_pool

# Consultar orden de turnos
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- get_turn_order

# Consultar CETES de una ronda
stellar contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- get_round_cetes \
  --round 0

# Tests
cd C:\Users\Admin\Desktop\tanda-contract
cargo test
```

### Git
```bash
# Crear rama para Accesly
git checkout -b feature/accesly-login

# Ver estado
git status
git diff
```
