// lib/screens/parcel/free_parcels_screen.dart
// ignore_for_file: prefer_const_constructors, unused_import, unused_element

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/models/user.dart';
import 'package:procolis/providers/auth_provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/parcel.dart';
import '../../providers/parcel_provider.dart';
import 'new_parcel_screen.dart';
import 'parcel_detail_screen.dart';

class FreeParcelsScreen extends ConsumerStatefulWidget {
  const FreeParcelsScreen({super.key});

  @override
  ConsumerState<FreeParcelsScreen> createState() => _FreeParcelsScreenState();
}

class _FreeParcelsScreenState extends ConsumerState<FreeParcelsScreen> {
  String _filter = 'all'; // all, pending, accepted, rejected
  String _sortBy = 'price_desc'; // price_desc, price_asc, date_desc, date_asc

  @override
  void initState() {
    super.initState();
    _loadFreeParcels();
  }

  void _loadFreeParcels() {
    Future.microtask(() {
      ref.read(parcelProvider.notifier).loadFreeParcels();
    });
  }

  List<Parcel> _getFilteredAndSortedParcels(List<Parcel> parcels) {
    List<Parcel> filtered = [...parcels];
    
    // Filtrage
    switch (_filter) {
      case 'pending':
        filtered = filtered.where((p) => p.bids.isEmpty).toList();
        break;
      case 'accepted':
        filtered = filtered.where((p) => p.selectedBid != null).toList();
        break;
      case 'rejected':
        filtered = filtered.where((p) => p.bids.isNotEmpty && p.selectedBid == null).toList();
        break;
      default:
        break;
    }
    
    // Tri
    switch (_sortBy) {
      case 'price_desc':
        filtered.sort((a, b) => (b.proposedPrice ?? 0).compareTo(a.proposedPrice ?? 0));
        break;
      case 'price_asc':
        filtered.sort((a, b) => (a.proposedPrice ?? 0).compareTo(b.proposedPrice ?? 0));
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final parcelState = ref.watch(parcelProvider);
    final freeParcels = parcelState.freeParcels;
    final authState = ref.watch(authProvider);
    final isDriver = authState.user?.role == UserRole.driver;
    final filteredParcels = _getFilteredAndSortedParcels(freeParcels);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Libre Service',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2B3C),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de filtres et tri
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        isExpanded: true,
                        icon: Icon(Icons.filter_list, size: 18, color: Colors.grey.shade600),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('📦 Tous')),
                          const DropdownMenuItem(value: 'pending', child: Text('⏳ Sans offres')),
                          const DropdownMenuItem(value: 'accepted', child: Text('✅ Acceptés')),
                          const DropdownMenuItem(value: 'rejected', child: Text('❌ Sans réponse')),
                        ],
                        onChanged: (value) {
                          setState(() => _filter = value!);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        icon: Icon(Icons.sort, size: 18, color: Colors.grey.shade600),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        items: [
                          const DropdownMenuItem(value: 'price_desc', child: Text('💰 Prix décroissant')),
                          const DropdownMenuItem(value: 'price_asc', child: Text('💰 Prix croissant')),
                          const DropdownMenuItem(value: 'date_desc', child: Text('📅 Plus récent')),
                          const DropdownMenuItem(value: 'date_asc', child: Text('📅 Plus ancien')),
                        ],
                        onChanged: (value) {
                          setState(() => _sortBy = value!);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadFreeParcels(),
              color: const Color(0xFF0B6E3A),
              backgroundColor: Colors.white,
              child: parcelState.isLoadingFreeParcels
                  ? const Center(child: CircularProgressIndicator())
                  : filteredParcels.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredParcels.length,
                          itemBuilder: (context, index) {
                            final parcel = filteredParcels[index];
                            return _FreeParcelCard(
                              parcel: parcel,
                              isDriver: isDriver,
                              currentDriverId: authState.user?.id,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0B6E3A).withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _filter != 'all' ? Icons.filter_alt : Icons.inbox,
                size: 48,
                color: const Color(0xFF0B6E3A),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _filter != 'all' ? 'Aucun résultat' : 'Aucun colis en libre service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filter != 'all' 
                  ? 'Essayez de modifier vos filtres'
                  : 'Les colis mis en libre service apparaîtront ici',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Comment ça marche ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le libre service permet aux chauffeurs de :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('1. Voir votre colis et son itinéraire'),
            _buildInfoRow('2. Voir les photos et vidéos du colis'),
            _buildInfoRow('3. Faire des offres de prix'),
            _buildInfoRow('4. Proposer leurs services'),
            const SizedBox(height: 12),
            const Text(
              'Vous pourrez :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('• Comparer les offres des chauffeurs'),
            _buildInfoRow('• Voir les profils des chauffeurs'),
            _buildInfoRow('• Négocier les prix'),
            _buildInfoRow('• Choisir le chauffeur qui vous convient'),
            const SizedBox(height: 12),
            Text(
              'C\'est comme une enchère pour votre colis !',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: const Color(0xFF0B6E3A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text),
    );
  }
}

// ==================== CARTE COLIS ====================
class _FreeParcelCard extends StatelessWidget {
  final Parcel parcel;
  final bool isDriver;
  final String? currentDriverId;

  const _FreeParcelCard({
    required this.parcel,
    this.isDriver = false,
    this.currentDriverId,
  });

  bool _hasDriverMadeBid() {
    if (!isDriver || currentDriverId == null || currentDriverId!.isEmpty) {
      return false;
    }
    final cleanCurrentId = currentDriverId!.trim().toLowerCase();
    return parcel.bids.any((bid) => bid.driverId.trim().toLowerCase() == cleanCurrentId);
  }

  Bid? _getDriverBid() {
    if (!isDriver || currentDriverId == null || currentDriverId!.isEmpty) {
      return null;
    }
    final cleanCurrentId = currentDriverId!.trim().toLowerCase();
    try {
      return parcel.bids.firstWhere(
        (bid) => bid.driverId.trim().toLowerCase() == cleanCurrentId,
      );
    } catch (e) {
      return null;
    }
  }

  void _showMakeBidDialog(BuildContext context) {
    final priceController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Faire une offre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Prix proposé (FCFA)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              final currentDriverId = authState.user?.id ?? '';
              final driverName = authState.user?.fullName ?? '';
              final driverPhone = authState.user?.phone ?? '';
              
              return ElevatedButton(
                onPressed: () async {
                  final price = double.tryParse(priceController.text);
                  if (price == null || price <= 0) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Veuillez entrer un prix valide')),
                      );
                    }
                    return;
                  }

                  final bidData = {
                    'price': price,
                    'message': messageController.text,
                    'driverId': currentDriverId,
                    'driverName': driverName,
                    'driverPhone': driverPhone,
                  };

                  final result = await ref.read(parcelProvider.notifier).makeBid(
                    parcel.id,
                    bidData,
                  );

                  if (dialogContext.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Offre envoyée avec succès !')),
                      );
                      ref.read(parcelProvider.notifier).loadFreeParcels();
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? "Erreur lors de l'envoi de l'offre")),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6E3A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Envoyer'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = parcel.photoUrls.isNotEmpty;
    final hasVideos = parcel.videoUrls.isNotEmpty;
    final hasMadeBid = _hasDriverMadeBid();
    final myBid = _getDriverBid();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FreeParcelDetailsScreen(parcel: parcel),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aperçu des médias
                if (hasPhotos || hasVideos)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        image: hasPhotos
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(parcel.photoUrls.first),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey.shade200,
                      ),
                      child: Stack(
                        children: [
                          if (hasVideos)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.videocam, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${parcel.videoUrls.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (hasPhotos && parcel.photoUrls.length > 1)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_library, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${parcel.photoUrls.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.purple.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gavel, size: 12, color: Colors.purple[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'À marchander',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (parcel.bids.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${parcel.bids.length} offre(s)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Message si offre déjà envoyée
                      if (isDriver && hasMadeBid)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withAlpha(30)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Offre déjà envoyée - ${myBid?.formattedPrice ?? ""}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Numéro de suivi
                      Text(
                        parcel.trackingNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Color(0xFF1A2B3C),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Itinéraire
                      Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              parcel.departureGarageName,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Column(
                          children: [
                            Container(width: 2, height: 12, color: Colors.grey.shade300),
                            Icon(Icons.arrow_downward, size: 10, color: Colors.grey.shade400),
                            Container(width: 2, height: 12, color: Colors.grey.shade300),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 10, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              parcel.arrivalGarageName ?? "Non spécifié",
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description et poids
                      Row(
                        children: [
                          Icon(Icons.description, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              parcel.description,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.fitness_center, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            parcel.formattedWeight,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Prix suggéré
                      if (parcel.proposedPrice != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_money, size: 14, color: Colors.amber[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Prix suggéré: ${parcel.formattedProposedPrice}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bouton d'action
          if (isDriver)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: hasMadeBid
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: Icon(Icons.check_circle, color: Colors.orange[700], size: 18),
                        label: Text(
                          'Offre envoyée - ${myBid?.formattedPrice ?? ""}',
                          style: TextStyle(color: Colors.orange[700], fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange[300]!),
                          backgroundColor: Colors.orange.withAlpha(20),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _showMakeBidDialog(context),
                        icon: const Icon(Icons.attach_money, size: 18),
                        label: const Text('Faire une offre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B6E3A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== DÉTAILS COLIS ====================
class FreeParcelDetailsScreen extends ConsumerStatefulWidget {
  final Parcel parcel;

  const FreeParcelDetailsScreen({super.key, required this.parcel});

  @override
  ConsumerState<FreeParcelDetailsScreen> createState() =>
      _FreeParcelDetailsScreenState();
}

class _FreeParcelDetailsScreenState
    extends ConsumerState<FreeParcelDetailsScreen> {
  bool _isProcessing = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingAudioUrl;
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _videoInitialized = {};

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeVideoController(String url, String id) async {
    if (kIsWeb) {
      setState(() {
        _videoInitialized[id] = true;
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (mounted) {
        setState(() {
          _videoControllers[id] = controller;
          _videoInitialized[id] = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement vidéo: $e');
      setState(() {
        _videoInitialized[id] = true;
      });
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      if (_currentlyPlayingAudioUrl == audioUrl) {
        await _audioPlayer.stop();
        setState(() => _currentlyPlayingAudioUrl = null);
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(audioUrl));
        setState(() => _currentlyPlayingAudioUrl = audioUrl);
      }
    } catch (e) {
      debugPrint('Erreur lecture audio: $e');
    }
  }

  Future<void> _acceptBid(Bid bid) async {
    setState(() => _isProcessing = true);
    final success = await ref.read(parcelProvider.notifier).acceptBid(
          widget.parcel.id,
          bid.id,
        );
    setState(() => _isProcessing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Offre de ${bid.driverName} acceptée'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      await ref.read(parcelProvider.notifier).loadFreeParcels();
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de l\'acceptation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectBid(Bid bid) async {
    setState(() => _isProcessing = true);
    final success = await ref.read(parcelProvider.notifier).rejectBid(
          widget.parcel.id,
          bid.id,
        );
    setState(() => _isProcessing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Offre de ${bid.driverName} refusée'),
          backgroundColor: Colors.orange,
        ),
      );
      await ref.read(parcelProvider.notifier).loadFreeParcels();
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcel = widget.parcel;
    final authState = ref.watch(authProvider);
    final currentDriverId = authState.user?.id;
    final isDriver = authState.user?.role == UserRole.driver;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          parcel.trackingNumber,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2B3C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainCard(parcel),
                  const SizedBox(height: 16),
                  _buildInfoCard(parcel),
                  const SizedBox(height: 16),
                  _buildReceiverCard(parcel),
                  const SizedBox(height: 16),
                  _buildBidsSection(parcel, isDriver, currentDriverId),
                ],
              ),
            ),
    );
  }

  Widget _buildMainCard(Parcel parcel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [parcel.status.color, parcel.status.color.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: parcel.status.color.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(parcel.statusIcon, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parcel.status.label,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(parcel.status),
                    style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.free:
        return 'En attente d\'offres';
      default:
        return status.label;
    }
  }

  Widget _buildInfoCard(Parcel parcel) {
    return _buildCard(
      title: 'Informations',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _buildInfoRow(Icons.description, 'Description', parcel.description),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.fitness_center, 'Poids', parcel.formattedWeight),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.category, 'Type', parcel.type.label),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.departure_board, 'Départ', parcel.departureGarageName),
          if (parcel.arrivalGarageName != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Arrivée', parcel.arrivalGarageName!),
          ],
          if (parcel.proposedPrice != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.attach_money, 'Prix suggéré', parcel.formattedProposedPrice, isHighlighted: true),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, 'Création', parcel.formattedDateTime),
          if (parcel.notes != null && parcel.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.note, 'Notes', parcel.notes!, isLongText: true),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiverCard(Parcel parcel) {
    return _buildCard(
      title: 'Destinataire',
      icon: Icons.person,
      child: Column(
        children: [
          _buildInfoRow(Icons.person, 'Nom', parcel.receiverName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, 'Téléphone', parcel.receiverPhone),
          if (parcel.receiverEmail != null && parcel.receiverEmail!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'Email', parcel.receiverEmail!),
          ],
          if (parcel.receiverAddress != null && parcel.receiverAddress!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Adresse', parcel.receiverAddress!),
          ],
        ],
      ),
    );
  }

  Widget _buildBidsSection(Parcel parcel, bool isDriver, String? currentDriverId) {
    List<Bid> filteredBids = [];
    
    if (isDriver) {
      if (currentDriverId != null && currentDriverId.isNotEmpty) {
        try {
          filteredBids = [parcel.bids.firstWhere((bid) => bid.driverId == currentDriverId)];
        } catch (e) {
          filteredBids = [];
        }
      }
    } else {
      filteredBids = parcel.bids;
    }
    
    if (filteredBids.isEmpty) {
      return _buildCard(
        title: isDriver ? 'Votre offre' : 'Offres',
        icon: Icons.gavel,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.hourglass_empty, size: 48, color: Colors.orange[300]),
              const SizedBox(height: 12),
              Text(
                isDriver ? 'Vous n\'avez pas encore fait d\'offre' : 'Aucune offre pour le moment',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isDriver ? 'Faites une offre pour être mis en relation' : 'Soyez patient, des offres arrivent',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildCard(
      title: isDriver ? 'Votre offre' : 'Offres des chauffeurs',
      icon: Icons.gavel,
      child: Column(
        children: filteredBids.map((bid) => _BidCard(
          bid: bid,
          onAccept: () => _acceptBid(bid),
          onReject: () => _rejectBid(bid),
          isProcessing: _isProcessing,
          isDriverBid: isDriver && bid.driverId == currentDriverId,
        )).toList(),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
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
                    color: const Color(0xFF0B6E3A).withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: const Color(0xFF0B6E3A)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2B3C)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlighted = false, bool isLongText = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B6E3A).withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF0B6E3A)),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: isHighlighted ? const Color(0xFF0B6E3A) : const Color(0xFF1A2B3C),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== CARTE OFFRE ====================
class _BidCard extends StatelessWidget {
  final Bid bid;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isProcessing;
  final bool isDriverBid;

  const _BidCard({
    required this.bid,
    required this.onAccept,
    required this.onReject,
    this.isProcessing = false,
    this.isDriverBid = false,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} à ${date.hour}h${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    final isAccepted = bid.status == BidStatus.accepted;
    final isRejected = bid.status == BidStatus.rejected;
    final isPending = bid.status == BidStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDriverBid
            ? Colors.green.withAlpha(20)
            : isAccepted
                ? Colors.green.withAlpha(15)
                : isRejected
                    ? Colors.red.withAlpha(15)
                    : Colors.grey.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: isDriverBid
            ? Border.all(color: Colors.green, width: 2)
            : isAccepted
                ? Border.all(color: Colors.green, width: 1)
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDriverBid
                    ? Colors.green
                    : (isAccepted ? Colors.green : Colors.blue),
                child: Icon(
                  isDriverBid ? Icons.star : (isAccepted ? Icons.check : Icons.person),
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bid.driverName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDriverBid ? Colors.green[700] : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDriverBid
                                ? Colors.green
                                : (isAccepted ? Colors.green : (isRejected ? Colors.red : Colors.orange)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isDriverBid ? 'VOTRE OFFRE' : bid.status.label,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(bid.driverPhone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(_formatDate(bid.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B6E3A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bid.formattedPrice,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          if (bid.message != null && bid.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(bid.message!, style: TextStyle(color: Colors.grey[700])),
            ),
          ],
          if (!isAccepted && !isRejected && !isProcessing && !isDriverBid) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B6E3A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isDriverBid && isPending)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'En attente de réponse du client',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          if (isDriverBid && isAccepted)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offre acceptée ! Le colis vous sera assigné',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          if (isDriverBid && isRejected)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offre refusée',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}