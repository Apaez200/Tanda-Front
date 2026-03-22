import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/claim/claim_screen.dart';
import '../../presentation/screens/create/create_tanda_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/deposit/deposit_screen.dart';
import '../../presentation/screens/exit/exit_screen.dart';
import '../../presentation/screens/frozen/frozen_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/hub/tanda_hub_screen.dart';
import '../../presentation/screens/portfolio/portfolio_screen.dart';
import '../../presentation/screens/join/join_tanda_screen.dart';
import '../../presentation/screens/my_tandas/my_tandas_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/login/login_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (ctx, state) => _fade(const SplashScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (ctx, state) => _fade(const LoginScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (ctx, state) => _fade(const OnboardingScreen()),
    ),
    GoRoute(
      path: '/hub',
      pageBuilder: (ctx, state) => _fade(const TandaHubScreen()),
    ),
    GoRoute(
      path: '/create-tanda',
      pageBuilder: (ctx, state) => _slideUp(const CreateTandaScreen()),
    ),
    GoRoute(
      path: '/join-tanda',
      pageBuilder: (ctx, state) => _slideUp(const JoinTandaScreen()),
    ),
    GoRoute(
      path: '/my-tandas',
      pageBuilder: (ctx, state) => _fade(const MyTandasScreen()),
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
    GoRoute(
      path: '/portfolio',
      pageBuilder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return _slideUp(PortfolioScreen(
          balance: (extra['balance'] as num?)?.toDouble() ?? 0,
          activeTandas: (extra['activeTandas'] as int?) ?? 0,
          completedTandas: (extra['completedTandas'] as int?) ?? 0,
        ));
      },
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
