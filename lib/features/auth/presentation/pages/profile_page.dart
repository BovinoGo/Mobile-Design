import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/auth/presentation/pages/welcome_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _green = Color(0xFF00695C);

  Map<String, String> _info = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await TokenService.instance.getUserInfo();
    if (mounted) {
      setState(() {
        _info = {
          'fullName': raw['fullName']?.toString() ?? '',
          'email': raw['email']?.toString() ?? '',
          'accountType': raw['accountType']?.toString() ?? '',
          'role': raw['role']?.toString() ?? '',
          'userId': raw['userId']?.toString() ?? '',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión'),
        content: const Text(
            '¿Seguro que deseas cerrar sesión? Tendrás que volver a iniciar sesión.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TokenService.instance.clearUserSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
        (route) => false,
      );
    }
  }

  String _accountTypeLabel(String type) {
    switch (type) {
      case 'LivestockCompany':
        return 'Empresa Ganadera';
      case 'IndependentRancher':
        return 'Ganadero Independiente';
      case 'BuyerCustomer':
        return 'Comprador';
      case 'PlatformAccount':
        return 'Administrador de Plataforma';
      default:
        return type.isEmpty ? '—' : type;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'CompanyAdmin':
        return 'Administrador de Empresa';
      case 'CompanyWorker':
        return 'Trabajador';
      case 'IndependentRancher':
        return 'Ganadero';
      case 'BuyerCustomer':
        return 'Comprador';
      case 'PlatformAdmin':
        return 'Admin de Plataforma';
      default:
        return role.isEmpty ? '—' : role;
    }
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : CustomScrollView(
              slivers: [
                // App bar with avatar
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: _green,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_green, Color(0xFF00897B)],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Avatar
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.25),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 2.5),
                            ),
                            child: Center(
                              child: Text(
                                _initials(_info['fullName'] ?? ''),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _info['fullName'] ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _accountTypeLabel(_info['accountType'] ?? ''),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _infoCard('Información de cuenta', [
                          _infoRow(Icons.person_outline, 'Nombre completo',
                              _info['fullName'] ?? '—'),
                          _infoRow(Icons.email_outlined, 'Email',
                              _info['email'] ?? '—'),
                          _infoRow(Icons.business_outlined, 'Tipo de cuenta',
                              _accountTypeLabel(_info['accountType'] ?? '')),
                          _infoRow(Icons.badge_outlined, 'Rol',
                              _roleLabel(_info['role'] ?? '')),
                        ]),
                        const SizedBox(height: 12),
                        _infoCard('Identificador', [
                          _copyRow(Icons.fingerprint, 'User ID',
                              _info['userId'] ?? '—'),
                        ]),
                        const SizedBox(height: 24),
                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text(
                              'Cerrar Sesión',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _green,
                  letterSpacing: 0.3)),
          const Divider(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value.length > 20
                      ? '${value.substring(0, 8)}...${value.substring(value.length - 8)}'
                      : value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18, color: _green),
            tooltip: 'Copiar',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID copiado al portapapeles'),
                  backgroundColor: _green,
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
