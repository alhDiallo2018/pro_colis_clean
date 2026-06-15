// ignore_for_file: unused_import, unused_element

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/screens/parcel/parcel_detail_screen.dart';

import '../../models/parcel.dart';
import '../../providers/parcel_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class TrackParcelScreen extends ConsumerStatefulWidget {
  const TrackParcelScreen({super.key});

  @override
  ConsumerState<TrackParcelScreen> createState() => _TrackParcelScreenState();
}

class _TrackParcelScreenState extends ConsumerState<TrackParcelScreen> {
  final TextEditingController _trackingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSearching = false;
  Parcel? _trackedParcel;
  List<String> _recentSearches = [];
  String? _currentlyPlayingAudioUrl;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioListeners() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _currentlyPlayingAudioUrl = null;
        });
      }
    });
  }

  void _loadRecentSearches() {
    // Charger les recherches récentes depuis SharedPreferences
    // Pour l'instant, on utilise une liste en mémoire
    _recentSearches = [
      'COL-20260526-ADE4B8',
      'COL-20260525-933934',
      'COL-20260524-7D6FDD',
    ];
    setState(() {});
  }

  List<String> _generateSuggestions(String query) {
    final suggestions = <String>{};

    if (query.startsWith('COL') || query.startsWith('col')) {
      suggestions.add('COL-${_getCurrentDate()}-XXXXXX');
      suggestions.add('COL-${_getYesterdayDate()}-XXXXXX');
    }

    for (var search in _recentSearches) {
      if (search.toUpperCase().contains(query.toUpperCase())) {
        suggestions.add(search);
      }
    }

    if (query.length >= 4 && query.length <= 8) {
      suggestions.add('COL-${_getCurrentDate()}-$query');
      suggestions.add('COL-${_getYesterdayDate()}-$query');
    }

    return suggestions.take(5).toList();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  String _getYesterdayDate() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}${yesterday.month.toString().padLeft(2, '0')}${yesterday.day.toString().padLeft(2, '0')}';
  }

  Future<void> _trackParcel({String? trackingNumber}) async {
    final trackingNumberToUse =
        trackingNumber ?? _trackingController.text.trim();
    if (trackingNumberToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numéro de suivi')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final parcel = await ref
          .read(parcelProvider.notifier)
          .trackParcel(trackingNumberToUse);
      setState(() {
        _isSearching = false;
        _trackedParcel = parcel;
      });

      if (parcel != null) {
        _saveToRecentSearches(trackingNumberToUse);
        _focusNode.unfocus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Colis ${parcel.trackingNumber} trouvé'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colis non trouvé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _saveToRecentSearches(String trackingNumber) {
    if (!_recentSearches.contains(trackingNumber)) {
      _recentSearches.insert(0, trackingNumber);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
      setState(() {});
    }
  }

  void _clearSearch() {
    _trackingController.clear();
    setState(() {
      _trackedParcel = null;
    });
    _focusNode.requestFocus();
  }

  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches.remove(search);
    });
  }

  bool _isStepCompleted(Parcel parcel, String stepStatus) {
    final statusOrder = [
      'pending',
      'confirmed',
      'picked_up',
      'in_transit',
      'arrived',
      'out_for_delivery',
      'delivered'
    ];

    final currentIndex = statusOrder.indexOf(parcel.status.value);
    final stepIndex = statusOrder.indexOf(stepStatus);

    return currentIndex >= stepIndex;
  }

  Widget _buildStatusTimeline(Parcel parcel) {
    const steps = [
      {'status': 'pending', 'label': 'Création', 'icon': Icons.create},
      {'status': 'confirmed', 'label': 'Confirmé', 'icon': Icons.check_circle},
      {'status': 'picked_up', 'label': 'Ramassé', 'icon': Icons.local_shipping},
      {'status': 'in_transit', 'label': 'En transit', 'icon': Icons.transfer_within_a_station},
      {'status': 'arrived', 'label': 'Arrivé', 'icon': Icons.location_on},
      {'status': 'out_for_delivery', 'label': 'En livraison', 'icon': Icons.delivery_dining},
      {'status': 'delivered', 'label': 'Livré', 'icon': Icons.check_circle},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = _isStepCompleted(parcel, step['status'] as String);
        final isLast = index == steps.length - 1;
        final isCurrent = parcel.status.value == step['status'];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? const Color(0xFF0B6E3A) : Colors.grey.shade300,
                  ),
                  child: Icon(step['icon'] as IconData, color: Colors.white, size: 20),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: isCompleted ? const Color(0xFF0B6E3A) : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? const Color(0xFF0B6E3A) : Colors.grey,
                      ),
                    ),
                    if (isCurrent)
                      const Text(
                        'En cours',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0B6E3A)),
                      ),
                    if (step['status'] == 'delivered' && parcel.deliveryDate != null)
                      Text(
                        _formatDate(parcel.deliveryDate!),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _viewFullDetails() {
    if (_trackedParcel != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParcelDetailScreen(parcel: _trackedParcel!),
        ),
      );
    }
  }

  void _shareTrackingNumber() {
    if (_trackedParcel != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partager: ${_trackedParcel!.trackingNumber}'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _downloadReceipt() {
    if (_trackedParcel != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléchargement du reçu en cours...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _makePhoneCall(String phoneNumber) {
    if (phoneNumber.isNotEmpty) {
      debugPrint('Appel vers: $phoneNumber');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appel vers $phoneNumber'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      if (_currentlyPlayingAudioUrl == audioUrl) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingAudioUrl = null;
        });
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(audioUrl));
        setState(() {
          _currentlyPlayingAudioUrl = audioUrl;
        });
      }
    } catch (e) {
      debugPrint('Erreur lecture audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Suivre un colis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2B3C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_trackedParcel != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSearch,
              tooltip: 'Nouvelle recherche',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Carte de recherche modernisée
            _buildSearchCard(),
            const SizedBox(height: 16),

            // Résultat de la recherche
            if (_trackedParcel != null) ...[
              _buildParcelResultCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
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
          children: [
            // Icône de recherche
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B6E3A).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 32,
                color: Color(0xFF0B6E3A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Suivez votre colis en temps réel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Entrez votre numéro de suivi pour connaître la localisation de votre colis',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Champ de recherche
            TextField(
              controller: _trackingController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Ex: COL-20260526-ADE4B8',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0B6E3A)),
                suffixIcon: _trackingController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _trackingController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF0B6E3A), width: 1.5),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              onSubmitted: (_) => _trackParcel(),
            ),
            const SizedBox(height: 16),
            
            // Bouton de recherche
            CustomButton(
              text: 'Suivre mon colis',
              onPressed: () => _trackParcel(),
              isLoading: _isSearching,
            ),
            
            // Suggestions en temps réel
            if (_trackingController.text.isNotEmpty &&
                _generateSuggestions(_trackingController.text).isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Suggestions:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ..._generateSuggestions(_trackingController.text).map(
                      (suggestion) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.history, size: 18, color: Color(0xFF0B6E3A)),
                        title: Text(
                          suggestion,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                        trailing: const Icon(Icons.arrow_forward, size: 18),
                        onTap: () {
                          _trackingController.text = suggestion;
                          _trackParcel();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            
            // Recherches récentes
            if (_recentSearches.isNotEmpty &&
                _trackedParcel == null &&
                !_isSearching &&
                _trackingController.text.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recherches récentes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _recentSearches.clear();
                          });
                        },
                        child: const Text(
                          'Effacer tout',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentSearches.map((search) {
                      return GestureDetector(
                        onTap: () => _trackParcel(trackingNumber: search),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                search,
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _removeRecentSearch(search),
                                child: const Icon(Icons.close, size: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelResultCard() {
    final parcel = _trackedParcel!;

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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: parcel.status.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        parcel.status.label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: parcel.status.color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      parcel.trackingNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                  ],
                ),
                if (parcel.price != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B6E3A).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          parcel.formattedPrice,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B6E3A),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Timeline
            _buildStatusTimeline(parcel),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Informations principales
            _buildInfoRow(Icons.person_outline, 'Expéditeur', parcel.senderName),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Destinataire', parcel.receiverName),
            const SizedBox(height: 12),
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
            if (parcel.hasDriver) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.delivery_dining, 'Chauffeur', parcel.driverName ?? 'Non assigné'),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Section options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOptionChip('Urgent', parcel.isUrgent, Colors.red),
                _buildOptionChip('Assuré', parcel.isInsured, Colors.blue),
                _buildOptionChip('Payé', parcel.isPaid, Colors.green),
                _buildOptionChip('Chauffeur', parcel.hasDriver, Colors.orange),
                _buildOptionChip('En cours', parcel.isInProgress, Colors.purple),
                _buildOptionChip('Terminé', parcel.isFinished, Colors.teal),
              ],
            ),

            // Photos
            if (parcel.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2B3C))),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: parcel.photoUrls.length,
                  itemBuilder: (context, index) {
                    return _buildPhotoThumbnail(parcel.photoUrls[index]);
                  },
                ),
              ),
            ],

            // Messages vocaux
            if (parcel.audioUrls.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Messages vocaux', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2B3C))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: parcel.audioUrls.map((audioUrl) {
                  final isPlaying = _currentlyPlayingAudioUrl == audioUrl;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.stop : Icons.play_arrow,
                            size: 18,
                            color: const Color(0xFF0B6E3A),
                          ),
                          onPressed: () => _playAudio(audioUrl),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        const Text('Message vocal', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Bouton Voir tous les détails
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _viewFullDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6E3A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Voir tous les détails',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareTrackingNumber,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Partager'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B6E3A),
              side: const BorderSide(color: Color(0xFF0B6E3A)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _downloadReceipt,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Reçu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B6E3A),
              side: const BorderSide(color: Color(0xFF0B6E3A)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
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
          width: 90,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A2B3C)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(String url) {
    final fullUrl = url.startsWith('http') ? url : 'https://procolis-backend.onrender.com$url';
    return GestureDetector(
      onTap: () => _showPhotoDialog(fullUrl),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
          image: DecorationImage(
            image: NetworkImage(fullUrl),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) =>
                debugPrint('Erreur chargement image: $exception'),
          ),
        ),
      ),
    );
  }

  void _showPhotoDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(25) : Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            size: 12,
            color: isActive ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}