import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/resource_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/calendar_provider.dart';

import 'views/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => ResourceProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => ReservationProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => CalendarProvider(),
        ),

      ],
      child: MaterialApp(
        title: 'ResaPro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.interTextTheme(),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}