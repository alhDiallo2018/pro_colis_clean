// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'register_client_screen.dart';
import 'register_driver_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Inscription', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2B3C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0B6E3A).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add, size: 50, color: Color(0xFF0B6E3A)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choisissez votre type de compte',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2B3C)),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez le profil qui vous correspond',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            
            // Carte Client
            _buildRegisterCard(
              context: context,
              title: 'Client',
              subtitle: 'Envoyez et recevez vos colis',
              icon: Icons.person_outline,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterClientScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Carte Chauffeur
            _buildRegisterCard(
              context: context,
              title: 'Chauffeur',
              subtitle: 'Devenez livreur partenaire',
              icon: Icons.local_taxi,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterDriverScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Carte Admin Garage
            _buildRegisterCard(
              context: context,
              title: 'Admin Garage',
              subtitle: 'Gérez votre point de service',
              icon: Icons.business,
              color: Colors.orange,
              onTap: () {
                // Pour l'admin, généralement c'est le super admin qui crée
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contactez l\'administrateur pour créer un compte admin'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Lien connexion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Déjà un compte ? ', style: TextStyle(color: Colors.grey.shade600)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(color: Color(0xFF0B6E3A), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2B3C)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}