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
  final _trackingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Parcel? _trackedParcel;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    // Charger les recherches récentes depuis SharedPreferences ou Hive
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

    // Suggestions basées sur le format COL-YYYYMMDD-XXXXXX
    if (query.startsWith('COL') || query.startsWith('col')) {
      suggestions.add('COL-${_getCurrentDate()}-XXXXXX');
      suggestions.add('COL-${_getYesterdayDate()}-XXXXXX');
    }

    // Suggestions basées sur les recherches récentes
    for (var search in _recentSearches) {
      if (search.toUpperCase().contains(query)) {
        suggestions.add(search);
      }
    }

    // Suggestions basées sur le format de numéro
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
        // Sauvegarder la recherche
        _saveToRecentSearches(trackingNumberToUse);
        // Fermer le clavier
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

  // Vérifier si une étape est complétée
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
      {
        'status': 'in_transit',
        'label': 'En transit',
        'icon': Icons.transfer_within_a_station
      },
      {'status': 'arrived', 'label': 'Arrivé', 'icon': Icons.location_on},
      {
        'status': 'out_for_delivery',
        'label': 'En livraison',
        'icon': Icons.delivery_dining
      },
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
                    color: isCompleted
                        ? const Color(0xFF0B6E3A)
                        : Colors.grey.shade300,
                  ),
                  child: Icon(step['icon'] as IconData,
                      color: Colors.white, size: 20),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: isCompleted
                        ? const Color(0xFF0B6E3A)
                        : Colors.grey.shade300,
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
                        fontWeight:
                            isCompleted ? FontWeight.bold : FontWeight.normal,
                        color:
                            isCompleted ? const Color(0xFF0B6E3A) : Colors.grey,
                      ),
                    ),
                    if (isCurrent)
                      const Text(
                        'En cours',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF0B6E3A)),
                      ),
                    if (step['status'] == 'delivered' &&
                        parcel.deliveryDate != null)
                      Text(
                        _formatDate(parcel.deliveryDate!),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivre un colis'),
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
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
            // Recherche avec suggestions
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Champ de recherche avec suggestions
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return _generateSuggestions(
                                textEditingValue.text.toUpperCase());
                          },
                          onSelected: (String selection) {
                            _trackParcel(trackingNumber: selection);
                          },
                          fieldViewBuilder: (context, controller, focusNode,
                              onFieldSubmitted) {
                            return CustomTextField(
                              controller: controller,
                              label: 'Numéro de suivi',
                              prefixIcon: Icons.search,
                              hint: 'Ex: COL-20260526-ADE4B8',
                              suffixIcon: _trackingController.text.isNotEmpty
                                  ? Icons.clear
                                  : null,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: MediaQuery.of(context).size.width - 48,
                                  constraints:
                                      const BoxConstraints(maxHeight: 300),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        leading: const Icon(Icons.history,
                                            size: 20, color: Colors.grey),
                                        title: Text(
                                          option,
                                          style: const TextStyle(
                                              fontFamily: 'monospace'),
                                        ),
                                        trailing: const Icon(
                                            Icons.arrow_forward,
                                            size: 16,
                                            color: Colors.grey),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Suivre mon colis',
                          onPressed: () => _trackParcel(),
                          isLoading: _isSearching,
                        ),
                      ],
                    ),
                  ),

                  // Recherches récentes
                  if (_recentSearches.isNotEmpty &&
                      _trackedParcel == null &&
                      !_isSearching)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recherches récentes',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _recentSearches.clear();
                                  });
                                },
                                child: const Text(
                                  'Effacer',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.red),
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
                                onTap: () =>
                                    _trackParcel(trackingNumber: search),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.history,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        search,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace'),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () =>
                                            _removeRecentSearch(search),
                                        child: const Icon(Icons.close,
                                            size: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Résultat
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

  Widget _buildParcelResultCard() {
    final parcel = _trackedParcel!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    Text(
                      parcel.trackingNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: parcel.status.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        parcel.status.label,
                        style:
                            TextStyle(fontSize: 12, color: parcel.status.color),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (parcel.price != null) ...[
                      const Text('Montant',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        parcel.formattedPrice,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B6E3A)),
                      ),
                    ],
                    if (parcel.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            // Timeline
            _buildStatusTimeline(parcel),
            const Divider(height: 32),

            // SECTION: EXPÉDITEUR
            _buildSectionTitle('Expéditeur', Icons.person_outline),
            _buildInfoRow('Nom', parcel.senderName, Icons.person),
            _buildInfoRow('Téléphone', parcel.senderPhone, Icons.phone),

            const Divider(height: 16),

            // SECTION: DESTINATAIRE
            _buildSectionTitle('Destinataire', Icons.person),
            _buildInfoRow('Nom', parcel.receiverName, Icons.person),
            _buildInfoRow('Téléphone', parcel.receiverPhone, Icons.phone),
            if (parcel.receiverEmail != null &&
                parcel.receiverEmail!.isNotEmpty)
              _buildInfoRow('Email', parcel.receiverEmail!, Icons.email),
            if (parcel.receiverAddress != null &&
                parcel.receiverAddress!.isNotEmpty)
              _buildInfoRow(
                  'Adresse', parcel.receiverAddress!, Icons.location_on),

            const Divider(height: 16),

            // SECTION: DÉTAILS DU COLIS
            _buildSectionTitle('Détails du colis', Icons.inventory),
            _buildInfoRow('Description', parcel.description, Icons.description),
            _buildInfoRow(
                'Poids', parcel.formattedWeight, Icons.fitness_center),
            _buildInfoRow('Type', parcel.type.label, Icons.category),
            if (parcel.length != null ||
                parcel.width != null ||
                parcel.height != null)
              _buildInfoRow('Dimensions', _getDimensions(parcel), Icons.crop),
            if (parcel.volume > 0)
              _buildInfoRow('Volume', parcel.formattedVolume, Icons.calculate),

            const Divider(height: 16),

            // SECTION: TRAJET
            _buildSectionTitle('Trajet', Icons.route),
            _buildInfoRow('Garage départ', parcel.departureGarageName,
                Icons.departure_board),
            if (parcel.arrivalGarageName != null &&
                parcel.arrivalGarageName!.isNotEmpty)
              _buildInfoRow('Garage arrivée', parcel.arrivalGarageName!,
                  Icons.location_on),

            const Divider(height: 16),

            // SECTION: CHAUFFEUR
            if (parcel.hasDriver) ...[
              _buildSectionTitle('Chauffeur', Icons.delivery_dining),
              if (parcel.driverName != null)
                _buildInfoRow('Nom', parcel.driverName!, Icons.person),
              if (parcel.driverPhone != null)
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                          'Téléphone', parcel.driverPhone!, Icons.phone),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.call, color: Colors.green, size: 20),
                      onPressed: () => _makePhoneCall(parcel.driverPhone!),
                    ),
                  ],
                ),
              const Divider(height: 16),
            ],

            // SECTION: DATES
            _buildSectionTitle('Dates importantes', Icons.calendar_today),
            _buildInfoRow(
                'Création', _formatDate(parcel.createdAt), Icons.create),
            if (parcel.pickupDate != null)
              _buildInfoRow('Ramassage', _formatDate(parcel.pickupDate!),
                  Icons.inventory),
            if (parcel.deliveryDate != null)
              _buildInfoRow('Livraison', _formatDate(parcel.deliveryDate!),
                  Icons.check_circle),
            if (parcel.estimatedDeliveryDate != null)
              _buildInfoRow('Estimée',
                  _formatDate(parcel.estimatedDeliveryDate!), Icons.schedule),

            const Divider(height: 16),

            // SECTION: OPTIONS
            _buildSectionTitle('Options', Icons.settings),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOptionChip('Urgent', parcel.isUrgent, Colors.red),
                _buildOptionChip('Assuré', parcel.isInsured, Colors.blue),
                _buildOptionChip('Payé', parcel.isPaid, Colors.green),
                _buildOptionChip('Chauffeur', parcel.hasDriver, Colors.orange),
                _buildOptionChip(
                    'En cours', parcel.isInProgress, Colors.purple),
                _buildOptionChip('Terminé', parcel.isFinished, Colors.teal),
              ],
            ),

            // SECTION: PHOTOS
            if (parcel.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Photos', Icons.photo_library),
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

            // SECTION: NOTES
            if (parcel.notes != null && parcel.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Notes', Icons.note),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  parcel.notes!,
                  style: const TextStyle(
                      fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Bouton Voir tous les détails
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _viewFullDetails,
                icon: const Icon(Icons.visibility),
                label: const Text('Voir tous les détails'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0B6E3A),
                  side: const BorderSide(color: Color(0xFF0B6E3A)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B6E3A),
              side: const BorderSide(color: Color(0xFF0B6E3A)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _downloadReceipt,
            icon: const Icon(Icons.download),
            label: const Text('Reçu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B6E3A),
              side: const BorderSide(color: Color(0xFF0B6E3A)),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== WIDGETS PERSONNALISÉS ====================

  Widget _buildSectionTitle(String title, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? const Color(0xFF0B6E3A)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color ?? const Color(0xFF0B6E3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(25) : Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isActive ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getDimensions(Parcel parcel) {
    final parts = <String>[];
    if (parcel.length != null) parts.add('L: ${parcel.length} cm');
    if (parcel.width != null) parts.add('l: ${parcel.width} cm');
    if (parcel.height != null) parts.add('H: ${parcel.height} cm');
    return parts.join(' x ');
  }
}
