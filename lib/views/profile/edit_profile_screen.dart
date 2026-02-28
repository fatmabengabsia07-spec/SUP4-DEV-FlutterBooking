import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? selectedDate;
  String? photoPath;
  File? imageFile;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) return;

    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone ?? "";

    if (user.birthDate != null) {
      selectedDate = user.birthDate;
    }

    photoPath = user.photoPath;
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
        photoPath = picked.path;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {

    final authProvider =
        context.read<AuthProvider>();

    final success =
        await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      birthDate: selectedDate,
      photoPath: photoPath,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Profil modifié avec succès"),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {

    final authProvider =
        context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              _buildHeader(),

              const SizedBox(height: 20),

              _buildAvatar(),

              const SizedBox(height: 30),

              _buildTextField(
                  "Full Name", _nameController),

              const SizedBox(height: 20),

              _buildTextField(
                  "Email", _emailController,
                  enabled: false),

              const SizedBox(height: 20),

              _buildTextField(
                  "Phone", _phoneController),

              const SizedBox(height: 20),

              _buildDateField(),

              const SizedBox(height: 40),

              if (authProvider.errorMessage != null)
                Text(
                  authProvider.errorMessage!,
                  style:
                      const TextStyle(color: AppColors.error),
                ),

              _buildSaveButton(authProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Center(
            child: Text(
              "Modifier le profil",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildAvatar() {
    ImageProvider imageProvider;

    if (imageFile != null) {
      imageProvider = FileImage(imageFile!);
    } else if (photoPath != null &&
        File(photoPath!).existsSync()) {
      imageProvider = FileImage(File(photoPath!));
    } else {
      imageProvider = const AssetImage(
          "assets/images/default_avatar.jpg");
    }

    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundImage: imageProvider,
      ),
    );
  }

  Widget _buildTextField(String label,
      TextEditingController controller,
      {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const UnderlineInputBorder(),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Birth Date",
          border: UnderlineInputBorder(),
        ),
        child: Text(
          selectedDate == null
              ? "Sélectionner date"
              : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
        ),
      ),
    );
  }

  Widget _buildSaveButton(
      AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
        ),
        onPressed: authProvider.isLoading
            ? null
            : _saveProfile,
        child: authProvider.isLoading
            ? const CircularProgressIndicator(
                color: AppColors.background)
            : const Text("Modifier"),
      ),
    );
  }
}