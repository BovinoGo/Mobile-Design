import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        home: PermissionInitializer(
          child: ConnectivityWrapper(
            child: FutureBuilder<Widget>(
              future: _getInitialPage(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00695C)),
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
