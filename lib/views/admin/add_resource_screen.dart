import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/resource.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/app_colors.dart';

class AddResourceScreen extends StatefulWidget {
  final Resource? resource;

  const AddResourceScreen({super.key, this.resource});

  @override
  State<AddResourceScreen> createState() => _AddResourceScreenState();
}

class _AddResourceScreenState extends State<AddResourceScreen> {
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = "Salles";
  final List<String> _types = ["Salles", "Matériel", "Véhicules"];

  File? _imageFile;
  String? _imagePath;

  bool _isLoading = false;

  bool get isEdit => widget.resource != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final r = widget.resource!;
      _nameController.text = r.name;
      _selectedType = r.type;
      _capacityController.text = r.capacity.toString();
      _descriptionController.text = r.description;
      _imagePath = r.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 📸 PICK IMAGE
  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imagePath = picked.path;
      });
    }
  }

  /// 🖼 IMAGE SAFE
  ImageProvider? _buildImageProvider() {
    if (_imageFile != null) return FileImage(_imageFile!);

    if (_imagePath != null && _imagePath!.isNotEmpty) {
      if (_imagePath!.startsWith("http")) {
        return NetworkImage(_imagePath!);
      }
      if (File(_imagePath!).existsSync()) {
        return FileImage(File(_imagePath!));
      }
    }
    return null;
  }

  /// 💾 SAVE
  Future<void> _saveResource() async {

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir les champs obligatoires"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final resource = Resource(
      id: '',
      name: _nameController.text.trim(),
      type: _selectedType, // 🔥 DROPDOWN
      capacity: int.tryParse(_capacityController.text) ?? 0,
      description: _descriptionController.text.trim(),
      imageUrl: _imagePath ?? '',
    );

    final provider = context.read<ResourceProvider>();

    try {
      if (isEdit) {
        final updated = Resource(
          id: widget.resource!.id,
          name: resource.name,
          type: resource.type,
          capacity: resource.capacity,
          description: resource.description,
          imageUrl: resource.imageUrl,
        );

        await provider.update(updated);

      } else {
        await provider.add(resource);
      }

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? "Ressource modifiée avec succès"
                  : "Ressource ajoutée avec succès",
            ),
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedType,
            isExpanded: true,
            items: _types.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEdit ? "Modifier Ressource" : "Nouvelle Ressource",
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// IMAGE
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.border,
                backgroundImage: _buildImageProvider(),
                child: _buildImageProvider() == null
                    ? const Icon(Icons.add_a_photo,
                        size: 40, color: AppColors.textSecondary)
                    : null,
              ),
            ),

            const SizedBox(height: 30),

            _buildField("Nom", _nameController),

            /// 🔥 DROPDOWN TYPE
            _buildDropdown(),

            _buildField(
              "Capacité",
              _capacityController,
              keyboardType: TextInputType.number,
            ),

            _buildField("Description", _descriptionController),

            const SizedBox(height: 30),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _saveResource,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? "Modifier" : "Ajouter"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}