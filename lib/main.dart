import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:visionai/providers/scene_description_provider.dart';
import 'package:visionai/screens/splash_screen.dart';
import 'package:visionai/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC3IDr4Hd2whhFsNOlhjuZ59kASXtEW-lQ",
        authDomain: "vision-ai-f6345.firebaseapp.com",
        projectId: "vision-ai-f6345",
        storageBucket: "vision-ai-f6345.firebasestorage.app",
        messagingSenderId: "335489594965",
        appId: "1:335489594965:web:d1c8700db9dfedb74ec6dc",
        measurementId: "G-E3M7W3KFJV",
      ),
    );
    
    // Configure Firebase Database
    FirebaseDatabase.instance.setPersistenceEnabled(true); // Enable offline persistence
    FirebaseDatabase.instance.ref().keepSynced(true); // Keep the database synced
  } catch (e) {
    print('Error initializing Firebase: $e');
    // You might want to show an error dialog or handle the error appropriately
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SceneDescriptionProvider()),
      ],
      child: MaterialApp(
        title: 'VisionAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          useMaterial3: true,
          colorScheme: lightColorScheme,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Color(0xFF4A4A4A)),
            titleTextStyle: TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          extensions: <ThemeExtension<dynamic>>[
            CustomFonts(
              openDyslexic: const TextStyle(fontFamily: 'OpenDyslexic'),
            ),
          ],
        ),
        darkTheme: AppTheme.darkTheme.copyWith(
          useMaterial3: true,
          colorScheme: darkColorScheme,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Color(0xFFE0E0E0)),
            titleTextStyle: TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          extensions: <ThemeExtension<dynamic>>[
            CustomFonts(
              openDyslexic: const TextStyle(fontFamily: 'OpenDyslexic'),
            ),
          ],
        ),
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}

// Custom ThemeExtension for additional fonts
class CustomFonts extends ThemeExtension<CustomFonts> {
  final TextStyle openDyslexic;

  CustomFonts({
    required this.openDyslexic,
  });

  @override
  ThemeExtension<CustomFonts> copyWith({
    TextStyle? openDyslexic,
  }) {
    return CustomFonts(
      openDyslexic: openDyslexic ?? this.openDyslexic,
    );
  }

  @override
  ThemeExtension<CustomFonts> lerp(ThemeExtension<CustomFonts>? other, double t) {
    if (other is! CustomFonts) {
      return this;
    }
    return CustomFonts(
      openDyslexic: TextStyle.lerp(openDyslexic, other.openDyslexic, t)!,
    );
  }
}
