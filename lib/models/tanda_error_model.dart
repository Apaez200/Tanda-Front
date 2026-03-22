enum TandaContractError {
  tandaNotRegistering,   // code 4
  alreadyRegistered,     // code 5
  tandaFull,             // code 6
  insufficientBalance,   // code 7
  tandaNotActive,        // code 8
  roundAlreadyFinalized, // code 9
  paymentWindowClosed,   // code 10
  alreadyPaid,           // code 11
  paymentWindowOpen,     // code 12
  participantNotFound,   // code 13
  notYourTurn,           // code 14
  alreadyReceivedPayout, // code 15
  roundNotFinalized,     // code 16
  noCetesToReinvest,     // code 17
  unknown,
}

extension TandaContractErrorMessage on TandaContractError {
  String get userMessage {
    switch (this) {
      case TandaContractError.tandaNotRegistering:
        return 'La tanda ya no acepta nuevos participantes.';
      case TandaContractError.alreadyRegistered:
        return 'Ya estás registrado en esta tanda.';
      case TandaContractError.tandaFull:
        return 'La tanda está llena, no hay lugares disponibles.';
      case TandaContractError.insufficientBalance:
        return 'Saldo insuficiente. Necesitas USDC en tu wallet.';
      case TandaContractError.tandaNotActive:
        return 'La tanda aún no ha comenzado.';
      case TandaContractError.alreadyPaid:
        return 'Ya realizaste tu pago de este mes.';
      case TandaContractError.paymentWindowClosed:
        return 'El periodo de pago ya cerró.';
      case TandaContractError.paymentWindowOpen:
        return 'El periodo de pago aún está abierto.';
      case TandaContractError.notYourTurn:
        return 'Aún no es tu turno de cobrar.';
      case TandaContractError.alreadyReceivedPayout:
        return 'Ya cobraste tu turno en esta tanda.';
      case TandaContractError.roundNotFinalized:
        return 'La ronda aún no ha sido finalizada.';
      case TandaContractError.participantNotFound:
        return 'No se encontró tu registro en la tanda.';
      case TandaContractError.roundAlreadyFinalized:
        return 'La ronda ya fue finalizada.';
      case TandaContractError.noCetesToReinvest:
        return 'No hay CETES disponibles para reinvertir.';
      case TandaContractError.unknown:
        return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }

  static TandaContractError fromCode(int code) {
    const map = {
      4: TandaContractError.tandaNotRegistering,
      5: TandaContractError.alreadyRegistered,
      6: TandaContractError.tandaFull,
      7: TandaContractError.insufficientBalance,
      8: TandaContractError.tandaNotActive,
      9: TandaContractError.roundAlreadyFinalized,
      10: TandaContractError.paymentWindowClosed,
      11: TandaContractError.alreadyPaid,
      12: TandaContractError.paymentWindowOpen,
      13: TandaContractError.participantNotFound,
      14: TandaContractError.notYourTurn,
      15: TandaContractError.alreadyReceivedPayout,
      16: TandaContractError.roundNotFinalized,
      17: TandaContractError.noCetesToReinvest,
    };
    return map[code] ?? TandaContractError.unknown;
  }
}

class TandaException implements Exception {
  final TandaContractError error;
  final String? rawMessage;
  TandaException(this.error, {this.rawMessage});

  @override
  String toString() => error.userMessage;
}
