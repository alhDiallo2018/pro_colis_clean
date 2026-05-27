import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../models/garage.dart';
import '../../models/parcel.dart';
import '../../models/payment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'parcel_detail_screen.dart';

class NewParcelScreen extends ConsumerStatefulWidget {
  const NewParcelScreen({super.key});

  @override
  ConsumerState<NewParcelScreen> createState() => _NewParcelScreenState();
}

class _NewParcelScreenState extends ConsumerState<NewParcelScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // Liste des garages depuis l'API
  List<Garage> _garages = [];
  bool _isLoadingGarages = true;
  
  // ==================== EXPÉDITEUR (CLIENT) ====================
  // Le chauffeur saisit les infos du client qui lui donne le colis
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _senderEmailController = TextEditingController();
  
  // ==================== DESTINATAIRE ====================
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _receiverEmailController = TextEditingController();
  final _receiverAddressController = TextEditingController();
  
  // ==================== COLIS ====================
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  ParcelType _selectedType = ParcelType.package;
  
  // ==================== LIEUX ====================
  String? _selectedDepartureGarageId;
  String? _selectedArrivalGarageId;
  
  // ==================== OPTIONS ====================
  bool _isLoading = false;
  bool _urgentDelivery = false;
  bool _insurance = false;
  
  // ==================== PAIEMENT ====================
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  final TextEditingController _phoneNumberController = TextEditingController();
  
  // ==================== MÉDIAS ====================
  final List<XFile> _photos = [];
  final List<XFile> _videos = [];
  final ImagePicker _picker = ImagePicker();
  
  // URLs uploadées
  List<String> _uploadedPhotoUrls = [];
  List<String> _uploadedVideoUrls = [];
  
  // Contrôleurs vidéo
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _videoInitialized = {};

  @override
  void initState() {
    super.initState();
    _loadGarages();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderEmailController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverEmailController.dispose();
    _receiverAddressController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _phoneNumberController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGarages() async {
    setState(() => _isLoadingGarages = true);
    
    try {
      final garages = await _apiService.getAllGarages();
      setState(() {
        _garages = garages;
        _isLoadingGarages = false;
      });
      debugPrint('✅ ${garages.length} garages chargés');
    } catch (e) {
      setState(() => _isLoadingGarages = false);
      debugPrint('❌ Erreur chargement garages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement garages: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== GESTION DES PHOTOS ====================
  
  Future<void> _pickPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() => _photos.add(photo));
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() => _photos.add(photo));
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() => _videos.add(video));
        if (!kIsWeb) {
          _initializeVideoController(video);
        }
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        setState(() => _videos.add(video));
        if (!kIsWeb) {
          _initializeVideoController(video);
        }
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  void _initializeVideoController(XFile video) async {
    if (kIsWeb) return;
    final controller = VideoPlayerController.file(File(video.path));
    await controller.initialize();
    if (mounted) {
      setState(() {
        _videoControllers[video.path] = controller;
        _videoInitialized[video.path] = true;
      });
    }
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));
  void _removeVideo(int index) {
    final videoPath = _videos[index].path;
    setState(() => _videos.removeAt(index));
    if (!kIsWeb) {
      _videoControllers[videoPath]?.dispose();
      _videoControllers.remove(videoPath);
      _videoInitialized.remove(videoPath);
    }
  }

  // ==================== AFFICHAGE DES MÉDIAS ====================
  
  Widget _buildMediaSection() {
    return _buildSection(
      icon: Icons.photo_library,
      title: 'Photos et vidéos',
      color: Colors.teal,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: _pickPhoto,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.camera_alt,
                  label: 'Appareil',
                  onTap: _takePhoto,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.video_library,
                  label: 'Vidéo',
                  onTap: _pickVideo,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.videocam,
                  label: 'Enregistrer',
                  onTap: _recordVideo,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_photos.isNotEmpty) ...[
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                itemBuilder: (context, index) => _buildPhotoThumbnail(_photos[index], index),
              ),
            ),
          ],
          
          if (_videos.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Vidéos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _videos.length,
                itemBuilder: (context, index) => _buildVideoThumbnail(_videos[index], index),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPhotoThumbnail(XFile photo, int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: _getImageProvider(photo.path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoThumbnail(XFile video, int index) {
    final isInitialized = _videoInitialized[video.path] ?? false;
    final controller = _videoControllers[video.path];
    
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black,
          ),
          child: Center(
            child: !kIsWeb && isInitialized && controller != null
                ? Stack(
                    children: [
                      VideoPlayer(controller),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(100),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, size: 30, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Image.network(
                        video.path,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.videocam, size: 40, color: Colors.white54),
                        ),
                      ),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(100),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, size: 30, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeVideo(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (kIsWeb) return NetworkImage(path);
    return FileImage(File(path));
  }

  // ==================== SECTION PAIEMENT ====================
  
  Widget _buildPaymentSection() {
    final double estimatedPrice = _calculateEstimatedPrice();
    
    return _buildSection(
      icon: Icons.payment,
      title: 'Paiement',
      color: Colors.deepPurple,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Prix du colis:'),
                    Text('${_priceController.text.isEmpty ? '0' : _priceController.text} FCFA'),
                  ],
                ),
                if (_urgentDelivery) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text('Frais urgent:'), Text('500 FCFA')],
                  ),
                ],
                if (_insurance) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text('Assurance:'), Text('2% du montant')],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total à payer:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${estimatedPrice.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0B6E3A)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          const Text('Mode de paiement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: PaymentMethod.values.map((method) {
                final isSelected = _selectedPaymentMethod == method;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getPaymentIcon(method), size: 16, color: isSelected ? Colors.white : _getPaymentColor(method)),
                        const SizedBox(width: 6),
                        Text(method.label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPaymentMethod = method);
                    },
                    selectedColor: _getPaymentColor(method),
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_selectedPaymentMethod == PaymentMethod.wave ||
              _selectedPaymentMethod == PaymentMethod.orangeMoney ||
              _selectedPaymentMethod == PaymentMethod.freeMoney)
            CustomTextField(
              controller: _phoneNumberController,
              label: 'Numéro de téléphone du client',
              prefixIcon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              hint: 'Ex: 77 123 45 67',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Numéro requis';
                if (v.length < 9) return 'Numéro invalide';
                return null;
              },
            ),
          
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le paiement sera effectué à la livraison. Vous recevrez un reçu par SMS/Email.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateEstimatedPrice() {
    double total = 0;
    if (_priceController.text.isNotEmpty) {
      total += double.tryParse(_priceController.text) ?? 0;
    }
    if (_urgentDelivery) total += 500;
    if (_insurance && _priceController.text.isNotEmpty) {
      total += (double.tryParse(_priceController.text) ?? 0) * 0.02;
    }
    return total;
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Icons.money;
      case PaymentMethod.wave: return Icons.waves;
      case PaymentMethod.orangeMoney: return Icons.phone_android;
      case PaymentMethod.freeMoney: return Icons.smartphone;
      case PaymentMethod.card: return Icons.credit_card;
    }
  }

  Color _getPaymentColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Colors.green;
      case PaymentMethod.wave: return Colors.blue;
      case PaymentMethod.orangeMoney: return Colors.deepOrange;
      case PaymentMethod.freeMoney: return Colors.purple;
      case PaymentMethod.card: return Colors.indigo;
    }
  }

  // ==================== UPLOAD DES MÉDIAS ====================
  
  Future<List<String>> _uploadPhotos() async {
    List<String> uploadedUrls = [];
    for (var photo in _photos) {
      try {
        final url = await _apiService.uploadParcelPhoto(photo, 'temp');
        if (url != null) uploadedUrls.add(url);
      } catch (e) {
        debugPrint('❌ Erreur upload photo: $e');
      }
    }
    return uploadedUrls;
  }
  
  Future<List<String>> _uploadVideos() async {
    List<String> uploadedUrls = [];
    for (var video in _videos) {
      try {
        final url = await _apiService.uploadParcelVideo(video, 'temp');
        if (url != null) uploadedUrls.add(url);
      } catch (e) {
        debugPrint('❌ Erreur upload vidéo: $e');
      }
    }
    return uploadedUrls;
  }

  // ==================== CRÉATION DU COLIS ====================
  
  Future<void> _createParcel() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (_selectedDepartureGarageId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez sélectionner un garage de départ'), backgroundColor: Colors.orange),
    );
    return;
  }
  
  // Validation du numéro de téléphone pour les paiements mobiles
  if ((_selectedPaymentMethod == PaymentMethod.wave ||
       _selectedPaymentMethod == PaymentMethod.orangeMoney ||
       _selectedPaymentMethod == PaymentMethod.freeMoney) &&
      _phoneNumberController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez entrer le numéro du client'), backgroundColor: Colors.orange),
    );
    return;
  }
  
  setState(() => _isLoading = true);
  
  try {
    final photoUrls = await _uploadPhotos();
    final videoUrls = await _uploadVideos();
    
    final departureGarage = _garages.firstWhere((g) => g.id == _selectedDepartureGarageId);
    final arrivalGarage = _selectedArrivalGarageId != null 
        ? _garages.firstWhere((g) => g.id == _selectedArrivalGarageId)
        : departureGarage;
    
    final totalPrice = _calculateEstimatedPrice();
    
    // Récupérer les infos du chauffeur connecté
    final authState = ref.read(authProvider);
    final currentDriver = authState.user;
    
    // Structure des données pour le backend
    final Map<String, dynamic> data = {
      // === INFOS CLIENT (expéditeur réel) ===
      'senderName': _senderNameController.text.trim(),
      'senderPhone': _senderPhoneController.text.trim(),
      
      // === INFOS DESTINATAIRE ===
      'receiverName': _receiverNameController.text.trim(),
      'receiverPhone': _receiverPhoneController.text.trim(),
      
      // === INFOS COLIS ===
      'description': _descriptionController.text.trim(),
      'weight': double.parse(_weightController.text),
      'type': _selectedType.value,
      
      // === TRAJET ===
      'departureGarageId': _selectedDepartureGarageId,
      'departureGarageName': departureGarage.name,
      'arrivalGarageId': _selectedArrivalGarageId,
      'arrivalGarageName': arrivalGarage.name,
      
      // === PRIX ET OPTIONS ===
      'price': double.tryParse(_priceController.text) ?? 0,
      'isUrgent': _urgentDelivery,
      'isInsured': _insurance,
      
      // === PAIEMENT ===
      'paymentMethod': _selectedPaymentMethod.value,
      'paymentPhoneNumber': _phoneNumberController.text.trim(),
      
      // === MÉDIAS ===
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      
      // === CHAUFFEUR (auto-assigné) ===
      'driverId': currentDriver?.id,
      'driverName': currentDriver?.fullName,
      'driverPhone': currentDriver?.phone,
    };
    
    // Ajouter les champs optionnels seulement s'ils ne sont pas vides
    if (_senderEmailController.text.trim().isNotEmpty) {
      data['senderEmail'] = _senderEmailController.text.trim();
    }
    
    if (_receiverEmailController.text.trim().isNotEmpty) {
      data['receiverEmail'] = _receiverEmailController.text.trim();
    }
    
    if (_receiverAddressController.text.trim().isNotEmpty) {
      data['receiverAddress'] = _receiverAddressController.text.trim();
    }
    
    if (_selectedArrivalGarageId != null) {
      data['arrivalGarageId'] = _selectedArrivalGarageId;
      data['arrivalGarageName'] = arrivalGarage.name;
    }
    
    if (totalPrice > 0) {
      data['totalAmount'] = totalPrice;
    }
    
    // ⚠️ IMPORTANT: NE PAS envoyer senderId si le client n'a pas de compte
    // data['senderId'] est volontairement OMIS
    
    print('📦 Données envoyées: ${jsonEncode(data)}');
    
    final result = await ref.read(parcelProvider.notifier).createParcel(data);
    
    if (mounted) setState(() => _isLoading = false);
    
    if (result != null && mounted) {
      _showSuccessDialog(result, totalPrice);
    } else if (mounted) {
      final errorState = ref.read(parcelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorState.error ?? 'Erreur lors de la création'), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    print('❌ Erreur création colis: $e');
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

  void _showSuccessDialog(Parcel parcel, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Colis créé avec succès'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📦 ${parcel.trackingNumber}'),
            const SizedBox(height: 8),
            Text('💰 ${amount.toStringAsFixed(0)} FCFA'),
            const SizedBox(height: 8),
            Text('👤 Client: ${_senderNameController.text.trim()}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Le client recevra un SMS avec le numéro de suivi.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Nouveau colis'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToParcelDetail(parcel);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B6E3A)),
            child: const Text('Voir le colis'),
          ),
        ],
      ),
    );
  }

  void _navigateToParcelDetail(Parcel parcel) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ParcelDetailScreen(parcel: parcel)),
    );
  }

  void _resetForm() {
    _senderNameController.clear();
    _senderPhoneController.clear();
    _senderEmailController.clear();
    _receiverNameController.clear();
    _receiverPhoneController.clear();
    _receiverEmailController.clear();
    _receiverAddressController.clear();
    _descriptionController.clear();
    _weightController.clear();
    _priceController.clear();
    _phoneNumberController.clear();
    setState(() {
      _selectedType = ParcelType.package;
      _selectedDepartureGarageId = null;
      _selectedArrivalGarageId = null;
      _selectedPaymentMethod = PaymentMethod.cash;
      _urgentDelivery = false;
      _insurance = false;
      _photos.clear();
      _videos.clear();
    });
    if (!kIsWeb) {
      for (var controller in _videoControllers.values) controller.dispose();
      _videoControllers.clear();
      _videoInitialized.clear();
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau colis'),
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingGarages
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================== SECTION EXPÉDITEUR (CLIENT) ====================
                    _buildSection(
                      icon: Icons.person_outline,
                      title: 'Client (Expéditeur)',
                      color: Colors.blue,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _senderNameController,
                            label: 'Nom complet du client',
                            prefixIcon: Icons.person,
                            validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _senderPhoneController,
                            label: 'Téléphone du client',
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _senderEmailController,
                            label: 'Email du client (optionnel)',
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // ==================== SECTION DESTINATAIRE ====================
                    _buildSection(
                      icon: Icons.person,
                      title: 'Destinataire',
                      color: Colors.blue,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _receiverNameController,
                            label: 'Nom complet',
                            prefixIcon: Icons.person,
                            validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _receiverPhoneController,
                            label: 'Téléphone',
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _receiverEmailController,
                            label: 'Email (optionnel)',
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _receiverAddressController,
                            label: 'Adresse (optionnel)',
                            prefixIcon: Icons.location_on,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // ==================== SECTION COLIS ====================
                    _buildSection(
                      icon: Icons.inventory,
                      title: 'Informations colis',
                      color: Colors.green,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            prefixIcon: Icons.description,
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _weightController,
                                  label: 'Poids (kg)',
                                  prefixIcon: Icons.fitness_center,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  controller: _priceController,
                                  label: 'Prix (FCFA)',
                                  prefixIcon: Icons.money,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<ParcelType>(
                            initialValue: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type de colis',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            items: ParcelType.values.map((type) => DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(_getTypeIcon(type), size: 18),
                                  const SizedBox(width: 8),
                                  Text(type.label),
                                ],
                              ),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedType = value!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // ==================== SECTION TRAJET ====================
                    _buildSection(
                      icon: Icons.route,
                      title: 'Trajet',
                      color: Colors.orange,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDepartureGarageId,
                            hint: const Text('Garage de départ'),
                            decoration: const InputDecoration(
                              labelText: 'Garage départ',
                              prefixIcon: Icon(Icons.departure_board),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            items: _garages.map((garage) => DropdownMenuItem(
                              value: garage.id,
                              child: Text('${garage.name} - ${garage.city}'),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedDepartureGarageId = value),
                            validator: (v) => v == null ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            initialValue: _selectedArrivalGarageId,
                            hint: const Text('Garage d\'arrivée (optionnel)'),
                            decoration: const InputDecoration(
                              labelText: 'Garage arrivée',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Aucun (même garage)')),
                              ..._garages.map((garage) => DropdownMenuItem(
                                value: garage.id,
                                child: Text('${garage.name} - ${garage.city}'),
                              )),
                            ],
                            onChanged: (value) => setState(() => _selectedArrivalGarageId = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // ==================== SECTION MÉDIAS ====================
                    _buildMediaSection(),
                    const SizedBox(height: 16),
                    
                    // ==================== SECTION OPTIONS ====================
                    _buildSection(
                      icon: Icons.settings,
                      title: 'Options',
                      color: Colors.purple,
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Livraison urgente'),
                            subtitle: const Text('Priorité + 500 FCFA'),
                            value: _urgentDelivery,
                            onChanged: (value) => setState(() => _urgentDelivery = value),
                            activeTrackColor: const Color(0xFF0B6E3A).withAlpha(128),
                            activeThumbColor: const Color(0xFF0B6E3A),
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: const Text('Assurance colis'),
                            subtitle: const Text('Protection jusqu\'à 50 000 FCFA (2%)'),
                            value: _insurance,
                            onChanged: (value) => setState(() => _insurance = value),
                            activeTrackColor: const Color(0xFF0B6E3A).withAlpha(128),
                            activeThumbColor: const Color(0xFF0B6E3A),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // ==================== SECTION PAIEMENT ====================
                    _buildPaymentSection(),
                    const SizedBox(height: 32),
                    
                    // ==================== BOUTON DE CRÉATION ====================
                    CustomButton(
                      text: 'Enregistrer le colis',
                      onPressed: _createParcel,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                    
                    // ==================== INFO CHAUFFEUR ====================
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vous êtes identifié comme chauffeur. Le colis vous sera automatiquement assigné.',
                              style: const TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  IconData _getTypeIcon(ParcelType type) {
    switch (type) {
      case ParcelType.document: return Icons.description;
      case ParcelType.package: return Icons.inventory;
      case ParcelType.fragile: return Icons.science;
      case ParcelType.perishable: return Icons.eco;
      case ParcelType.valuable: return Icons.attach_money;
    }
  }
}