import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import 'login_page.dart';

enum _AccountRole { company, rancher, buyer }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  static const _green = Color(0xFF00695C);

  // Step 1: role selection; Step 2: form
  int _step = 0;
  _AccountRole? _selectedRole;

  bool _isVisible = false;
  bool _agreeToTerms = false;

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
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
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validateForm() {
    if (_fullNameCtrl.text.trim().isEmpty) return 'El nombre completo es obligatorio';
    if (_fullNameCtrl.text.trim().length < 3) return 'El nombre debe tener al menos 3 caracteres';
    if (_emailCtrl.text.trim().isEmpty) return 'El email es obligatorio';
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailCtrl.text.trim())) {
      return 'Ingresa un email válido';
    }
    if (_passwordCtrl.text.trim().isEmpty) return 'La contraseña es obligatoria';
    if (_passwordCtrl.text.trim().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  void _submit() {
    final error = _validateForm();
    if (error != null) {
      _showDialog(error, isError: true);
      return;
    }
    final fullName = _fullNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();

    switch (_selectedRole!) {
      case _AccountRole.company:
        BlocProvider.of<AuthBloc>(context).add(RegisterCompanyEvent(
            fullName: fullName, email: email, password: password, phone: phone));
        break;
      case _AccountRole.rancher:
        BlocProvider.of<AuthBloc>(context).add(RegisterRancherEvent(
            fullName: fullName, email: email, password: password, phone: phone));
        break;
      case _AccountRole.buyer:
        BlocProvider.of<AuthBloc>(context).add(RegisterBuyerEvent(
            fullName: fullName, email: email, password: password, phone: phone));
        break;
    }
  }

  void _showDialog(String message, {required bool isError}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isError
                        ? [Colors.red.shade400, Colors.red.shade700]
                        : [Colors.green.shade400, Colors.green.shade700],
                  ),
                ),
                child: Icon(
                  isError ? Icons.close_rounded : Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isError ? '¡Algo salió mal!' : '¡Registro exitoso!',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isError ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isError ? Colors.red.shade200 : Colors.green.shade200),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                      fontSize: 15,
                      color: isError ? Colors.red.shade800 : Colors.green.shade800),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (!isError) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isError ? 'Entendido' : 'Iniciar Sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _green,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Hero(
                    tag: 'register_image',
                    child: Image.asset('assets/images/register.png', height: 120),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is SuccessRegisterState) {
                          _showDialog(
                            'Tu cuenta ha sido creada correctamente. Inicia sesión para continuar.',
                            isError: false,
                          );
                        }
                        if (state is FailureState) {
                          _showDialog(
                            state.errorMessage.replaceAll('Exception: ', ''),
                            isError: true,
                          );
                        }
                      },
                      builder: (context, state) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: _step == 0
                              ? _buildRoleSelection()
                              : _buildForm(state),
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

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crear tu Cuenta',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: _green),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecciona el tipo de cuenta que deseas crear',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 28),
        _roleCard(
          role: _AccountRole.company,
          icon: Icons.business_outlined,
          title: 'Empresa Ganadera',
          subtitle: 'Gestiona múltiples ranchos, trabajadores y publicaciones',
        ),
        const SizedBox(height: 16),
        _roleCard(
          role: _AccountRole.rancher,
          icon: Icons.agriculture_outlined,
          title: 'Ganadero Independiente',
          subtitle: 'Administra tu rancho y bovinos de forma individual',
        ),
        const SizedBox(height: 16),
        _roleCard(
          role: _AccountRole.buyer,
          icon: Icons.shopping_cart_outlined,
          title: 'Comprador',
          subtitle: 'Explora el mercado y realiza compras de bovinos',
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedRole != null ? _green : Colors.grey.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _selectedRole == null
                ? null
                : () => setState(() => _step = 1),
            child: Text(
              'Continuar',
              style: TextStyle(
                color: _selectedRole != null ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿Ya tienes una cuenta? ',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginPage())),
              child: const Text('Iniciar Sesión',
                  style: TextStyle(
                      color: _green, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }

  Widget _roleCard({
    required _AccountRole role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _green.withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _green : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? _green : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? _green : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _green, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AuthState state) {
    final roleLabel = _selectedRole == _AccountRole.company
        ? 'Empresa Ganadera'
        : _selectedRole == _AccountRole.rancher
            ? 'Ganadero Independiente'
            : 'Comprador';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _step = 0),
              child: const Icon(Icons.arrow_back_ios, color: _green, size: 20),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(roleLabel,
                  style: const TextStyle(
                      color: _green, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Completa tu Registro',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: _green)),
        const SizedBox(height: 6),
        const Text('Rellena los datos de tu cuenta',
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 28),
        _input(controller: _fullNameCtrl, hint: 'Nombre completo', icon: Icons.person_outline),
        const SizedBox(height: 16),
        _input(
            controller: _emailCtrl,
            hint: 'Correo electrónico',
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _input(
            controller: _phoneCtrl,
            hint: 'Teléfono (opcional)',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone),
        const SizedBox(height: 16),
        _input(
          controller: _passwordCtrl,
          hint: 'Contraseña',
          icon: Icons.lock_outline,
          obscure: !_isVisible,
          suffix: IconButton(
            icon: Icon(_isVisible ? Icons.visibility : Icons.visibility_off,
                color: _green),
            onPressed: () => setState(() => _isVisible = !_isVisible),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreeToTerms,
              activeColor: _green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: const TextSpan(
                    text: 'Acepto los ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(
                          text: 'Términos & Condiciones',
                          style: TextStyle(
                              color: _green, fontWeight: FontWeight.bold)),
                      TextSpan(text: ' y la '),
                      TextSpan(
                          text: 'Política de Privacidad',
                          style: TextStyle(
                              color: _green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _agreeToTerms ? _green : Colors.grey.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (state is LoadingAuthState || !_agreeToTerms) ? null : _submit,
            child: state is LoadingAuthState
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      color: _agreeToTerms ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿Ya tienes una cuenta? ',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginPage())),
              child: const Text('Iniciar Sesión',
                  style: TextStyle(
                      color: _green, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      cursorColor: _green,
      style: const TextStyle(
          fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _green),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: TextStyle(
            fontWeight: FontWeight.w400, fontSize: 15, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green),
        ),
      ),
    );
  }
}
