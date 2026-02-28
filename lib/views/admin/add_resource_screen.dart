import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/resource.dart';
import '../../widgets/app_colors.dart';

class AddResourceScreen extends StatefulWidget {
  final Resource? resource;

  const AddResourceScreen({super.key, this.resource});

  @override
  State<AddResourceScreen> createState() => _AddResourceScreenState();
}

class _AddResourceScreenState extends State<AddResourceScreen> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  String? _imagePath;

  bool _isLoading = false;

  bool get isEdit => widget.resource != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      _nameController.text = widget.resource!.name;
      _typeController.text = widget.resource!.type;
      _capacityController.text =
          widget.resource!.capacity.toString();
      _descriptionController.text =
          widget.resource!.description;
      _imagePath = widget.resource!.imageUrl;
    }
  }

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

  ImageProvider? _buildImageProvider() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }

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

  Future<void> _saveResource() async {
    if (_nameController.text.isEmpty ||
        _typeController.text.isEmpty) {
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
      type: _typeController.text.trim(),
      capacity:
          int.tryParse(_capacityController.text) ?? 0,
      description:
          _descriptionController.text.trim(),
      imageUrl: _imagePath ?? '',
    );

    if (isEdit) {
      await FirebaseFirestore.instance
          .collection('resources')
          .doc(widget.resource!.id)
          .update(resource.toMap());
    } else {
      await FirebaseFirestore.instance
          .collection('resources')
          .add(resource.toMap());
    }

    setState(() => _isLoading = false);

    Navigator.pop(context);
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
            _buildField("Type", _typeController),
            _buildField("Capacité", _capacityController,
                keyboardType: TextInputType.number),
            _buildField("Description", _descriptionController),
            const SizedBox(height: 30),
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
                    ? const CircularProgressIndicator(
                        color: AppColors.primaryLight)
                    : Text(isEdit ? "Modifier" : "Ajouter"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}