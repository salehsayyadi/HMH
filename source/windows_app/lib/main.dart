import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/colors.dart';
import 'core/services/api_service.dart';
import 'models/user.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void maximizeAppWindow() {
  if (!Platform.isWindows) return;
  try {
    final user32 = DynamicLibrary.open('user32.dll');
    final getForegroundWindow = user32.lookupFunction<
        IntPtr Function(),
        int Function()>('GetForegroundWindow');
    final showWindow = user32.lookupFunction<
        Int32 Function(IntPtr, Int32),
        int Function(int, int)>('ShowWindow');

    final hwnd = getForegroundWindow();
    if (hwnd != 0) {
      showWindow(hwnd, 3); // SW_MAXIMIZE = 3
    }
  } catch (_) {}
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  maximizeAppWindow();
  await ApiService.init();
  runApp(const HMHApp());
}

class HMHApp extends StatelessWidget {
  const HMHApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سامانه رزرو آمفی‌تئاتر مدارس امام حسین (ع)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Vazirmatn',
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.mainBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.secondaryGreen,
          background: AppColors.mainBackground,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
      locale: const Locale('fa', 'IR'),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.10,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      maximizeAppWindow();
      Future.delayed(const Duration(milliseconds: 200), maximizeAppWindow);
      Future.delayed(const Duration(milliseconds: 600), maximizeAppWindow);
    });
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Smooth, instant transition without annoying freezing
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final token = await ApiService.getToken().timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (token == null || token.isEmpty || token.startsWith('offline_')) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final res = await ApiService.getMe().timeout(const Duration(seconds: 8));
      final user = UserModel.fromJson(res);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(currentUser: user)),
      );
    } catch (_) {
      await ApiService.clearTokens();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
            ),
            SizedBox(height: 18),
            Text(
              'سامانه رزرو آمفی‌تئاتر مدارس امام حسین (ع) یزد',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.darkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
