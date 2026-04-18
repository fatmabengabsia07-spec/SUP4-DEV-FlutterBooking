import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../models/resource.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/resource_card.dart';

import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../calendar/reservation_screen.dart';
import '../reservations/reservations_screen.dart';
import '../admin/admin_screen.dart';
import '../admin/stats_screen.dart';
import '../manager/pending_reservations_screen.dart';
import '../manager/reviewed_reservations_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserRole role;
  final int initialIndex;

  const HomeScreen({
    super.key,
    required this.role,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  late int _currentIndex;
  String selectedCategory = "Tout";

  final List<String> categories = [
    "Tout",
    "Salles",
    "Véhicules",
    "Matériel",
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get isAdmin => widget.role == UserRole.admin;
  bool get isManager => widget.role == UserRole.manager;
  bool get isUser => widget.role == UserRole.user;

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    final logoutIndex = isAdmin
        ? 4
        : isManager
            ? 4
            : 2;

    if (index == logoutIndex) {
      _logout();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  List<BottomNavigationBarItem> _buildBottomItems() {
    if (isAdmin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Accueil",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: "Réservations",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: "Admin",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: "Stats",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: "Déco",
        ),
      ];
    }

    if (isManager) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Accueil",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: "Réservations",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pending_actions),
          label: "En attente",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fact_check),
          label: "Traitées",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: "Déco",
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: "Accueil",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: "Réservations",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.logout),
        label: "Déco",
      ),
    ];
  }

  Widget _buildBody() {
    if (isAdmin) {
      switch (_currentIndex) {
        case 0:
          return _buildHomeContent();
        case 1:
          return const ReservationsScreen();
        case 2:
          return const AdminScreen();
        case 3:
          return const StatsScreen();
        default:
          return _buildHomeContent();
      }
    }

    if (isManager) {
      switch (_currentIndex) {
        case 0:
          return _buildHomeContent();
        case 1:
          return const ReservationsScreen();

        case 2:
          return const PendingReservationsScreen();

        case 3:
          return const ReviewedReservationsScreen();

        default:
          return _buildHomeContent();
      }
    }

    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const ReservationsScreen();
      default:
        return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: _onItemTapped,
        items: _buildBottomItems(),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Consumer2<ResourceProvider, AuthProvider>(
      builder: (context, resourceProvider, authProvider, _) {
        return Column(
          children: [
            _buildHeader(authProvider),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildCategoryFilter(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Resource>>(
                stream: resourceProvider.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final resources = snapshot.data!;

                  final filteredResources = resources.where((resource) {
                    final matchesSearch = resource.name
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase());

                    final matchesCategory = selectedCategory == "Tout" ||
                        resource.type == selectedCategory;

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredResources.isEmpty) {
                    return const Center(
                      child: Text("Aucune ressource trouvée"),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredResources.length,
                    itemBuilder: (context, index) {
                      final resource = filteredResources[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReservationScreen(resource: resource),
                              ),
                            );
                          },
                          child: ResourceCard(
                            imageUrl: resource.imageUrl,
                            title: resource.name,
                            type: resource.type,
                            capacity: resource.capacity,
                            description: resource.description,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final photoPath = user?.photoPath;

    ImageProvider imageProvider;
    if (photoPath != null &&
        photoPath.isNotEmpty &&
        File(photoPath).existsSync()) {
      imageProvider = FileImage(File(photoPath));
    } else {
      imageProvider = const AssetImage("assets/images/default_avatar.jpg");
    }

    String title = "Ressources";
    String subtitle = "Que souhaitez-vous réserver ?";

    if (isManager) {
      title = "Espace Manager";
      subtitle = "Validez et suivez les réservations";
    }

    if (isAdmin) {
      title = "Espace Admin";
      subtitle = "Gérez la plateforme et les statistiques";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );

              if (!mounted) return;
              await context.read<AuthProvider>().loadUserData();
            },
            child: CircleAvatar(
              radius: 22,
              backgroundImage: imageProvider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: "Rechercher une ressource...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
