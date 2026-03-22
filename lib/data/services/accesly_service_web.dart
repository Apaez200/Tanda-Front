import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';

/// Accesly App ID
const _acceslyAppId = String.fromEnvironment(
  'ACCESLY_APP_ID',
  defaultValue: 'acc_d3480b81eb11e101f8709561',
);

/// Channel name shared between Flutter and the Accesly iframe.
const _channelName = 'accesly-tanda-sign';

/// Service that manages the Accesly login iframe, wallet connection, and TX signing.
///
/// Communication architecture:
/// - Connection events (connect/disconnect): iframe → parent via window.parent.postMessage
/// - Sign requests/responses: BroadcastChannel (bypasses contentWindow entirely)
class AcceslyService {
  static final AcceslyService _instance = AcceslyService._internal();
  factory AcceslyService() => _instance;
  AcceslyService._internal();

  final _walletController = StreamController<AcceslyWallet?>.broadcast();
  Stream<AcceslyWallet?> get walletStream => _walletController.stream;

  AcceslyWallet? _currentWallet;
  AcceslyWallet? get currentWallet => _currentWallet;
  bool get isConnected => _currentWallet != null;

  bool _isRegistered = false;
  int _requestCounter = 0;
  final _pendingSignRequests = <String, Completer<AcceslySignResult>>{};

  html.BroadcastChannel? _signChannel;

  void registerViewFactory() {
    if (_isRegistered) return;
    _isRegistered = true;

    // BroadcastChannel for sign request/response (works across same-origin contexts)
    _signChannel = html.BroadcastChannel(_channelName);
    _signChannel!.onMessage.listen((html.MessageEvent event) {
      final data = event.data;
      if (data is Map) {
        _handleSignResponse(Map<String, dynamic>.from(data));
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      'accesly-login-iframe',
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'accesly_login.html?appId=$_acceslyAppId'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'popup; popups';
        return iframe;
      },
    );

    // Connection events still come via window.postMessage (from iframe's window.parent.postMessage)
    html.window.addEventListener('message', (html.Event event) {
      final msgEvent = event as html.MessageEvent;
      final data = msgEvent.data;
      if (data is Map) {
        _handleConnectionEvent(Map<String, dynamic>.from(data));
      }
    });
  }

  void _handleConnectionEvent(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'accesly_connected':
        _currentWallet = AcceslyWallet(
          stellarAddress: data['stellarAddress'] as String,
          email: data['email'] as String? ?? '',
        );
        _walletController.add(_currentWallet);
        debugPrint('[Accesly] Connected: ${_currentWallet!.stellarAddress}');
        break;

      case 'accesly_disconnected':
        _currentWallet = null;
        _walletController.add(null);
        debugPrint('[Accesly] Disconnected');
        break;
    }
  }

  void _handleSignResponse(Map<String, dynamic> data) {
    if (data['type'] != 'sign_result') return;

    final requestId = data['requestId'] as String? ?? '';
    final completer = _pendingSignRequests.remove(requestId);
    if (completer == null) {
      debugPrint('[Accesly] No pending request for $requestId');
      return;
    }

    final success = data['success'] as bool? ?? false;
    debugPrint('[Accesly] sign_result: requestId=$requestId success=$success');

    if (success) {
      completer.complete(AcceslySignResult(
        signedXdr: data['signedXdr'] as String? ?? '',
        txHash: data['txHash'] as String? ?? '',
      ));
    } else {
      completer.completeError(
        Exception(data['error'] as String? ?? 'Firma rechazada por Accesly'),
      );
    }
  }

  /// Sign and submit a transaction XDR via Accesly's TEE-based signing.
  Future<AcceslySignResult> signAndSubmit(String unsignedXdr) async {
    return _requestSign(unsignedXdr, submit: true);
  }

  /// Sign a transaction without submitting (returns signed XDR).
  Future<AcceslySignResult> signTransaction(String unsignedXdr) async {
    return _requestSign(unsignedXdr, submit: false);
  }

  Future<AcceslySignResult> _requestSign(String xdr, {required bool submit}) async {
    if (_currentWallet == null) {
      throw Exception('No hay wallet Accesly conectada');
    }
    if (_signChannel == null) {
      throw Exception('BroadcastChannel no inicializado');
    }

    final requestId = 'req_${++_requestCounter}_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<AcceslySignResult>();
    _pendingSignRequests[requestId] = completer;

    final msgType = submit ? 'sign_and_submit' : 'sign_transaction';
    debugPrint('[Accesly] Sending $msgType via BroadcastChannel, requestId=$requestId');

    _signChannel!.postMessage({
      'type': msgType,
      'xdr': xdr,
      'requestId': requestId,
    });

    return completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        _pendingSignRequests.remove(requestId);
        throw Exception(
          'Timeout: Accesly no respondió en 90s. '
          'Verifica que el popup de firma no esté bloqueado.',
        );
      },
    );
  }

  void dispose() {
    _signChannel?.close();
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
