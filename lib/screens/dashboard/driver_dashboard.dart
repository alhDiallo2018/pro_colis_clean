// mobile/lib/screens/dashboard/driver_dashboard.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/models/parcel.dart';
import 'package:procolis/models/user.dart';
import 'package:procolis/services/api_service.dart';

import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
import '../parcel/free_parcels_screen.dart';
import '../parcel/new_parcel_screen.dart';
import '../parcel/parcel_detail_screen.dart';
import '../profile/profile_screen.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(parcelProvider.notifier).loadDriverParcels();
      ref.read(parcelProvider.notifier).loadFreeParcels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final parcelState = ref.watch(parcelProvider);

    return Scaffold(
      body: _getScreen(_selectedIndex, user, parcelState),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF0B6E3A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping), label: 'Mes colis'),
          BottomNavigationBarItem(
              icon: Icon(Icons.gavel), label: 'Libre service'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Envoyer'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _getScreen(int index, User? user, ParcelState parcelState) {
    switch (index) {
      case 0:
        return _MyParcelsScreen(
            parcelState: parcelState, onRefresh: _loadData, user: user);
      case 1:
        return const FreeParcelsForDriversScreen();
      case 2:
        return const NewParcelScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _MyParcelsScreen(
            parcelState: parcelState, onRefresh: _loadData, user: user);
    }
  }
}

// Écran pour les colis en libre service (vue chauffeur)
class FreeParcelsForDriversScreen extends ConsumerStatefulWidget {
  const FreeParcelsForDriversScreen({super.key});

  @override
  ConsumerState<FreeParcelsForDriversScreen> createState() => _FreeParcelsForDriversScreenState();
}

class _FreeParcelsForDriversScreenState extends ConsumerState<FreeParcelsForDriversScreen> {
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

  @override
  Widget build(BuildContext context) {
    final parcelState = ref.watch(parcelProvider);
    final freeParcels = parcelState.freeParcels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colis en Libre Service'),
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(parcelProvider.notifier).loadFreeParcels();
        },
        child: parcelState.isLoadingFreeParcels
            ? const Center(child: CircularProgressIndicator())
            : freeParcels.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: freeParcels.length,
                    itemBuilder: (context, index) {
                      final parcel = freeParcels[index];
                      return _DriverFreeParcelCard(parcel: parcel);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey.withAlpha(100)),
          const SizedBox(height: 16),
          const Text(
            'Aucun colis en libre service',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Les clients n\'ont pas encore mis de colis en libre service',
            style: TextStyle(color: Colors.grey.withAlpha(150)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment faire une offre ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pour faire une offre sur un colis :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('1. Cliquez sur "Faire une offre"'),
            _buildInfoRow('2. Proposez votre prix'),
            _buildInfoRow('3. Ajoutez un message si souhaité'),
            const SizedBox(height: 12),
            const Text(
              'Si votre offre est acceptée :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('• Vous serez notifié'),
            _buildInfoRow('• Le colis vous sera assigné'),
            _buildInfoRow('• Vous pourrez suivre la livraison'),
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

// Carte pour les colis en libre service (version chauffeur avec vérification des offres)
class _DriverFreeParcelCard extends ConsumerStatefulWidget {
  final Parcel parcel;

  const _DriverFreeParcelCard({required this.parcel});

  @override
  ConsumerState<_DriverFreeParcelCard> createState() => _DriverFreeParcelCardState();
}

class _DriverFreeParcelCardState extends ConsumerState<_DriverFreeParcelCard> {
  bool _isMakingOffer = false;
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Vérifie si le chauffeur actuel a déjà fait une offre
  bool _hasDriverMadeBid() {
    final authState = ref.read(authProvider);
    final currentDriverId = authState.user?.id;
    
    if (currentDriverId == null || currentDriverId.isEmpty) return false;
    
    // Nettoyer les IDs pour la comparaison
    final cleanCurrentId = currentDriverId.trim().toLowerCase();
    
    return widget.parcel.bids.any((bid) {
      final cleanBidId = bid.driverId.trim().toLowerCase();
      return cleanBidId == cleanCurrentId;
    });
  }

  /// Récupère l'offre du chauffeur actuel
  Bid? _getDriverBid() {
    final authState = ref.read(authProvider);
    final currentDriverId = authState.user?.id;
    
    if (currentDriverId == null || currentDriverId.isEmpty) return null;
    
    final cleanCurrentId = currentDriverId.trim().toLowerCase();
    
    try {
      return widget.parcel.bids.firstWhere((bid) => 
        bid.driverId.trim().toLowerCase() == cleanCurrentId
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _makeOffer() async {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un prix valide'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isMakingOffer = true);

    final authState = ref.read(authProvider);
    final currentUser = authState.user;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: utilisateur non connecté'), backgroundColor: Colors.red),
      );
      setState(() => _isMakingOffer = false);
      return;
    }

    final result = await ref.read(parcelProvider.notifier).makeBid(
      widget.parcel.id,
      {
        'price': price,
        'message': _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
        'driverId': currentUser.id,
        'driverName': currentUser.fullName,
        'driverPhone': currentUser.phone,
      },
    );

    setState(() => _isMakingOffer = false);

    if (result['success'] == true && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offre de ${price.toStringAsFixed(0)} FCFA envoyée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      // Recharger pour mettre à jour l'état
      ref.read(parcelProvider.notifier).loadFreeParcels();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors de l\'envoi de l\'offre'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOfferDialog() {
    // Vérifier si une offre existe déjà
    if (_hasDriverMadeBid()) {
      final myBid = _getDriverBid();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez déjà fait une offre de ${myBid?.formattedPrice ?? ""} sur ce colis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    _priceController.clear();
    _messageController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faire une offre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Colis: ${widget.parcel.trackingNumber}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Votre offre (FCFA)',
                hintText: 'Ex: 5000',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optionnel)',
                hintText: 'Ajoutez un message au client...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (widget.parcel.proposedPrice != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prix suggéré par le client: ${widget.parcel.formattedProposedPrice}',
                        style: TextStyle(fontSize: 12, color: Colors.amber[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _makeOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B6E3A),
            ),
            child: const Text('Envoyer l\'offre'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FreeParcelDetailsScreen(parcel: widget.parcel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parcel = widget.parcel;
    final hasMadeBid = _hasDriverMadeBid();
    final myBid = _getDriverBid();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _navigateToDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gavel, size: 14, color: Colors.purple[700]),
                        const SizedBox(width: 4),
                        Text(
                          'À marchander',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    parcel.trackingNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Message si le chauffeur a déjà fait une offre
              if (hasMadeBid)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '✅ Vous avez déjà fait une offre de ${myBid?.formattedPrice ?? ""} sur ce colis',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'De: ${parcel.departureGarageName}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'À: ${parcel.arrivalGarageName ?? "Non spécifié"}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.rule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    parcel.formattedWeight,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.description, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      parcel.description,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (parcel.proposedPrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(15),
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
              const SizedBox(height: 16),
              if (_isMakingOffer)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: hasMadeBid
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: Icon(Icons.check_circle, color: Colors.orange[700]),
                          label: Text(
                            '✅ Offre déjà envoyée - ${myBid?.formattedPrice ?? ""}',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.orange[300]!),
                            backgroundColor: Colors.orange.withAlpha(20),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _showOfferDialog,
                          icon: const Icon(Icons.gavel, size: 18),
                          label: const Text('💰 Faire une offre'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B6E3A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyParcelsScreen extends StatefulWidget {
  final ParcelState parcelState;
  final VoidCallback onRefresh;
  final User? user;

  const _MyParcelsScreen({
    required this.parcelState,
    required this.onRefresh,
    this.user,
  });

  @override
  State<_MyParcelsScreen> createState() => _MyParcelsScreenState();
}

class _MyParcelsScreenState extends State<_MyParcelsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  User? _freshUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFreshUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFreshUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _freshUser = user;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement user: $e');
    }
  }

  List<Parcel> get _pendingParcels {
    return widget.parcelState.parcels
        .where((p) =>
            p.status == ParcelStatus.pending ||
            p.status == ParcelStatus.confirmed)
        .toList();
  }

  List<Parcel> get _activeDeliveries {
    return widget.parcelState.parcels
        .where((p) =>
            p.status == ParcelStatus.pickedUp ||
            p.status == ParcelStatus.inTransit ||
            p.status == ParcelStatus.arrived ||
            p.status == ParcelStatus.outForDelivery)
        .toList();
  }

  List<Parcel> get _completedParcels {
    return widget.parcelState.parcels.where((p) => p.isDelivered).toList();
  }

  List<Parcel> get _myParcels {
    return widget.parcelState.parcels.toList();
  }

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/uploads/')) {
      return 'https://procolis-backend.onrender.com$url';
    }
    return url;
  }

  String _getDriverStatusText(String? status) {
    if (status == null || status.isEmpty) {
      return '🟢 Disponible';
    }
    switch (status.toLowerCase()) {
      case 'available':
        return '🟢 Disponible';
      case 'busy':
        return '🔴 En livraison';
      case 'offline':
        return '⚪ Hors ligne';
      default:
        return '🟢 Disponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUser = _freshUser ?? widget.user;
    final userName = displayUser?.fullName.split(' ').first ?? "Chauffeur";
    final profilePhoto = displayUser?.profilePhoto;
    final fullImageUrl = _getFullImageUrl(profilePhoto);
    final driverStatus = displayUser?.driverStatus ?? 'available';

    return RefreshIndicator(
      onRefresh: () async {
        await _loadFreshUser();
        widget.onRefresh();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B6E3A), Color(0xFF168A48)],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          ).then((_) {
                            _loadFreshUser();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: fullImageUrl.isNotEmpty
                                ? Image.network(
                                    fullImageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.white.withAlpha(50),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.white.withAlpha(50),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.white.withAlpha(50),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour $userName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getDriverStatusText(driverStatus.toString()),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: Colors.green[300]),
                            const SizedBox(width: 4),
                            Text(
                              '${_activeDeliveries.length} en cours',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatItem(Icons.pending, 'Attente',
                            _pendingParcels.length, Colors.orange),
                        const SizedBox(width: 8),
                        _buildStatItem(Icons.local_shipping, 'En cours',
                            _activeDeliveries.length, Colors.blue),
                        const SizedBox(width: 8),
                        _buildStatItem(Icons.check_circle, 'Livrés',
                            _completedParcels.length, Colors.green),
                        const SizedBox(width: 8),
                        _buildStatItem(Icons.attach_money, 'Gains',
                            _calculateTotalEarnings(), Colors.amber),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF0B6E3A),
            labelColor: const Color(0xFF0B6E3A),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Tous'),
              Tab(text: 'En attente'),
              Tab(text: 'En cours'),
              Tab(text: 'Livrés'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildParcelList(_myParcels),
                _buildParcelList(_pendingParcels),
                _buildParcelList(_activeDeliveries),
                _buildParcelList(_completedParcels),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotalEarnings() {
    return _completedParcels.fold(
        0, (sum, parcel) => sum + (parcel.price?.toInt() ?? 0));
  }

  Widget _buildStatItem(IconData icon, String label, int count, Color color) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildParcelList(List<Parcel> parcels) {
    if (widget.parcelState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (parcels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              'Aucun colis',
              style: TextStyle(color: Colors.grey.withAlpha(150)),
            ),
            const SizedBox(height: 8),
            const Text('Les colis apparaîtront ici',
                style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: parcels.length,
      itemBuilder: (context, index) {
        final parcel = parcels[index];
        return _ParcelCard(
            parcel: parcel,
            onRefresh: () {
              _loadFreshUser();
              widget.onRefresh();
            });
      },
    );
  }
}

class _ParcelCard extends StatefulWidget {
  final Parcel parcel;
  final VoidCallback onRefresh;

  const _ParcelCard({required this.parcel, required this.onRefresh});

  @override
  State<_ParcelCard> createState() => _ParcelCardState();
}

class _ParcelCardState extends State<_ParcelCard> {
  bool _isUpdating = false;

  Color _getStatusColor(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return Colors.orange;
      case ParcelStatus.free:
        return Colors.purple;
      case ParcelStatus.confirmed:
        return Colors.blue;
      case ParcelStatus.pickedUp:
        return Colors.purple;
      case ParcelStatus.inTransit:
        return Colors.indigo;
      case ParcelStatus.arrived:
        return Colors.teal;
      case ParcelStatus.outForDelivery:
        return Colors.lightBlue;
      case ParcelStatus.delivered:
        return Colors.green;
      case ParcelStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusIcon(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return '⏳';
      case ParcelStatus.free:
        return '🔓';
      case ParcelStatus.confirmed:
        return '✅';
      case ParcelStatus.pickedUp:
        return '📦';
      case ParcelStatus.inTransit:
        return '🚚';
      case ParcelStatus.arrived:
        return '📍';
      case ParcelStatus.outForDelivery:
        return '🚛';
      case ParcelStatus.delivered:
        return '🎉';
      case ParcelStatus.cancelled:
        return '❌';
    }
  }

  /// Format une date avec affichage relatif
  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return "Aujourd'hui";
    } else if (targetDate == yesterday) {
      return 'Hier';
    } else {
      final difference = today.difference(targetDate).inDays;
      if (difference < 7) {
        return 'Il y a $difference jours';
      } else if (difference < 30) {
        final weeks = (difference / 7).floor();
        return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatRelativeDate(date)} à ${_formatTime(date)}';
  }

  Future<void> _acceptDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Accepter la livraison'),
        content: Text(
            'Voulez-vous accepter la livraison du colis ${widget.parcel.trackingNumber} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus('picked_up');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final apiService = ApiService();
    try {
      await apiService.updateParcelStatus(widget.parcel.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Statut mis à jour'),
              backgroundColor: Colors.green),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _showDeliveryConfirmation() async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmation de livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirmez-vous la livraison du colis ?'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus('delivered');
    }
    notesController.dispose();
  }

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParcelDetailScreen(parcel: widget.parcel),
      ),
    ).then((_) {
      widget.onRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final parcel = widget.parcel;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _navigateToDetail,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          _getStatusIcon(parcel.status),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            parcel.trackingNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(parcel.status).withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      parcel.status.label,
                      style: TextStyle(
                          fontSize: 11,
                          color: _getStatusColor(parcel.status),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      parcel.receiverName,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      parcel.arrivalGarageName ??
                          parcel.receiverAddress ??
                          'Adresse non précisée',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.withAlpha(50)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      parcel.formattedPrice,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  if (parcel.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.flash_on, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text('URGENT',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Affichage de la date avec format relatif
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(parcel.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_isUpdating)
                _buildActionButtons()
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final parcel = widget.parcel;

    // Les colis en libre service ne sont pas affichés ici
    // Ils sont dans l'onglet dédié
    
    if (parcel.status == ParcelStatus.pending ||
        parcel.status == ParcelStatus.confirmed) {
      return _buildActionButton(
        icon: Icons.check_circle,
        label: 'Accepter',
        color: Colors.green,
        onTap: _acceptDelivery,
      );
    } else if (parcel.status == ParcelStatus.pickedUp) {
      return _buildActionButton(
        icon: Icons.directions_car,
        label: 'Démarrer',
        color: Colors.blue,
        onTap: () => _updateStatus('in_transit'),
      );
    } else if (parcel.status == ParcelStatus.inTransit) {
      return _buildActionButton(
        icon: Icons.location_on,
        label: 'Arrivé garage',
        color: Colors.orange,
        onTap: () => _updateStatus('arrived'),
      );
    } else if (parcel.status == ParcelStatus.arrived) {
      return _buildActionButton(
        icon: Icons.delivery_dining,
        label: 'Partir livraison',
        color: Colors.purple,
        onTap: () => _updateStatus('out_for_delivery'),
      );
    } else if (parcel.status == ParcelStatus.outForDelivery) {
      return _buildActionButton(
        icon: Icons.check_circle,
        label: 'Livrer',
        color: Colors.green,
        onTap: _showDeliveryConfirmation,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}