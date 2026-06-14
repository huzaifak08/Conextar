import 'package:conextar/constants/theme.dart';
import 'package:conextar/providers/app_provider_container.dart';
import 'package:conextar/sockets/init.dart';
import 'package:conextar/views/splash/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap the socket system background connection tunnel
  await SocketService().init();

  runApp(
    ProviderScope(
      child: UncontrolledProviderScope(
        container: AppProviderContainer.instance,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Conextar',
      theme: ContextarTheme.buildThemeData(context),
      home: const SplashView(),
    );
  }
}

// dart run build_runner watch --delete-conflicting-outputs
// dart run build_runner build --delete-conflicting-outputs
