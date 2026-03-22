import 'package:flutter/foundation.dart';

/// Whether the user has deposited this round.
final ValueNotifier<bool> userDepositedNotifier = ValueNotifier<bool>(false);

/// Connected wallet public key (null = not connected).
final ValueNotifier<String?> walletPublicKeyNotifier = ValueNotifier<String?>(null);
