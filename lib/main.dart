import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:manage_intern/providers/auth_provider.dart';
import 'package:manage_intern/providers/intern_provider.dart';
import 'package:manage_intern/screens/auth/login_screen.dart';
import 'package:manage_intern/screens/interns/intern_list_screen.dart';
import 'package:manage_intern/screens/profile/profile_screen.dart';
import 'package:manage_intern/screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InternProvider()),
      ],
      child: MaterialApp(
        title: 'Manage Intern',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          "/": (context) => const SplashScreen(),
          "/login": (context) => const LoginScreen(),
          "/profile": (context) => const ProfileScreen(),
          "/interns": (context) => const InternListScreen(),
        },
      ),
    );
  }
}
