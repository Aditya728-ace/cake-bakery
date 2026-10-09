import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth_state.dart';
import 'core/nav.dart';
import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthState();
  await auth.init();
  runApp(ChangeNotifierProvider<AuthState>.value(value: auth, child: const BakeryAdminApp()));
}

class BakeryAdminApp extends StatelessWidget {
  const BakeryAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bakery Studio',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildTheme(),
      home: Consumer<AuthState>(
        builder: (context, auth, _) => auth.loggedIn ? const HomeShell() : const LoginScreen(),
      ),
    );
  }
}
