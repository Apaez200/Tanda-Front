import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/accesly_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  // Register Accesly iframe globally (web only)
  if (kIsWeb) {
    AcceslyService().registerViewFactory();
  }

  runApp(const TandaChainApp());
}

class TandaChainApp extends StatelessWidget {
  const TandaChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TandaChain',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
      builder: (context, child) {
        // Wrap the app with a persistent Accesly iframe (hidden, always alive)
        if (kIsWeb) {
          return Stack(
            children: [
              child!,
              // Hidden iframe that persists across navigation
              const Positioned(
                left: -9999,
                top: -9999,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: HtmlElementView(viewType: 'accesly-login-iframe'),
                ),
              ),
            ],
          );
        }
        return child!;
      },
    );
  }
}
