import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;
  bool _loading = false;

  final _slides = const [
    _Slide(
      emoji: '📦',
      title: 'Tu tanda digital',
      subtitle: 'Ahorra con tu grupo de siempre, pero ahora tu dinero no duerme',
    ),
    _Slide(
      emoji: '📈',
      title: 'Tu dinero trabaja',
      subtitle: 'Cada peso que metes genera rendimiento automático basado en CETES',
    ),
    _Slide(
      emoji: '🔒',
      title: '100% seguro',
      subtitle: 'Smart contracts en blockchain. Nadie toca tu dinero, ni siquiera nosotros',
    ),
  ];

  void _next() {
    if (_page < 2) {
      _pc.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    }
  }

  void _connect() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == 2;

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Botón saltar
            if (!isLast)
              Positioned(
                top: 8,
                right: 20,
                child: TextButton(
                  onPressed: () => _pc.jumpToPage(2),
                  child: Text('Saltar', style: bodyText(14, color: softGray)),
                ),
              ),

            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pc,
                    onPageChanged: (p) => setState(() => _page = p),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                  ),
                ),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? accentGold : softGray.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: isLast
                      ? CustomButton(
                          label: 'Conectar Wallet',
                          onPressed: _connect,
                          variant: CustomButtonVariant.primary,
                          loading: _loading,
                          fullWidth: true,
                        )
                      : CustomButton(
                          label: 'Siguiente →',
                          onPressed: _next,
                          variant: CustomButtonVariant.secondary,
                          fullWidth: true,
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(slide.emoji, style: const TextStyle(fontSize: 100)),
          ),
          const SizedBox(height: 36),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 100),
            child: Text(
              slide.title,
              style: titleBold(30),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: Text(
              slide.subtitle,
              style: bodyText(16, color: softGray),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.emoji, required this.title, required this.subtitle});
  final String emoji;
  final String title;
  final String subtitle;
}
