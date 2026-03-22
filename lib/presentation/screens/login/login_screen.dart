import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../../core/constants/contract_constants.dart';
import '../../../core/prototype_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/accesly_service.dart';
import '../../../injection.dart';

const _bg = Color(0xFF060608);
const _cardColor = Color(0xFF0E0F14);
const _borderColor = Color(0xFF1E1F2A);
const _mint = Color(0xFF0CFFC5);
const _purple = Color(0xFF6C63FF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  String _statusText = '';
  String _activeAction = ''; // 'create', 'import', 'login', 'accesly'
  final _secretController = TextEditingController();
  bool _showLoginField = false;
  bool _hasSavedAccount = false;
  bool _showAcceslyLogin = false;
  late AnimationController _glowController;
  StreamSubscription? _acceslySub;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _checkSavedAccount();

    // Accesly iframe is registered globally in main.dart
  }

  @override
  void dispose() {
    _secretController.dispose();
    _glowController.dispose();
    _acceslySub?.cancel();
    super.dispose();
  }

  void _checkSavedAccount() async {
    final publicKey = await walletRepository.getConnectedPublicKey();
    if (mounted) {
      setState(() => _hasSavedAccount = publicKey != null);
    }
  }

  void _loginExisting() async {
    setState(() {
      _loading = true;
      _activeAction = 'login';
      _statusText = 'Entrando a tu cuenta...';
    });

    try {
      final publicKey = await walletRepository.getConnectedPublicKey();
      if (publicKey != null) {
        walletPublicKeyNotifier.value = publicKey;
        if (mounted) context.go('/hub');
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _statusText = '';
            _activeAction = '';
          });
          _showSnack('No se encontró una cuenta guardada', warningRed);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusText = '';
          _activeAction = '';
        });
      }
    }
  }

  void _createAccount() async {
    setState(() {
      _loading = true;
      _activeAction = 'create';
      _statusText = 'Creando tu cuenta...';
    });

    try {
      final keypair = await walletRepository.generateTestnetKeypair();
      final publicKey = keypair['publicKey']!;
      final secretKey = keypair['secretKey']!;

      setState(() => _statusText = 'Fondeando cuenta en testnet...');
      await walletRepository.fundTestnetAccount(publicKey);

      await walletRepository.saveKeypair(publicKey, secretKey);
      walletPublicKeyNotifier.value = publicKey;

      if (mounted) context.go('/hub');
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusText = '';
          _activeAction = '';
        });
        _showSnack('Hubo un problema, intenta de nuevo', warningRed);
      }
    }
  }

  void _importAccount() async {
    final secret = _secretController.text.trim();
    if (secret.isEmpty) {
      _showSnack('Ingresa tu clave de acceso', warningRed);
      return;
    }

    setState(() {
      _loading = true;
      _activeAction = 'import';
      _statusText = 'Recuperando tu cuenta...';
    });

    try {
      String publicKey;
      if (ContractConstants.useMock) {
        // In mock mode, accept any string as valid credential
        publicKey = 'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W';
      } else {
        // Derive the correct public key from the imported secret key
        final keyPair = KeyPair.fromSecretSeed(secret);
        publicKey = keyPair.accountId;
      }
      await walletRepository.saveKeypair(publicKey, secret);
      walletPublicKeyNotifier.value = publicKey;

      if (mounted) context.go('/hub');
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusText = '';
          _activeAction = '';
        });
        _showSnack('No se pudo recuperar la cuenta', warningRed);
      }
    }
  }

  void _openAcceslyLogin() {
    setState(() {
      _showAcceslyLogin = true;
      _activeAction = 'accesly';
      _statusText = 'Conectando con Accesly...';
    });

    _acceslySub?.cancel();
    _acceslySub = AcceslyService().walletStream.listen((wallet) {
      if (wallet != null && mounted) {
        setState(() {
          _loading = true;
          _statusText = 'Wallet conectada, configurando...';
        });
        _completeAcceslyLogin(wallet);
      }
    });
  }

  void _completeAcceslyLogin(AcceslyWallet wallet) async {
    try {
      walletPublicKeyNotifier.value = wallet.stellarAddress;
      await walletRepository.saveKeypair(wallet.stellarAddress, '');

      if (mounted) {
        setState(() {
          _showAcceslyLogin = false;
          _loading = false;
          _statusText = '';
          _activeAction = '';
        });
        context.go('/hub');
      }
    } catch (e) {
      debugPrint('[Login] Accesly login error: $e');
      if (mounted) {
        setState(() {
          _showAcceslyLogin = false;
          _loading = false;
          _statusText = '';
          _activeAction = '';
        });
        // Still navigate to hub — trustline can be retried later
        context.go('/hub');
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, style: bodyText(13, color: color)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: -60,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) => Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentGold
                          .withValues(alpha: 0.05 * _glowController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) => Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _mint.withValues(
                          alpha: 0.04 * _glowController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // LOGO
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accentGold, Color(0xFFB8892E)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentGold.withValues(alpha: 0.25),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.link_rounded,
                            color: _bg, size: 38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // TITLE
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [offWhite, accentGold],
                      ).createShader(bounds),
                      child: Text(
                        'Rendix',
                        style: titleBold(34, color: offWhite),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Invierte en grupo, gana rendimientos.\nTu dinero seguro en la blockchain.',
                      style: bodyText(15, color: const Color(0xFF6B6D7B)),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // STATUS
                  if (_statusText.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    FadeInUp(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: accentGold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentGold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(_statusText,
                                  style: bodyText(13, color: accentGold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 44),

                  // ── OPTION 1: INICIAR SESIÓN ──
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 150),
                    child: _LoginOption(
                      icon: Icons.login_rounded,
                      title: 'Iniciar sesión',
                      subtitle: _hasSavedAccount
                          ? 'Entra a tu cuenta guardada o usa tu clave'
                          : 'Ingresa con tu clave de acceso',
                      gradientColors: const [_mint, Color(0xFF08B88E)],
                      borderColor: const Color(0xFF0A3D30),
                      loading: _loading && _activeAction == 'login',
                      onTap: _loading
                          ? null
                          : () {
                              if (_hasSavedAccount) {
                                _loginExisting();
                              } else {
                                setState(() => _showLoginField = !_showLoginField);
                              }
                            },
                    ),
                  ),

                  // LOGIN FIELD (enter key to sign in)
                  if (_showLoginField || (_hasSavedAccount && _activeAction != 'login')) ...[
                    if (_showLoginField)
                      ...[
                        const SizedBox(height: 12),
                        FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: _mint.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tu clave de acceso',
                                    style: bodyText(12,
                                        color: const Color(0xFF6B6D7B))),
                                const SizedBox(height: 4),
                                Text(
                                    'Ingresa cualquier texto para acceder.',
                                    style: bodyText(11,
                                        color: const Color(0xFF4A4B55))),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _borderColor),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 2),
                                  child: TextField(
                                    controller: _secretController,
                                    obscureText: true,
                                    style: bodyText(14, color: offWhite),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Pega tu clave aquí...',
                                      hintStyle: bodyText(14,
                                          color: const Color(0xFF3A3C48)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: _loading ? null : _importAccount,
                                  child: Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const LinearGradient(
                                        colors: [_mint, Color(0xFF08B88E)],
                                      ),
                                    ),
                                    child: Center(
                                      child: _loading &&
                                              _activeAction == 'import'
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF060608),
                                              ),
                                            )
                                          : Text('Entrar',
                                              style: bodyText(15,
                                                  color: const Color(0xFF060608),
                                                  weight: FontWeight.w700)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                  ],
                  const SizedBox(height: 14),

                  // ── OPTION 2: CREAR CUENTA ──
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 250),
                    child: _LoginOption(
                      icon: Icons.person_add_rounded,
                      title: 'Crear mi cuenta',
                      subtitle: 'Primera vez aquí? Empieza en segundos',
                      gradientColors: const [
                        Color(0xFFD4A843),
                        Color(0xFFB8892E)
                      ],
                      borderColor: const Color(0xFF3D2E14),
                      loading:
                          _loading && _activeAction == 'create',
                      onTap: _loading ? null : _createAccount,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── OPTION 3: ACCESLY (Google/Apple) ──
                  if (kIsWeb)
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 350),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                    height: 1,
                                    color: _borderColor),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Text('o continua con',
                                    style: bodyText(12,
                                        color:
                                            const Color(0xFF4A4B55))),
                              ),
                              Expanded(
                                child: Container(
                                    height: 1,
                                    color: _borderColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _LoginOption(
                            icon: Icons.security_rounded,
                            title: 'Accesly',
                            subtitle:
                                'Inicia con Google o Apple — wallet automatica',
                            gradientColors: const [
                              _purple,
                              Color(0xFF4E47B8)
                            ],
                            borderColor: const Color(0xFF2A2560),
                            loading: _loading &&
                                _activeAction == 'accesly',
                            onTap:
                                _loading ? null : _openAcceslyLogin,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Accesly iframe overlay (web only)
                  if (_showAcceslyLogin && kIsWeb)
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: _purple.withValues(alpha: 0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            children: [
                              const HtmlElementView(
                                viewType: 'accesly-login-iframe',
                              ),
                              // Close button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    _acceslySub?.cancel();
                                    setState(() {
                                      _showAcceslyLogin = false;
                                      _activeAction = '';
                                      _statusText = '';
                                    });
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _bg.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.close_rounded,
                                        color: offWhite,
                                        size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),

                  // If has saved account, show quick-login hint
                  if (_hasSavedAccount && !_showLoginField)
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 350),
                      child: Center(
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _showLoginField = true),
                          child: Text(
                              '¿Quieres usar otra cuenta? Ingresa tu clave',
                              style: bodyText(12,
                                  color: const Color(0xFF4A4B55))),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // FOOTER
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: Duration(
                        milliseconds: _hasSavedAccount ? 450 : 350),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _mint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('Conectado a Stellar',
                                style: bodyText(11,
                                    color: const Color(0xFF4A4B55))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tu dinero protegido por tecnología blockchain',
                          style: bodyText(11,
                              color: const Color(0xFF3A3C48)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LOGIN OPTION CARD ──────────────────────────────────────────────────────

class _LoginOption extends StatefulWidget {
  const _LoginOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.borderColor,
    this.loading = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color borderColor;
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_LoginOption> createState() => _LoginOptionState();
}

class _LoginOptionState extends State<_LoginOption> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hovering && !disabled
                ? const Color(0xFF14151E)
                : _cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovering && !disabled
                  ? widget.gradientColors[0].withValues(alpha: 0.4)
                  : widget.borderColor,
              width: 1.5,
            ),
            boxShadow: _hovering && !disabled
                ? [
                    BoxShadow(
                      color: widget.gradientColors[0]
                          .withValues(alpha: 0.06),
                      blurRadius: 20,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.gradientColors[0].withValues(alpha: 0.15),
                      widget.gradientColors[1].withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color:
                        widget.gradientColors[0].withValues(alpha: 0.2),
                  ),
                ),
                child: widget.loading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.gradientColors[0],
                        ),
                      )
                    : Icon(widget.icon,
                        color: widget.gradientColors[0], size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: titleSemi(15, color: offWhite)),
                    const SizedBox(height: 3),
                    Text(widget.subtitle,
                        style: bodyText(12,
                            color: const Color(0xFF6B6D7B))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  color: widget.gradientColors[0].withValues(alpha: 0.6),
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
