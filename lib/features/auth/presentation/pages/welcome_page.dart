import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _exitController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _exitSlideAnimation;
  late Animation<double> _exitFadeAnimation;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Entry animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Exit animations
    _exitSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.0),
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInCubic,
    ));

    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeIn,
    ));

    // Start entry animations with safety checks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // Animate exit and then navigate
  void _animateToPage(Widget page) {
    setState(() {
      _isExiting = true;
    });
    
    _exitController.forward().then((_) {
      if (mounted) {
        Navigator.of(context).push(_createRoute(page));
      }
    });
  }

  // Custom page transition with entry animations for destination
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 1000),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFF00695C),
      body: SafeArea(
        child: Stack(
          children: [
            // Parte superior con fondo verde y contenido central
            Column(
              children: [
                // VacApp título en la parte superior - con fade animation
                FadeTransition(
                  opacity: _isExiting ? _exitFadeAnimation : _fadeAnimation,
                  child: SlideTransition(
                    position: _isExiting 
                        ? Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.5)).animate(_exitController)
                        : const AlwaysStoppedAnimation(Offset.zero),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 20),
                      child: const Text(
                        "VacApp",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: size.height * 0.05),
                        
                        // Mascot image with animations
                        FadeTransition(
                          opacity: _isExiting ? _exitFadeAnimation : _fadeAnimation,
                          child: SlideTransition(
                            position: _isExiting 
                                ? Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.3)).animate(_exitController)
                                : const AlwaysStoppedAnimation(Offset.zero),
                            child: ScaleTransition(
                              scale: _isExiting ? const AlwaysStoppedAnimation(1.0) : _scaleAnimation,
                              child: Image.asset(
                                'assets/images/welcome.png',
                                height: size.height * 0.25,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Welcome text with animations
                        FadeTransition(
                          opacity: _isExiting ? _exitFadeAnimation : _fadeAnimation,
                          child: SlideTransition(
                            position: _isExiting 
                                ? Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.2)).animate(_exitController)
                                : const AlwaysStoppedAnimation(Offset.zero),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                "¡Hola! Soy Vicky, tu asistente vacuna \n\nTe ayudaré a llevar el control de tus bovinos de forma fácil y segura, ¡desde donde estés!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Parte inferior flotante con fondo blanco y botones - con slide animation
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _isExiting ? _exitSlideAnimation : _slideAnimation,
                child: FadeTransition(
                  opacity: _isExiting ? _exitFadeAnimation : _fadeAnimation,
                  child: Center(
                    child: Container(
                      width: size.width * 0.88,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón Iniciar Sesión
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00695C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isExiting ? null : () {
                                _animateToPage(const LoginPage());
                              },
                              child: const Text(
                                "Iniciar Sesión",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Botón Crear Cuenta
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF00695C),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isExiting ? null : () {
                                _animateToPage(const RegisterPage());
                              },
                              child: const Text(
                                "Crear Cuenta",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00695C),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}