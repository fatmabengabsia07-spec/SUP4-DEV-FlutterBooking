import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/resource.dart';
import '../../models/user.dart';
import '../../providers/resource_provider.dart';
import '../../providers/manager_provider.dart';
import '../../widgets/app_colors.dart';

import 'add_resource_screen.dart';
import 'add_manager_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int selectedTab = 0;

  ImageProvider _buildImage(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith("http")) {
        return NetworkImage(imageUrl);
      }
      if (File(imageUrl).existsSync()) {
        return FileImage(File(imageUrl));
      }
    }
    return const AssetImage("assets/images/default_avatar.jpg");
  }

  ImageProvider _buildUserImage(String? photoPath) {
    if (photoPath != null && photoPath.isNotEmpty) {
      if (photoPath.startsWith("http")) {
        return NetworkImage(photoPath);
      }
      if (File(photoPath).existsSync()) {
        return FileImage(File(photoPath));
      }
    }
    return const AssetImage("assets/images/default_avatar.jpg");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: selectedTab == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddResourceScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddManagerScreen(),
                  ),
                );
              },
              child: const Icon(Icons.person_add, color: Colors.white),
            ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Administration",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildTabButton("Ressources", 0),
                  _buildTabButton("Managers", 1),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: selectedTab == 0
                  ? _buildResourcesTab()
                  : _buildManagersTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    return Consumer<ResourceProvider>(
      builder: (context, provider, _) {
        return StreamBuilder<List<Resource>>(
          stream: provider.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final resources = snapshot.data!;

            if (resources.isEmpty) {
              return const Center(child: Text("Aucune ressource"));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final resource = resources[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: _buildImage(resource.imageUrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resource.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              resource.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.adminColor,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddResourceScreen(resource: resource),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppColors.primaryDark,
                        ),
                        onPressed: () async {
                          final confirm = await _confirmDialog(
                            "Voulez-vous supprimer cette ressource ?",
                          );

                          if (confirm == true) {
                            await provider.delete(resource.id);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildManagersTab() {
    return Consumer<ManagerProvider>(
      builder: (context, provider, _) {
        return StreamBuilder<List<User>>(
          stream: provider.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final managers = snapshot.data!;

            if (managers.isEmpty) {
              return const Center(child: Text("Aucun manager"));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: managers.length,
              itemBuilder: (context, index) {
                final manager = managers[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: _buildUserImage(manager.photoPath),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              manager.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              manager.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.adminColor,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddManagerScreen(user: manager),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppColors.primaryDark,
                        ),
                        onPressed: () async {
                          final confirm = await _confirmDialog(
                            "Voulez-vous supprimer ce manager ?",
                          );

                          if (confirm == true) {
                            final success =
                                await provider.demoteManagerToUser(manager.id);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? "Manager supprimé avec succès"
                                      : (provider.errorMessage ??
                                          "Erreur lors de la suppression"),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.primary, size: 50),
              const SizedBox(height: 12),
              const Text(
                "Confirmation",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Annuler"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Confirmer"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}