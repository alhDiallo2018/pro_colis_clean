import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String userId;
  final String identifier;
  final bool isLogin;
  
  const OtpVerificationScreen({
    super.key,
    required this.userId,
    required this.identifier,
    this.isLogin = true,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    print('🔐 OTP Screen - UserId: ${widget.userId}');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le code à 6 chiffres')),
      );
      return;
    }
    
    setState(() => _isVerifying = true);
    print('🔐 Verifying OTP: $code for user ${widget.userId}');
    
    final result = await ref.read(authProvider.notifier).verifyOtp(
      userId: widget.userId,
      code: code,
      type: 'login',
    );
    
    setState(() => _isVerifying = false);
    print('🔐 Verification result: $result');
    
    if (result['success'] == true) {
      print('✅ Login successful, navigating to dashboard');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      }
    } else {
      print('❌ Verification failed: ${result['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Code invalide'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    
    setState(() => _isVerifying = true);
    
    final result = await ref.read(authProvider.notifier).sendOtp(
      identifier: widget.identifier,
    );
    
    setState(() => _isVerifying = false);
    
    if (result['success'] == true) {
      _startTimer();
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau code envoyé !'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification OTP'),
        backgroundColor: const Color(0xFF0B6E3A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms, size: 80, color: Color(0xFF0B6E3A)),
            const SizedBox(height: 24),
            const Text(
              'Code de vérification',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Envoyé à ${widget.identifier}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(fontSize: 32, letterSpacing: 8),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isVerifying)
              const CircularProgressIndicator()
            else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6E3A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Vérifier',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_canResend)
                Text(
                  'Renvoyer dans ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey),
                )
              else
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text(
                    'Renvoyer le code',
                    style: TextStyle(color: Color(0xFF0B6E3A)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
