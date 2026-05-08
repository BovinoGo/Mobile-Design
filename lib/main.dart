import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/core/themes/color_palette.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/core/services/notification_service.dart';
import 'package:vacapp/core/services/sync_service.dart';
import 'package:vacapp/core/widgets/connectivity_wrapper.dart';
import 'package:vacapp/core/widgets/permission_initializer.dart';
import 'package:vacapp/features/app/presentation/pages/main_view.dart';
import 'package:vacapp/features/auth/data/datasources/auth_service.dart';
import 'package:vacapp/features/auth/data/repositories/auth_repository.dart';
import 'package:vacapp/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:vacapp/features/auth/presentation/pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await _initializeServices();
  runApp(const MainApp());
}

Future<void> _initializeServices() async {
  try {
    await NotificationService().initialize();
    await SyncService().initialize();
  } catch (e) {
    // Non-fatal — app continues
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<Widget> _getInitialPage() async {
    final hasToken = await TokenService.instance.hasValidToken();
    final hasOffline = await TokenService.instance.hasOfflineData();
    if (hasToken || hasOffline) return const MainView();
    return const WelcomePage();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: AuthRepository(AuthService()),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: ColorPalette.primaryColor,
            secondary: ColorPalette.accentColor,
            surface: ColorPalette.secondaryColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: ColorPalette.backgroundDark,
          ),
          scaffoldBackgroundColor: ColorPalette.secondaryColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: ColorPalette.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: ColorPalette.primaryColor,
          ),
        ),
        home: PermissionInitializer(
          child: ConnectivityWrapper(
            child: FutureBuilder<Widget>(
              future: _getInitialPage(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  final titleStyle = GoogleFonts.cormorantGaramond(
                    fontSize: 48,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                    color: ColorPalette.primaryColor,
                    height: 0.95,
                  );
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('VacApp', style: titleStyle),
                          const SizedBox(height: 18),
                          const CircularProgressIndicator(color: ColorPalette.primaryColor),
                        ],
                      ),
                    ),
                  );
                }
                return snapshot.data ?? const WelcomePage();
              },
            ),
          ),
        ),
      ),
    );
  }
}
