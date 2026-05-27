// mobile/lib/screens/dashboard/garage_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/screens/parcel/parcel_detail_screen.dart';
import 'package:procolis/screens/profile/profile_screen.dart';

import '../../models/parcel.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class GarageAdminDashboard extends ConsumerStatefulWidget {
  const GarageAdminDashboard({super.key});

  @override
  ConsumerState<GarageAdminDashboard> createState() => _GarageAdminDashboardState();
}

class _GarageAdminDashboardState extends ConsumerState<GarageAdminDashboard> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  List<Parcel> _parcels = [];
  List<User> _drivers = [];
  bool _isLoading = true;
  String? _error;
  User? _currentAdmin;
  
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;
  int _availableDriversCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _loadCurrentAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAdmin() async {
    try {
      final admin = await _apiService.getCurrentUser();
      if (mounted) {
        setState(() => _currentAdmin = admin);
      }
    } catch (e) {
      debugPrint('Erreur chargement admin: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final parcels = await _apiService.getGarageParcels();
      final drivers = await _apiService.getGarageDrivers();
      
      if (mounted) {
        _updateStats(parcels, drivers);
        setState(() {
          _parcels = parcels;
          _drivers = drivers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur détaillée: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateStats(List<Parcel> parcels, List<User> drivers) {
    _pendingCount = parcels.where((p) => 
      p.status == ParcelStatus.pending || p.status == ParcelStatus.confirmed
    ).length;
    _inProgressCount = parcels.where((p) => 
      p.status == ParcelStatus.pickedUp ||
      p.status == ParcelStatus.inTransit ||
      p.status == ParcelStatus.arrived ||
      p.status == ParcelStatus.outForDelivery
    ).length;
    _completedCount = parcels.where((p) => p.status == ParcelStatus.delivered).length;
    _availableDriversCount = drivers.where((d) => d.driverStatus == DriverStatus.available).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Garage'),
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
            tooltip: 'Mon profil',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Actualiser'),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorView();

    return Column(
      children: [
        _buildHeader(),
        _buildStatsGrid(),
        _buildTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PendingParcelsTab(parcels: _parcels, drivers: _drivers, onRefresh: _loadData),
              _DriversTab(drivers: _drivers, onRefresh: _loadData),
              _InProgressTab(parcels: _parcels, onRefresh: _loadData),
              _HistoryTab(parcels: _parcels, onRefresh: _loadData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B6E3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: const [Color(0xFF0B6E3A), Color(0xFF0A5A2E)]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.business, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour, ${_currentAdmin?.fullName.split(' ').first ?? "Admin"}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Gérez votre garage et vos livraisons',
                          style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green[400], shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('$_availableDriversCount dispo', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.store, size: 16),
                  const SizedBox(width: 6),
                  Text('${_parcels.length} colis | ${_drivers.length} chauffeurs', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatCard(title: 'En attente', value: _pendingCount, icon: Icons.pending_actions, color: Colors.orange, onTap: () => _tabController.animateTo(0)),
          const SizedBox(width: 12),
          _StatCard(title: 'En cours', value: _inProgressCount, icon: Icons.local_shipping, color: Colors.blue, onTap: () => _tabController.animateTo(2)),
          const SizedBox(width: 12),
          _StatCard(title: 'Livrés', value: _completedCount, icon: Icons.check_circle, color: Colors.green, onTap: () => _tabController.animateTo(3)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF0B6E3A),
        indicatorWeight: 3,
        labelColor: const Color(0xFF0B6E3A),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: '📦 En attente'),
          Tab(text: '👨‍✈️ Chauffeurs'),
          Tab(text: '🚚 En cours'),
          Tab(text: '📜 Historique'),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, -2))]),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _tabController.index,
        onTap: (index) => _tabController.animateTo(index),
        selectedItemColor: const Color(0xFF0B6E3A),
        unselectedItemColor: Colors.grey[500],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pending), label: 'En attente'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Chauffeurs'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'En cours'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
        ],
      ),
    );
  }
}

// ==================== STAT CARD ====================
class _StatCard extends StatelessWidget {
  final String title; final int value; final IconData icon; final Color color; final VoidCallback onTap;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withAlpha(25), color.withAlpha(10)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Column(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
                const SizedBox(height: 8),
                Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== ONGLET COLIS EN ATTENTE ====================
class _PendingParcelsTab extends StatefulWidget {
  final List<Parcel> parcels;
  final List<User> drivers;
  final Future<void> Function() onRefresh;
  const _PendingParcelsTab({required this.parcels, required this.drivers, required this.onRefresh});

  @override
  State<_PendingParcelsTab> createState() => _PendingParcelsTabState();
}

class _PendingParcelsTabState extends State<_PendingParcelsTab> {
  final ApiService _apiService = ApiService();
  String? _processingParcelId;

  List<Parcel> get _pendingParcels => widget.parcels.where((p) => 
    p.status == ParcelStatus.pending || p.status == ParcelStatus.confirmed
  ).toList();

  String? _getDriverName(String? driverId) {
    if (driverId == null) return null;
    final driver = widget.drivers.firstWhere(
      (d) => d.id == driverId,
      orElse: () => User(
        id: driverId,
        fullName: 'Chauffeur inconnu',
        email: '',
        phone: '',
        role: UserRole.driver,
        createdAt: DateTime.now(),
      ),
    );
    return driver.fullName;
  }


  Future<void> _confirmParcel(Parcel parcel) async {
    setState(() => _processingParcelId = parcel.id);
    try {
      await _apiService.updateParcelStatus(parcel.id, 'confirmed');
      if (mounted) {
        _showSnackBar('Colis confirmé', Colors.green);
        await widget.onRefresh();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Erreur: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _processingParcelId = null);
    }
  }

  Future<void> _assignDriver(Parcel parcel, String driverId) async {
    setState(() => _processingParcelId = parcel.id);
    try {
      final result = await _apiService.assignDriverToParcel(parcel.id, driverId);
      if (mounted && result['success'] == true) {
        _showSnackBar('Chauffeur assigné', Colors.green);
        await widget.onRefresh();
      } else if (mounted) {
        _showSnackBar(result['message'] ?? 'Erreur', Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Erreur: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _processingParcelId = null);
    }
  }

  Future<void> _cancelParcel(Parcel parcel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le colis'),
        content: Text('Annuler ${parcel.trackingNumber} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _processingParcelId = parcel.id);
      try {
        await _apiService.updateParcelStatus(parcel.id, 'cancelled');
        if (mounted) {
          _showSnackBar('Colis annulé', Colors.green);
          await widget.onRefresh();
        }
      } catch (e) {
        if (mounted) _showSnackBar('Erreur: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _processingParcelId = null);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating)
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingParcels.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Aucun colis en attente'),
        SizedBox(height: 8),
        Text('Les nouveaux colis apparaîtront ici', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingParcels.length,
        itemBuilder: (context, index) {
          final parcel = _pendingParcels[index];
          final isProcessing = _processingParcelId == parcel.id;
          final isConfirmed = parcel.status == ParcelStatus.confirmed;
          // CORRECTION: Vérifier si un chauffeur est assigné
          final hasDriver = parcel.driverId != null && parcel.driverId!.isNotEmpty;
          final driverName = _getDriverName(parcel.driverId);
          // Vérifier si le chauffeur assigné existe dans la liste
          final driverExists = driverName != null && driverName != 'Chauffeur inconnu';
          
          // DEBUG: Afficher dans la console pour vérifier
          print('📦 Colis: ${parcel.trackingNumber}');
          print('   driverId: ${parcel.driverId}');
          print('   hasDriver: $hasDriver');
          print('   driverName: $driverName');
          print('   driverExists: $driverExists');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withAlpha(50))
            ),
            child: InkWell(
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ParcelDetailScreen(parcel: parcel))
              ).then((_) => widget.onRefresh()),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B6E3A).withAlpha(25),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: const Icon(Icons.inventory, size: 20, color: Color(0xFF0B6E3A)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(parcel.trackingNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace')),
                              Text(parcel.receiverName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isConfirmed ? Colors.blue : Colors.orange).withAlpha(25),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                            isConfirmed ? 'Confirmé' : 'En attente',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isConfirmed ? Colors.blue : Colors.orange)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Infos colis
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(icon: Icons.fitness_center, label: '${parcel.weight} kg'),
                        if (parcel.price != null) _InfoChip(icon: Icons.money, label: '${parcel.price!.toInt()} FCFA'),
                        _InfoChip(icon: Icons.category, label: parcel.type.label),
                      ],
                    ),
                    
                    // AFFICHAGE DIRECT DU CHAUFFEUR ASSIGNÉ (si existant)
                    if (hasDriver && driverExists) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.green.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.delivery_dining, size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Chauffeur: $driverName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          ],
                        ),
                      ),
                    ],
                    
                    const Divider(height: 24),
                    
                    // Boutons d'action
                    Row(
                      children: [
                        // Bouton Annuler
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isProcessing ? null : () => _cancelParcel(parcel),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Annuler'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Bouton Confirmer (si non confirmé)
                        if (!isConfirmed)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isProcessing ? null : () => _confirmParcel(parcel),
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Confirmer'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                          ),
                        
                        // Bouton Assigner chauffeur (si confirmé ET sans chauffeur)
                        // CORRECTION: Utiliser !hasDriver pour les colis sans chauffeur
                        if (!hasDriver && isConfirmed)
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              hint: const Text('Assigner'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                prefixIcon: const Icon(Icons.delivery_dining, size: 18),
                              ),
                              items: widget.drivers
                                  .where((d) => d.driverStatus == DriverStatus.available)
                                  .map((d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Row(
                                      children: [
                                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(d.fullName)),
                                        const SizedBox(width: 8),
                                        Text(d.phone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  )).toList(),
                              onChanged: isProcessing ? null : (value) => _assignDriver(parcel, value!),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.grey.withAlpha(25), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Colors.grey[600]), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]))]),
  );
}

// ==================== ONGLET CHAUFFEURS AVEC CRUD ====================
class _DriversTab extends StatelessWidget {
  final List<User> drivers;
  final Future<void> Function() onRefresh;
  const _DriversTab({required this.drivers, required this.onRefresh});

  void _showDriverDetails(BuildContext context, User driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver.fullName),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(leading: const Icon(Icons.phone), title: const Text('Téléphone'), subtitle: Text(driver.phone)),
          ListTile(leading: const Icon(Icons.email), title: const Text('Email'), subtitle: Text(driver.email)),
          ListTile(leading: const Icon(Icons.badge), title: const Text('Statut'), subtitle: Text(driver.driverStatus?.label ?? 'Disponible')),
          if (driver.vehiclePlate != null) ListTile(leading: const Icon(Icons.directions_car), title: const Text('Plaque'), subtitle: Text(driver.vehiclePlate!)),
          if (driver.vehicleModel != null) ListTile(leading: const Icon(Icons.car_repair), title: const Text('Modèle'), subtitle: Text(driver.vehicleModel!)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), child: const Text('Modifier')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey), SizedBox(height: 16),
        Text('Aucun chauffeur'), SizedBox(height: 8),
        Text('Ajoutez des chauffeurs depuis le profil', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          final driver = drivers[index];
          final isAvailable = driver.driverStatus == DriverStatus.available;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withAlpha(50))),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (isAvailable ? Colors.green : Colors.grey).withAlpha(25), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.person, color: isAvailable ? Colors.green : Colors.grey)),
              title: Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text(driver.phone, style: const TextStyle(fontSize: 12)),
                Text(driver.email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (isAvailable ? Colors.green : Colors.orange).withAlpha(25), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: isAvailable ? Colors.green : Colors.orange, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(driver.driverStatus?.label ?? 'Disponible', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isAvailable ? Colors.green : Colors.orange)),
                ]),
              ),
              onTap: () => _showDriverDetails(context, driver),
            ),
          );
        },
      ),
    );
  }
}

// ==================== ONGLET COLIS EN COURS ====================
class _InProgressTab extends StatelessWidget {
  final List<Parcel> parcels; final Future<void> Function() onRefresh;
  const _InProgressTab({required this.parcels, required this.onRefresh});
  List<Parcel> get _inProgressParcels => parcels.where((p) => p.status == ParcelStatus.pickedUp || p.status == ParcelStatus.inTransit || p.status == ParcelStatus.arrived || p.status == ParcelStatus.outForDelivery).toList();

  @override
  Widget build(BuildContext context) {
    if (_inProgressParcels.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.local_shipping, size: 64, color: Colors.grey), SizedBox(height: 16), Text('Aucun colis en cours'),
      ]));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _inProgressParcels.length,
        itemBuilder: (context, index) {
          final parcel = _inProgressParcels[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withAlpha(50))),
            child: ListTile(
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: parcel.status.color.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.local_shipping, color: parcel.status.color)),
              title: Text(parcel.trackingNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              subtitle: Text('${parcel.receiverName} - ${parcel.status.label}'),
              trailing: Column(mainAxisSize: MainAxisSize.min, children: [
                if (parcel.driverName != null) Text(parcel.driverName!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: parcel.status.color.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: Text(parcel.status.label, style: TextStyle(fontSize: 10, color: parcel.status.color))),
              ]),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParcelDetailScreen(parcel: parcel))).then((_) => onRefresh()),
            ),
          );
        },
      ),
    );
  }
}

// ==================== ONGLET HISTORIQUE ====================
class _HistoryTab extends StatelessWidget {
  final List<Parcel> parcels; final Future<void> Function() onRefresh;
  const _HistoryTab({required this.parcels, required this.onRefresh});
  List<Parcel> get _historyParcels => parcels.where((p) => p.status == ParcelStatus.delivered || p.status == ParcelStatus.cancelled).toList();

  Future<void> _deleteParcel(BuildContext context, Parcel parcel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer ${parcel.trackingNumber} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final apiService = ApiService();
        final currentUser = await apiService.getCurrentUser();
        if (currentUser.role == UserRole.superAdmin) {
          await apiService.deleteParcelSuperAdmin(parcel.id);
        } else if (currentUser.role == UserRole.admin) {
          await apiService.deleteParcelAdmin(parcel.id);
        } else {
          throw Exception('Droits insuffisants');
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Colis supprimé'), backgroundColor: Colors.green));
          await onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_historyParcels.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, size: 64, color: Colors.grey), SizedBox(height: 16), Text('Aucun historique'),
      ]));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyParcels.length,
        itemBuilder: (context, index) {
          final parcel = _historyParcels[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withAlpha(50))),
            child: ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (parcel.status == ParcelStatus.delivered ? Colors.green : Colors.red).withAlpha(25), borderRadius: BorderRadius.circular(10)),
                child: Icon(parcel.status == ParcelStatus.delivered ? Icons.check_circle : Icons.cancel, color: parcel.status == ParcelStatus.delivered ? Colors.green : Colors.red)),
              title: Text(parcel.trackingNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              subtitle: Text('${parcel.receiverName} - ${_formatDate(parcel.createdAt)}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: parcel.status.color.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                  child: Text(parcel.status.label, style: TextStyle(fontSize: 11, color: parcel.status.color))),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteParcel(context, parcel)),
              ]),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}