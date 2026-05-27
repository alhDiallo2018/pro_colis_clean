// mobile/lib/screens/dashboard/driver_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/models/parcel.dart';
import 'package:procolis/models/user.dart';
import 'package:procolis/services/api_service.dart';

import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
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
        return const NewParcelScreen();
      case 2:
        return const ProfileScreen();
      default:
        return _MyParcelsScreen(
            parcelState: parcelState, onRefresh: _loadData, user: user);
    }
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

  /// Format une date avec affichage "Aujourd'hui", "Hier", ou date normale
  String _formatRelativeDate(DateTime? date) {
    if (date == null) return 'Date non définie';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Aujourd\'hui';
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

  /// Format l'heure
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Format complet date + heure relative
  String _formatDateTime(DateTime date) {
    final relativeDate = _formatRelativeDate(date);
    final time = _formatTime(date);
    return '$relativeDate à $time';
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
                              _getDriverStatusText(
                                driverStatus.toString(),
                              ),
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
