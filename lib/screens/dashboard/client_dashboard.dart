// mobile/lib/screens/dashboard/client_dashboard.dart
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, deprecated_member_use, unnecessary_this, unused_element

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/models/parcel.dart';
import 'package:procolis/models/user.dart';

import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
import '../../widgets/parcel_card.dart';
import '../parcel/free_parcels_screen.dart';
import '../parcel/new_parcel_screen.dart';
import '../parcel/parcel_detail_screen.dart';
import '../parcel/track_parcel_screen.dart';
import '../profile/profile_screen.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(parcelProvider.notifier).loadMyParcels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final parcelState = ref.watch(parcelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _getScreen(_selectedIndex, user, parcelState),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() => _selectedIndex = index);
              if (index == 2) {
                _loadData();
              }
            },
            selectedItemColor: const Color(0xFF0B6E3A),
            unselectedItemColor: Colors.grey.shade400,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline_rounded),
                label: 'Nouveau',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded),
                label: 'Suivi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.track_changes),
                label: 'Libre service',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getScreen(int index, User? user, ParcelState parcelState) {
    switch (index) {
      case 0:
        return HomeScreen(
          user: user,
          parcelState: parcelState,
          onRefresh: _loadData,
        );
      case 1:
        return const NewParcelScreen();
      case 2:
        return const TrackParcelScreen();
      case 3:
        return const FreeParcelsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return HomeScreen(
          user: user,
          parcelState: parcelState,
          onRefresh: _loadData,
        );
    }
  }
}

class HomeScreen extends StatefulWidget {
  final User? user;
  final ParcelState parcelState;
  final VoidCallback onRefresh;

  const HomeScreen({
    super.key,
    required this.user,
    required this.parcelState,
    required this.onRefresh,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filtres
  String _selectedFilter = 'all'; // all, pending, in_progress, delivered, free, cancelled
  String _sortBy = 'date_desc'; // date_desc, date_asc, price_desc, price_asc
  
  // Audio player pour les messages vocaux
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingAudioUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  List<Parcel> get _myParcels {
    if (widget.user == null) return [];
    return widget.parcelState.parcels.where((parcel) {
      final isSender = parcel.senderName == widget.user!.fullName ||
          parcel.senderPhone == widget.user!.phone ||
          parcel.senderEmail == widget.user!.email;
      final isReceiver = parcel.receiverName == widget.user!.fullName ||
          parcel.receiverPhone == widget.user!.phone ||
          parcel.receiverEmail == widget.user!.email;
      return isSender || isReceiver;
    }).toList();
  }

  List<Parcel> get _sentParcels {
    if (widget.user == null) return [];
    return _myParcels.where((parcel) {
      return parcel.senderName == widget.user!.fullName ||
          parcel.senderPhone == widget.user!.phone ||
          parcel.senderEmail == widget.user!.email;
    }).toList();
  }

  List<Parcel> get _receivedParcels {
    if (widget.user == null) return [];
    return _myParcels.where((parcel) {
      return parcel.receiverName == widget.user!.fullName ||
          parcel.receiverPhone == widget.user!.phone ||
          parcel.receiverEmail == widget.user!.email;
    }).toList();
  }

  // Appliquer les filtres et le tri
  List<Parcel> _filterAndSortParcels(List<Parcel> parcels) {
    List<Parcel> filtered = [...parcels];
    
    // Application des filtres
    switch (_selectedFilter) {
      case 'pending':
        filtered = filtered.where((p) => p.isPending).toList();
        break;
      case 'in_progress':
        filtered = filtered.where((p) => p.isInProgress).toList();
        break;
      case 'delivered':
        filtered = filtered.where((p) => p.isDelivered).toList();
        break;
      case 'free':
        filtered = filtered.where((p) => p.isFree).toList();
        break;
      case 'cancelled':
        filtered = filtered.where((p) => p.isCancelled).toList();
        break;
      default:
        break;
    }
    
    // Application du tri
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_desc':
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'price_asc':
        filtered.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B6E3A)),
        ),
      );
    }

    final myParcels = _filterAndSortParcels(_myParcels);
    final sentParcels = _filterAndSortParcels(_sentParcels);
    final receivedParcels = _filterAndSortParcels(_receivedParcels);

    final pendingCount = _myParcels.where((p) => p.isPending).length;
    final inProgressCount = _myParcels.where((p) => p.isInProgress).length;
    final deliveredCount = _myParcels.where((p) => p.isDelivered).length;
    final freeWithBidsCount = _myParcels
        .where((p) => p.isFreeForBidding && p.hasBids)
        .length;

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: const Color(0xFF0B6E3A),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeader(widget.user!, freeWithBidsCount),
                _buildStatsCards(pendingCount, inProgressCount, deliveredCount),
                _buildFiltersRow(),
                _buildTabBar(),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: _buildDynamicParcelList(
              context,
              _tabController.index == 0
                  ? myParcels
                  : (_tabController.index == 1 ? sentParcels : receivedParcels),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Filtre par statut
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  isExpanded: true,
                  icon: Icon(Icons.filter_list, size: 18, color: Colors.grey.shade600),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('📦 Tous les colis')),
                    const DropdownMenuItem(value: 'pending', child: Text('⏳ En attente')),
                    const DropdownMenuItem(value: 'in_progress', child: Text('🚚 En cours')),
                    const DropdownMenuItem(value: 'delivered', child: Text('✅ Livrés')),
                    const DropdownMenuItem(value: 'free', child: Text('🔓 Libre service')),
                    const DropdownMenuItem(value: 'cancelled', child: Text('❌ Annulés')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Tri
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  icon: Icon(Icons.sort, size: 18, color: Colors.grey.shade600),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  items: [
                    const DropdownMenuItem(value: 'date_desc', child: Text('📅 Plus récent')),
                    const DropdownMenuItem(value: 'date_asc', child: Text('📅 Plus ancien')),
                    const DropdownMenuItem(value: 'price_desc', child: Text('💰 Prix décroissant')),
                    const DropdownMenuItem(value: 'price_asc', child: Text('💰 Prix croissant')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User user, int freeWithBidsCount) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B6E3A), Color(0xFF0D8C46)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Pro-Colis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2B3C),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bonjour 👋',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B3C),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              if (freeWithBidsCount > 0)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FreeParcelsScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.gavel_rounded,
                            size: 18,
                            color: Color(0xFF7A5C00),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$freeWithBidsCount offre${freeWithBidsCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF7A5C00),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(int pending, int inProgress, int delivered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.schedule_rounded,
              label: 'En attente',
              value: pending,
              color: Colors.orange,
              gradientColors: [const Color(0xFFFFE0B2), const Color(0xFFFFCC80)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.directions_car_rounded,
              label: 'En cours',
              value: inProgress,
              color: Colors.blue,
              gradientColors: [const Color(0xFFB3E5FC), const Color(0xFF81D4FA)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_rounded,
              label: 'Livrés',
              value: delivered,
              color: Colors.green,
              gradientColors: [const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF0B6E3A),
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        onTap: (index) => setState(() {}),
        tabs: const [
          Tab(text: 'Tous'),
          Tab(text: 'Envoyés'),
          Tab(text: 'Reçus'),
        ],
      ),
    );
  }

  Widget _buildDynamicParcelList(BuildContext context, List<Parcel> parcels) {
    if (widget.parcelState.isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B6E3A)),
          ),
        ),
      );
    }

    if (parcels.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B6E3A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inbox_rounded,
                    size: 48,
                    color: const Color(0xFF0B6E3A),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucun colis trouvé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Commencez par créer votre premier envoi',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewParcelScreen(),
                        ),
                      );
                    },
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
                      'Créer un envoi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final parcel = parcels[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ParcelCard(
              parcel: parcel,
              onTap: () => _navigateToParcelDetail(parcel),
            ),
          );
        },
        childCount: parcels.length,
      ),
    );
  }

  void _navigateToParcelDetail(Parcel parcel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParcelDetailScreen(parcel: parcel),
      ),
    );
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

  Color _getStatusColor(ParcelStatus status) => status.color;

  IconData _getStatusIcon(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return Icons.hourglass_empty_rounded;
      case ParcelStatus.free:
        return Icons.gavel_rounded;
      case ParcelStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case ParcelStatus.pickedUp:
        return Icons.inventory_2_rounded;
      case ParcelStatus.inTransit:
        return Icons.local_shipping_rounded;
      case ParcelStatus.arrived:
        return Icons.fmd_good_rounded;
      case ParcelStatus.outForDelivery:
        return Icons.delivery_dining_rounded;
      case ParcelStatus.delivered:
        return Icons.task_alt_rounded;
      case ParcelStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final List<Color> gradientColors;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.darken(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.darken(),
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken() {
    return Color.fromRGBO(
      (this.red * 0.8).round(),
      (this.green * 0.8).round(),
      (this.blue * 0.8).round(),
      1,
    );
  }
}