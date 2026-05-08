import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vacapp/core/themes/color_palette.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/app/presentation/pages/main_view.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool _isVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeController =
        AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveSession(dynamic user) async {
    await TokenService.instance.saveUserSession(
      user.token,
      user.fullName,
      userId: user.userId,
      email: user.email,
      fullName: user.fullName,
      accountType: user.accountType,
      role: user.role,
    );
  }

  Route _verticalRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: ColorPalette.primaryColor,
      height: 1.1,
      letterSpacing: 0.2,
    );
    final subtitleStyle = GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.grey.shade600,
      height: 1.35,
    );
    final primaryButtonStyle = GoogleFonts.plusJakartaSans(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 16,
      letterSpacing: 0.2,
    );
    final helperTextStyle = GoogleFonts.dmSans(
      color: Colors.grey.shade600,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final actionTextStyle = GoogleFonts.plusJakartaSans(
      color: ColorPalette.primaryColor,
      fontWeight: FontWeight.w700,
      fontSize: 14,
    );

    return Scaffold(
      backgroundColor: ColorPalette.primaryColor,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'login_image',
                      child: Image.asset('assets/images/login.png',
                          height: 160, fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is SuccessLoginState) {
                          _saveSession(state.user).then((_) {
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const MainView()),
                              );
                            }
                          });
                        }
                        if (state is FailureState) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.errorMessage
                                  .replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                '¡Bienvenido de nuevo!',
                                style: titleStyle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ingresa tus credenciales para continuar',
                                style: subtitleStyle,
                              ),
                              const SizedBox(height: 30),
                              _inputField(
                                controller: _emailController,
                                hint: 'Correo electrónico',
                                icon: Icons.email_outlined,
                                obscure: false,
                                isPassword: false,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              _inputField(
                                controller: _passwordController,
                                hint: 'Contraseña',
                                icon: Icons.lock_outline,
                                obscure: !_isVisible,
                                isPassword: true,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorPalette.primaryColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  onPressed: state is LoadingAuthState
                                      ? null
                                      : () {
                                          BlocProvider.of<AuthBloc>(context).add(
                                            LoginEvent(
                                              email: _emailController.text.trim(),
                                              password: _passwordController.text.trim(),
                                            ),
                                          );
                                        },
                                  child: state is LoadingAuthState
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                        : Text(
                                          'Iniciar Sesión',
                                            style: primaryButtonStyle.copyWith(
                                              color: Colors.white,
                                            ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¿No tienes cuenta? ',
                                    style: helperTextStyle.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pushReplacement(
                                        _verticalRoute(const RegisterPage())),
                                    child: Text(
                                      'Regístrate',
                                      style: actionTextStyle.copyWith(
                                        color: ColorPalette.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).padding.bottom + 20),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required bool isPassword,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      cursorColor: ColorPalette.primaryColor,
      style: GoogleFonts.dmSans(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: ColorPalette.primaryColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _isVisible ? Icons.visibility : Icons.visibility_off,
                  color: ColorPalette.primaryColor),
                onPressed: () => setState(() => _isVisible = !_isVisible),
              )
            : null,
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.primaryColor),
        ),
      ),
    );
  }
}
