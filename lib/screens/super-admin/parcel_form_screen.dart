// mobile/lib/screens/super-admin/parcel_form_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../models/garage.dart';
import '../../models/parcel.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ParcelFormScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final Parcel? parcel;
  
  const ParcelFormScreen({
    super.key,
    required this.isEditing,
    this.parcel,
  });

  @override
  ConsumerState<ParcelFormScreen> createState() => _ParcelFormScreenState();
}

class _ParcelFormScreenState extends ConsumerState<ParcelFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controllers
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _receiverEmailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _trackingNumberController = TextEditingController();
  
  // Dropdown values
  ParcelType _selectedType = ParcelType.package;
  ParcelStatus _selectedStatus = ParcelStatus.pending;
  String? _selectedDepartureGarageId;
  String? _selectedArrivalGarageId;
  String? _selectedDriverId;
  String? _selectedPaymentMethod;
  
  // Lists
  List<Garage> _garages = [];
  List<User> _drivers = [];
  bool _loadingData = true;
  
  // Médias
  final List<XFile> _photos = [];
  final List<XFile> _videos = [];
  List<String> _existingPhotoUrls = [];
  final ImagePicker _picker = ImagePicker();
  
  // Contrôleurs vidéo
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _videoInitialized = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.isEditing && widget.parcel != null) {
      _populateForm();
    }
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverEmailController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _trackingNumberController.dispose();
    // Libérer les contrôleurs vidéo
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final garages = await _apiService.getAllGaragesSuperAdmin();
      final allUsers = await _apiService.getAllUsersSuperAdmin();
      
      if (mounted) {
        setState(() {
          _garages = garages;
          _drivers = allUsers.where((u) => u.role == UserRole.driver).toList();
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _populateForm() {
    final parcel = widget.parcel!;
    _senderNameController.text = parcel.senderName;
    _senderPhoneController.text = parcel.senderPhone;
    _receiverNameController.text = parcel.receiverName;
    _receiverPhoneController.text = parcel.receiverPhone;
    _receiverEmailController.text = parcel.receiverEmail ?? '';
    _descriptionController.text = parcel.description;
    _weightController.text = parcel.weight.toString();
    _priceController.text = parcel.price?.toString() ?? '';
    _trackingNumberController.text = parcel.trackingNumber;
    _selectedType = parcel.type;
    _selectedStatus = parcel.status;
    // Convertir PaymentMethod en String si nécessaire
    if (parcel.paymentMethod != null) {
      if (parcel.paymentMethod is String) {
        _selectedPaymentMethod = parcel.paymentMethod as String;
      } else {
        // Si c'est un enum PaymentMethod, convertir en String
        _selectedPaymentMethod = parcel.paymentMethod.toString().split('.').last;
      }
    }
    
    // Charger les photos existantes
    _existingPhotoUrls = List.from(parcel.photoUrls);
  }

  // ==================== GESTION DES PHOTOS ====================
  
  Future<void> _pickPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() {
          _photos.add(photo);
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la sélection de la photo: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() {
          _photos.add(photo);
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null && mounted) {
        setState(() {
          _videos.add(video);
        });
        _initializeVideoController(video);
      }
    } catch (e) {
      debugPrint('Erreur lors de la sélection de la vidéo: $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
      );
      if (video != null && mounted) {
        setState(() {
          _videos.add(video);
        });
        _initializeVideoController(video);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement vidéo: $e');
    }
  }

  void _initializeVideoController(XFile video) async {
    final controller = VideoPlayerController.file(File(video.path));
    await controller.initialize();
    if (mounted) {
      setState(() {
        _videoControllers[video.path] = controller;
        _videoInitialized[video.path] = true;
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoUrls.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    final videoPath = _videos[index].path;
    setState(() {
      _videos.removeAt(index);
    });
    // Libérer le contrôleur vidéo
    _videoControllers[videoPath]?.dispose();
    _videoControllers.remove(videoPath);
    _videoInitialized.remove(videoPath);
  }

  // ==================== CRÉATION DU COLIS ====================
  
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Utiliser les URLs des photos existantes ou les chemins des nouvelles photos
      final photoUrls = [..._existingPhotoUrls, ..._photos.map((p) => p.path)];
      
      final data = {
        'senderName': _senderNameController.text.trim(),
        'senderPhone': _senderPhoneController.text.trim(),
        'receiverName': _receiverNameController.text.trim(),
        'receiverPhone': _receiverPhoneController.text.trim(),
        'receiverEmail': _receiverEmailController.text.trim().isEmpty ? null : _receiverEmailController.text.trim(),
        'description': _descriptionController.text.trim(),
        'weight': double.parse(_weightController.text.trim()),
        'type': _selectedType.value,
        'status': _selectedStatus.value,
        'departureGarageId': _selectedDepartureGarageId,
        'arrivalGarageId': _selectedArrivalGarageId,
        'driverId': _selectedDriverId,
        'price': _priceController.text.isNotEmpty ? double.parse(_priceController.text.trim()) : null,
        'paymentMethod': _selectedPaymentMethod,
        'photoUrls': photoUrls,
      };
      
      if (widget.isEditing && widget.parcel != null) {
        await _apiService.updateParcelStatus(
          widget.parcel!.id,
          _selectedStatus.value,
        );
      } else {
        await _apiService.createParcel(data);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Colis modifié avec succès' : 'Colis créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== AFFICHAGE DES MÉDIAS ====================
  
  Widget _buildMediaSection() {
    return Column(
      children: [
        _buildSectionTitle('Photos et vidéos'),
        const SizedBox(height: 8),
        
        // Boutons d'ajout
        Row(
          children: [
            Expanded(
              child: _buildMediaButton(
                icon: Icons.photo_library,
                label: 'Galerie photo',
                onTap: _pickPhoto,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMediaButton(
                icon: Icons.camera_alt,
                label: 'Appareil photo',
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
                label: 'Galerie vidéo',
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
        
        // Photos existantes
        if (_existingPhotoUrls.isNotEmpty) ...[
          const Text('Photos existantes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingPhotoUrls.length,
              itemBuilder: (context, index) {
                return _buildExistingPhotoThumbnail(_existingPhotoUrls[index], index);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Nouvelles photos
        if (_photos.isNotEmpty) ...[
          const Text('Nouvelles photos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return _buildPhotoThumbnail(_photos[index], index);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Vidéos
        if (_videos.isNotEmpty) ...[
          const Text('Vidéos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                return _buildVideoThumbnail(_videos[index], index);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
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
              image: FileImage(File(photo.path)),
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

  Widget _buildExistingPhotoThumbnail(String url, int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeExistingPhoto(index),
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
          child: isInitialized && controller != null
              ? Stack(
                  children: [
                    VideoPlayer(controller),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier le colis' : 'Nouveau colis'),
        backgroundColor: const Color.fromARGB(255, 5, 243, 243),
        foregroundColor: Colors.white,
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Section Expéditeur
                    _buildSectionTitle('Expéditeur'),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _senderNameController,
                      label: 'Nom complet',
                      prefixIcon: Icons.person,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _senderPhoneController,
                      label: 'Téléphone',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Section Destinataire
                    _buildSectionTitle('Destinataire'),
                    const SizedBox(height: 8),
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
                      label: 'Email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    
                    // Section Détails du colis
                    _buildSectionTitle('Détails du colis'),
                    const SizedBox(height: 8),
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
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type de colis',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: ParcelType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(type.label),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                    const SizedBox(height: 24),
                    
                    // Section Transport
                    _buildSectionTitle('Transport'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedDepartureGarageId,
                      decoration: const InputDecoration(
                        labelText: 'Garage de départ',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sélectionner...')),
                        ..._garages.map((garage) => DropdownMenuItem(
                          value: garage.id,
                          child: Text(garage.name),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedDepartureGarageId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: _selectedArrivalGarageId,
                      decoration: const InputDecoration(
                        labelText: 'Garage d\'arrivée',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sélectionner...')),
                        ..._garages.map((garage) => DropdownMenuItem(
                          value: garage.id,
                          child: Text(garage.name),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedArrivalGarageId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: _selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Chauffeur assigné',
                        prefixIcon: Icon(Icons.delivery_dining),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Aucun chauffeur')),
                        ..._drivers.map((driver) => DropdownMenuItem(
                          value: driver.id,
                          child: Text(driver.fullName),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedDriverId = value),
                    ),
                    const SizedBox(height: 24),
                    
                    // Section Paiement
                    _buildSectionTitle('Paiement'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Mode de paiement',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Sélectionner...')),
                        DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                        DropdownMenuItem(value: 'wave', child: Text('Wave')),
                        DropdownMenuItem(value: 'orange_money', child: Text('Orange Money')),
                        DropdownMenuItem(value: 'card', child: Text('Carte bancaire')),
                      ],
                      onChanged: (value) => setState(() => _selectedPaymentMethod = value),
                    ),
                    const SizedBox(height: 24),
                    
                    // Section Médias
                    _buildMediaSection(),
                    const SizedBox(height: 24),
                    
                    // Numéro de suivi (uniquement pour les nouveaux colis)
                    if (!widget.isEditing) ...[
                      CustomTextField(
                        controller: _trackingNumberController,
                        label: 'Numéro de suivi',
                        prefixIcon: Icons.numbers,
                        readOnly: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    CustomButton(
                      text: widget.isEditing ? 'Modifier' : 'Créer',
                      onPressed: _save,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF0B6E3A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}