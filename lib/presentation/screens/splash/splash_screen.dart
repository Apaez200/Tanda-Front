import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/prototype_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../injection.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fillCtrl;
  late Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _fillAnim = CurvedAnimation(parent: _fillCtrl, curve: Curves.easeInOut);

    Timer(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
      final publicKey = await walletRepository.getConnectedPublicKey();
      if (!mounted) return;
      if (publicKey != null) {
        walletPublicKeyNotifier.value = publicKey;
        context.go('/hub');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Alcancía animada
              FadeIn(
                duration: const Duration(milliseconds: 800),
                child: AnimatedBuilder(
                  animation: _fillAnim,
                  builder: (_, __) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: accentGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: accentGold.withOpacity(0.3),
                            blurRadius: 24,
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: [0, _fillAnim.value, _fillAnim.value],
                          colors: [
                            primaryGreen.withOpacity(0.85),
                            primaryGreen.withOpacity(0.85),
                            cardBg,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: offWhite,
                        size: 56,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              SlideInUp(
                duration: const Duration(milliseconds: 700),
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Rendix',
                  style: titleBold(36, color: accentGold),
                ),
              ),
              const SizedBox(height: 10),
              SlideInUp(
                duration: const Duration(milliseconds: 700),
                delay: const Duration(milliseconds: 500),
                child: Text(
                  'Tu dinero, pero con superpoderes',
                  style: bodyText(15, color: softGray),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
