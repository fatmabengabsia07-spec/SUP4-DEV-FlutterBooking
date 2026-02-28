import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';

class ResourceCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;

  const ResourceCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
  });

  ImageProvider _getImageProvider() {
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('/') && File(imageUrl).existsSync()) {
        return FileImage(File(imageUrl));
      }
      if (imageUrl.startsWith('http')) {
        return NetworkImage(imageUrl);
      }
    }
    return const AssetImage("assets/images/default_avatar.jpg");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image(
              image: _getImageProvider(),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(description,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}