import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/irrigation_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IrigasiBawangApp());
}

class IrigasiBawangApp extends StatelessWidget {
  const IrigasiBawangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IrrigationProvider()),
      ],
      child: MaterialApp(
        title: 'Irigasi Bawang',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          primaryColor: const Color(0xFF047857),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF047857),
            secondary: Color(0xFF0288D1),
            surface: Colors.white,
            error: Color(0xFFDC2626),
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
          useMaterial3: true,
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
