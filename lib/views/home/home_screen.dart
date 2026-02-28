import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/resource_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/resource.dart';

import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../admin/admin_screen.dart';
import '../calendar/reservation_screen.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/resource_card.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({super.key, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final TextEditingController _searchController = TextEditingController();

  int _currentIndex = 0;
  String selectedCategory = "Tout";

  final List<String> categories = [
    "Tout",
    "Salles",
    "Véhicules",
    "Matériel"
  ];

  void _logout() async {
    await context.read<AuthProvider>().logout();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _onItemTapped(int index) {

    if (!widget.isAdmin && index == 2) {
      _logout();
      return;
    }

    if (widget.isAdmin && index == 4) {
      _logout();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
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
        onTap: _onItemTapped,
        items: widget.isAdmin
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Réservations"),
                BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
                BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Déco"),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Réservations"),
                BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Déco"),
              ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 0) return _buildHomeContent();
    if (_currentIndex == 1) return const Center(child: Text("Page Réservations"));
    if (widget.isAdmin && _currentIndex == 2) return const AdminScreen();
    if (widget.isAdmin && _currentIndex == 3)
      return const Center(child: Text("Page Statistiques"));
    return const SizedBox();
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  final resources = snapshot.data!;

                  final filtered = resources.where((resource) {

                    final matchesSearch = resource.name
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase());

                    final matchesCategory = selectedCategory == "Tout" ||
                        resource.type == selectedCategory;

                    return matchesSearch && matchesCategory;

                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("Aucune ressource trouvée"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {

                      final resource = filtered[index];

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

    if (photoPath != null && File(photoPath).existsSync()) {
      imageProvider = FileImage(File(photoPath));
    } else {
      imageProvider =
          const AssetImage("assets/images/default_avatar.jpg");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ressources",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Que souhaitez-vous réserver ?",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EditProfileScreen()),
              );

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
}