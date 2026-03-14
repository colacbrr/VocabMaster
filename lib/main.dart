// lib/main.dart - WITH HIVE USER PROFILES
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_config.dart';
import 'services/hive_service.dart';
import 'widgets/local_auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive
    await HiveService.initHive();
    debugPrint('Hive initialized successfully');
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      home: const LocalAuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
