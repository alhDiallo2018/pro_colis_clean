// mobile/lib/screens/auth/register_driver_screen.dart
// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart';

class RegisterDriverScreen extends ConsumerStatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  ConsumerState<RegisterDriverScreen> createState() =>
      _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends ConsumerState<RegisterDriverScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();

  // État
  bool _isLoading = false;
  bool _isLoadingLocations = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  
  // Sélections
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedLocationId;
  
  // Listes dynamiques
  List<String> _regions = [];
  List<String> _cities = [];
  List<Map<String, dynamic>> _locations = [];
  
  // Map pour stocker les villes par région
  final Map<String, List<String>> _citiesByRegion = {};
  
  // Préfixe téléphone
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

  // Modèles de véhicules
  final List<DropdownMenuItem<String>> _vehicleModels = const [
    DropdownMenuItem(value: 'Toyota HiAce', child: Text('Toyota HiAce')),
    DropdownMenuItem(value: 'Toyota Corolla', child: Text('Toyota Corolla')),
    DropdownMenuItem(value: 'Toyota Camry', child: Text('Toyota Camry')),
    DropdownMenuItem(value: 'Toyota Land Cruiser', child: Text('Toyota Land Cruiser')),
    DropdownMenuItem(value: 'Hyundai Accent', child: Text('Hyundai Accent')),
    DropdownMenuItem(value: 'Hyundai H100', child: Text('Hyundai H100')),
    DropdownMenuItem(value: 'Hyundai Grand Starex', child: Text('Hyundai Grand Starex')),
    DropdownMenuItem(value: 'Mercedes-Benz Sprinter', child: Text('Mercedes-Benz Sprinter')),
    DropdownMenuItem(value: 'Mercedes-Benz Actros', child: Text('Mercedes-Benz Actros')),
    DropdownMenuItem(value: 'Renault Logan', child: Text('Renault Logan')),
    DropdownMenuItem(value: 'Renault Master', child: Text('Renault Master')),
    DropdownMenuItem(value: 'Peugeot 301', child: Text('Peugeot 301')),
    DropdownMenuItem(value: 'Peugeot 206', child: Text('Peugeot 206')),
    DropdownMenuItem(value: 'Nissan Patrol', child: Text('Nissan Patrol')),
    DropdownMenuItem(value: 'Nissan Navara', child: Text('Nissan Navara')),
    DropdownMenuItem(value: 'Mitsubishi L200', child: Text('Mitsubishi L200')),
    DropdownMenuItem(value: 'Mitsubishi Pajero', child: Text('Mitsubishi Pajero')),
    DropdownMenuItem(value: 'Honda CR-V', child: Text('Honda CR-V')),
    DropdownMenuItem(value: 'Honda Civic', child: Text('Honda Civic')),
    DropdownMenuItem(value: 'Kia Picanto', child: Text('Kia Picanto')),
    DropdownMenuItem(value: 'Kia Sportage', child: Text('Kia Sportage')),
    DropdownMenuItem(value: 'Ford Ranger', child: Text('Ford Ranger')),
    DropdownMenuItem(value: 'Ford Transit', child: Text('Ford Transit')),
    DropdownMenuItem(value: 'Isuzu Elf', child: Text('Isuzu Elf')),
    DropdownMenuItem(value: 'Isuzu N-Series', child: Text('Isuzu N-Series')),
    DropdownMenuItem(value: 'TATA Motors', child: Text('TATA Motors')),
    DropdownMenuItem(value: 'King Long', child: Text('King Long')),
    DropdownMenuItem(value: 'Yutong Bus', child: Text('Yutong Bus')),
    DropdownMenuItem(value: 'Foton Auman', child: Text('Foton Auman')),
  ];

  final List<DropdownMenuItem<String>> _vehicleColors = const [
    DropdownMenuItem(value: 'Blanc', child: Text('Blanc')),
    DropdownMenuItem(value: 'Noir', child: Text('Noir')),
    DropdownMenuItem(value: 'Gris', child: Text('Gris')),
    DropdownMenuItem(value: 'Bleu', child: Text('Bleu')),
    DropdownMenuItem(value: 'Rouge', child: Text('Rouge')),
    DropdownMenuItem(value: 'Vert', child: Text('Vert')),
    DropdownMenuItem(value: 'Jaune', child: Text('Jaune')),
    DropdownMenuItem(value: 'Beige', child: Text('Beige')),
    DropdownMenuItem(value: 'Marron', child: Text('Marron')),
    DropdownMenuItem(value: 'Orange', child: Text('Orange')),
    DropdownMenuItem(value: 'Violet', child: Text('Violet')),
    DropdownMenuItem(value: 'Rose', child: Text('Rose')),
    DropdownMenuItem(value: 'Bordeaux', child: Text('Bordeaux')),
    DropdownMenuItem(value: 'Kaki', child: Text('Kaki')),
    DropdownMenuItem(value: 'Argenté', child: Text('Argenté')),
  ];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoadingLocations = true);
    try {
      final locations = await _apiService.getAllGarages();
      
      final regionsSet = <String>{};
      final locationsList = <Map<String, dynamic>>[];
      final citiesByRegionTemp = <String, Set<String>>{};
      
      for (var location in locations) {
        final region = location.region;
        final city = location.city;
        
        regionsSet.add(region);
        
        String cleanName = location.name;
        if (cleanName.startsWith('Garage ')) {
          cleanName = cleanName.substring(7);
        }
        
        locationsList.add({
          'id': location.id,
          'name': cleanName,
          'city': city,
          'region': region,
        });
        
        if (!citiesByRegionTemp.containsKey(region)) {
          citiesByRegionTemp[region] = {};
        }
        citiesByRegionTemp[region]!.add(city);
      }
      
      final citiesByRegionFinal = <String, List<String>>{};
      for (var entry in citiesByRegionTemp.entries) {
        citiesByRegionFinal[entry.key] = entry.value.toList()..sort();
      }
      
      setState(() {
        _regions = regionsSet.toList()..sort();
        _locations = locationsList;
        _citiesByRegion.clear();
        _citiesByRegion.addAll(citiesByRegionFinal);
        _isLoadingLocations = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur: $e');
      setState(() => _isLoadingLocations = false);
      _loadFallbackData();
    }
  }
  
  void _loadFallbackData() {
    const fallbackRegions = [
      'Dakar', 'Thiès', 'Saint-Louis', 'Ziguinchor', 'Kaolack',
      'Tambacounda', 'Kédougou', 'Kaffrine', 'Diourbel', 'Fatick',
      'Kolda', 'Louga', 'Matam', 'Sédhiou'
    ];
    
    const fallbackCitiesByRegion = {
      'Dakar': ['Dakar', 'Pikine', 'Guédiawaye', 'Rufisque', 'Bargny'],
      'Thiès': ['Thiès', 'Mbour', 'Tivaouane', 'Saly'],
      'Saint-Louis': ['Saint-Louis', 'Richard Toll', 'Dagana'],
      'Ziguinchor': ['Ziguinchor', 'Bignona', 'Oussouye'],
      'Kaolack': ['Kaolack', 'Nioro du Rip'],
      'Tambacounda': ['Tambacounda', 'Bakel'],
      'Kédougou': ['Kédougou', 'Salémata'],
      'Kaffrine': ['Kaffrine', 'Malem Hodar'],
      'Diourbel': ['Diourbel', 'Bambey', 'Touba'],
      'Fatick': ['Fatick', 'Foundiougne', 'Sokone'],
      'Kolda': ['Kolda', 'Vélingara'],
      'Louga': ['Louga', 'Linguère'],
      'Matam': ['Matam', 'Kanel'],
      'Sédhiou': ['Sédhiou', 'Bounkiling'],
    };
    
    setState(() {
      _regions = fallbackRegions;
      _citiesByRegion.clear();
      _citiesByRegion.addAll(fallbackCitiesByRegion);
      _isLoadingLocations = false;
    });
  }

  void _onRegionChanged(String? region) {
    setState(() {
      _selectedRegion = region;
      _selectedCity = null;
      _selectedLocationId = null;
      
      if (region != null && _citiesByRegion.containsKey(region)) {
        _cities = _citiesByRegion[region]!;
      } else {
        _cities = [];
      }
    });
  }

  List<Map<String, dynamic>> get _filteredLocations {
    return _locations.where((loc) {
      if (_selectedRegion != null && loc['region'] != _selectedRegion) return false;
      if (_selectedCity != null && loc['city'] != _selectedCity) return false;
      return true;
    }).toList();
  }

  String _getFullPhoneNumber() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) return '';
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return '$_selectedCountryCode$cleanNumber';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Les mots de passe ne correspondent pas', Colors.red);
      return;
    }

    if (!_acceptTerms) {
      _showSnackBar('Vous devez accepter les conditions', Colors.red);
      return;
    }

    if (_selectedLocationId == null) {
      _showSnackBar('Veuillez sélectionner votre point de service', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullPhoneNumber = _getFullPhoneNumber();
      
      final result = await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            phone: fullPhoneNumber, // Utiliser le numéro complet avec code pays
            fullName: _fullNameController.text.trim(),
            password: _passwordController.text,
            role: 'driver',
            address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
            city: _selectedCity,
            region: _selectedRegion,
            garageId: _selectedLocationId,
            vehiclePlate: _vehiclePlateController.text.trim().isNotEmpty ? _vehiclePlateController.text.trim().toUpperCase() : null,
            vehicleModel: _vehicleModelController.text.trim().isNotEmpty ? _vehicleModelController.text.trim() : null,
            vehicleColor: _vehicleColorController.text.isNotEmpty ? _vehicleColorController.text : null,
            vehicleYear: _vehicleYearController.text.isNotEmpty ? int.tryParse(_vehicleYearController.text) : null,
          );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          final userId = result['userId'];
          final email = _emailController.text.trim();

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                userId: userId,
                identifier: email,
                isLogin: false,
              ),
            ),
            (route) => false,
          );
        } else {
          _showSnackBar(result['message'] ?? 'Erreur lors de l\'inscription', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Erreur: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Inscription Chauffeur', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2B3C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B6E3A).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_taxi, size: 40, color: Color(0xFF0B6E3A)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Devenez chauffeur partenaire',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2B3C)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Créez votre compte et commencez à gagner',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section Informations personnelles
              _buildSectionCard(
                title: 'Informations personnelles',
                icon: Icons.person,
                color: Colors.blue,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Nom complet *',
                      prefixIcon: Icons.person,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email *',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@') ? 'Email valide requis' : null,
                    ),
                    const SizedBox(height: 12),
                    // ✅ Champ téléphone avec sélecteur de code pays
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Téléphone *',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sélecteur de code pays
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
                                    return DropdownMenuItem(
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
                                    setState(() {
                                      _selectedCountryCode = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: _phoneController,
                                label: 'Numéro de téléphone',
                                prefixIcon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _addressController,
                      label: 'Adresse détaillée',
                      prefixIcon: Icons.location_on,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section Localisation
              _buildSectionCard(
                title: 'Localisation',
                icon: Icons.map,
                color: Colors.orange,
                child: Column(
                  children: [
                    if (_isLoadingLocations)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedRegion,
                        hint: const Text('Sélectionnez votre région'),
                        decoration: _inputDecoration('Région *', Icons.map),
                        items: _regions.map((region) => DropdownMenuItem<String>(
                          value: region,
                          child: Text(region, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _onRegionChanged,
                        validator: (v) => v == null ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      if (_selectedRegion != null && _cities.isNotEmpty)
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedCity,
                          hint: const Text('Sélectionnez votre ville'),
                          decoration: _inputDecoration('Ville *', Icons.location_city),
                          items: _cities.map((city) => DropdownMenuItem<String>(
                            value: city,
                            child: Text(city, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedCity = value),
                          validator: (v) => v == null ? 'Champ requis' : null,
                        ),
                      if (_selectedCity != null && _filteredLocations.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedLocationId,
                          hint: const Text('Sélectionnez votre point de service'),
                          decoration: _inputDecoration('Point de service *', Icons.business_center),
                          items: _filteredLocations.map((location) => DropdownMenuItem<String>(
                            value: location['id'],
                            child: Text(location['name'], overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedLocationId = value),
                          validator: (v) => v == null ? 'Veuillez sélectionner votre point de service' : null,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section Véhicule
              _buildSectionCard(
                title: 'Véhicule (optionnel)',
                icon: Icons.directions_car,
                color: Colors.purple,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _vehiclePlateController,
                      label: 'Plaque d\'immatriculation',
                      prefixIcon: Icons.confirmation_number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _vehicleModelController.text.isNotEmpty ? _vehicleModelController.text : null,
                      hint: const Text('Sélectionnez votre modèle'),
                      decoration: _inputDecoration('Modèle du véhicule', Icons.car_repair),
                      items: _vehicleModels,
                      onChanged: (value) => setState(() => _vehicleModelController.text = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _vehicleColorController.text.isNotEmpty ? _vehicleColorController.text : null,
                      decoration: _inputDecoration('Couleur du véhicule', Icons.color_lens),
                      items: _vehicleColors,
                      onChanged: (value) => setState(() => _vehicleColorController.text = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _vehicleYearController,
                      label: 'Année du véhicule',
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section Sécurité
              _buildSectionCard(
                title: 'Sécurité',
                icon: Icons.lock,
                color: Colors.red,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Mot de passe *',
                      prefixIcon: Icons.lock,
                      suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      onSuffixPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      obscureText: _obscurePassword,
                      validator: (v) => v == null || v.length < 6 ? 'Min 6 caractères' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmer mot de passe *',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      onSuffixPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      obscureText: _obscureConfirmPassword,
                      validator: (v) => v == null || v.length < 6 ? 'Min 6 caractères' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Conditions
              Container(
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
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                      activeColor: const Color(0xFF0B6E3A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    const Expanded(
                      child: Text(
                        "J'accepte les conditions d'utilisation",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bouton inscription
              CustomButton(
                text: 'Créer mon compte chauffeur',
                onPressed: _register,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),

              // Lien connexion
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Déjà un compte ? Se connecter',
                    style: TextStyle(color: Color(0xFF0B6E3A), fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0B6E3A), width: 1.5),
      ),
    );
  }
}