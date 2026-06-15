// lib/screens/auth/login_screen.dart
// ignore_for_file: unused_field, avoid_print, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../dashboard/dashboard_screen.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _pinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _identifierController = TextEditingController();
  bool _isLoading = false;
  bool _showAdvancedOptions = false;
  bool _obscurePin = true;
  bool _rememberMe = true;
  
  String _selectedCountryCode = '+221';
  final List<Map<String, String>> _countryCodes = [
    {'code': '+221', 'flag': '🇸🇳', 'name': 'Sénégal'},
    {'code': '+223', 'flag': '🇲🇱', 'name': 'Mali'},
    {'code': '+224', 'flag': '🇬🇳', 'name': 'Guinée'},
    {'code': '+222', 'flag': '🇲🇷', 'name': 'Mauritanie'},
    {'code': '+225', 'flag': '🇨🇮', 'name': 'Côte d\'Ivoire'},
    {'code': '+226', 'flag': '🇧🇫', 'name': 'Burkina Faso'},
    {'code': '+227', 'flag': '🇳🇪', 'name': 'Niger'},
    {'code': '+228', 'flag': '🇹🇬', 'name': 'Togo'},
    {'code': '+229', 'flag': '🇧🇯', 'name': 'Bénin'},
    {'code': '+220', 'flag': '🇬🇲', 'name': 'Gambie'},
    {'code': '+245', 'flag': '🇬🇼', 'name': 'Guinée-Bissau'},
    {'code': '+238', 'flag': '🇨🇻', 'name': 'Cap-Vert'},
    {'code': '+240', 'flag': '🇬🇶', 'name': 'Guinée équatoriale'},
    {'code': '+241', 'flag': '🇬🇦', 'name': 'Gabon'},
    {'code': '+242', 'flag': '🇨🇬', 'name': 'Congo'},
    {'code': '+243', 'flag': '🇨🇩', 'name': 'RDC'},
    {'code': '+244', 'flag': '🇦🇴', 'name': 'Angola'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA/Canada'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _phoneController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('saved_phone');
    final savedCountryCode = prefs.getString('saved_country_code');
    final rememberMe = prefs.getBool('remember_me') ?? true;
    
    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
        if (savedCountryCode != null) {
          _selectedCountryCode = savedCountryCode;
        }
        if (rememberMe && savedPhone != null && savedPhone.isNotEmpty) {
          _phoneController.text = savedPhone;
        }
      });
    }
  }

  Future<void> _savePhoneNumber(String phoneNumber) async {
    if (!_rememberMe) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_phone', phoneNumber);
    await prefs.setString('saved_country_code', _selectedCountryCode);
    await prefs.setBool('remember_me', _rememberMe);
  }

  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
    if (mounted) {
      setState(() {
        _rememberMe = value;
      });
    }
    if (!value) {
      await prefs.remove('saved_phone');
    }
  }

  String _getFullPhoneNumber() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) return '';
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return '$_selectedCountryCode$cleanNumber';
  }

  Future<void> _loginWithPin() async {
    final phoneNumber = _getFullPhoneNumber();
    final pin = _pinController.text.trim();
    
    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer votre numéro de téléphone'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    if (pin.isEmpty || pin.length != 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer un code PIN valide (6 chiffres)'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final result = await ref.read(authProvider.notifier).loginWithPin(
        pin,
        phoneNumber,
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      if (result['success'] == true) {
        debugPrint('✅ Connexion PIN réussie, redirection vers Dashboard...');
        
        if (mounted) {
          // ✅ REDIRECTION VERS LE DASHBOARD
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Numéro ou PIN incorrect'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        _pinController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        _pinController.clear();
      }
    }
  }

  Future<void> _sendOtp() async {
    final email = _identifierController.text.trim();
    
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer votre email'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    if (!email.contains('@')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email invalide'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final result = await ref.read(authProvider.notifier).sendOtp(
        identifier: email,
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      if (result['success'] == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              userId: result['userId'].toString(),
              identifier: email,
              isLogin: true,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Erreur lors de l\'envoi'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleAdvancedOptions() {
    if (mounted) {
      setState(() {
        _showAdvancedOptions = !_showAdvancedOptions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Écouter les changements d'état pour rediriger automatiquement
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        debugPrint('🔄 AuthState changé, redirection vers Dashboard...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B6E3A), Color(0xFF168A48)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B6E3A).withAlpha(50),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_shipping, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              
              // Titre
              const Center(
                child: Text(
                  'PRO COLIS',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A2B3C)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Transport de colis interurbain',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 48),
              
              // Connexion Rapide
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B6E3A).withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.phone_android, size: 24, color: Color(0xFF0B6E3A)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Connexion Rapide',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2B3C)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous avec votre numéro et votre code PIN',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    
                    // Champ téléphone
                    const Text(
                      'Numéro de téléphone',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A2B3C)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              items: _countryCodes.map((country) {
                                return DropdownMenuItem<String>(
                                  value: country['code'],
                                  child: Row(
                                    children: [
                                      Text(country['flag']!),
                                      const SizedBox(width: 4),
                                      Text(country['code']!),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCountryCode = value;
                                  });
                                  _savePhoneNumber(_phoneController.text.trim());
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _phoneController,
                            label: 'Numéro de téléphone',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              if (value != null) {
                                _savePhoneNumber(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ PIN
                    CustomTextField(
                      controller: _pinController,
                      label: 'Code PIN (6 chiffres)',
                      prefixIcon: Icons.lock,
                      suffixIcon: _obscurePin ? Icons.visibility_off : Icons.visibility,
                      onSuffixPressed: () {
                        if (mounted) {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        }
                      },
                      obscureText: _obscurePin,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 8),
                    
                    // Se souvenir de moi
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            _saveRememberMe(value ?? false);
                          },
                          activeColor: const Color(0xFF0B6E3A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        const Text(
                          'Se souvenir de mon numéro',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Bouton connexion
                    CustomButton(
                      text: 'Se connecter',
                      onPressed: _loginWithPin,
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Séparateur
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bouton options avancées
                    GestureDetector(
                      onTap: _toggleAdvancedOptions,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showAdvancedOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: const Color(0xFF0B6E3A),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showAdvancedOptions ? 'Masquer les options avancées' : 'Options avancées',
                              style: const TextStyle(color: Color(0xFF0B6E3A), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Options avancées
                    if (_showAdvancedOptions) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.email_outlined, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Connexion par Email',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Vous avez perdu votre code PIN ? Connectez-vous avec votre email',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _identifierController,
                              label: 'Adresse email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _sendOtp,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF0B6E3A)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Envoyer le code OTP',
                                  style: TextStyle(color: Color(0xFF0B6E3A)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Lien inscription
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'S\'inscrire',
                      style: TextStyle(color: Color(0xFF0B6E3A), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}