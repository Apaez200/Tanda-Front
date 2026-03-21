import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/claim/claim_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/deposit/deposit_screen.dart';
import '../../presentation/screens/exit/exit_screen.dart';
import '../../presentation/screens/frozen/frozen_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (ctx, state) => _fade(const SplashScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (ctx, state) => _fade(const OnboardingScreen()),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (ctx, state) => _fade(const DashboardScreen()),
    ),
    GoRoute(
      path: '/deposit',
      pageBuilder: (ctx, state) => _slideUp(const DepositScreen()),
    ),
    GoRoute(
      path: '/claim',
      pageBuilder: (ctx, state) => _slideUp(const ClaimScreen()),
    ),
    GoRoute(
      path: '/frozen',
      pageBuilder: (ctx, state) => _fade(const FrozenScreen()),
    ),
    GoRoute(
      path: '/exit',
      pageBuilder: (ctx, state) => _slideUp(const ExitScreen()),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (ctx, state) => _fade(const HistoryScreen()),
    ),
  ],
);

CustomTransitionPage<void> _fade(Widget child) => CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (ctx, anim, _, c) =>
          FadeTransition(opacity: anim, child: c),
      transitionDuration: const Duration(milliseconds: 350),
    );

CustomTransitionPage<void> _slideUp(Widget child) =>
    CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (ctx, anim, _, c) {
        final tween = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(position: anim.drive(tween), child: c);
      },
      transitionDuration: const Duration(milliseconds: 420),
    );
