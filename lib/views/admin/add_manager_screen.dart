import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/manager_provider.dart';
import '../../widgets/app_colors.dart';

class AddManagerScreen extends StatefulWidget {
  final User? user;

  const AddManagerScreen({super.key, this.user});

  @override
  State<AddManagerScreen> createState() => _AddManagerScreenState();
}

class _AddManagerScreenState extends State<AddManagerScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      nameController.text = widget.user!.name;
      emailController.text = widget.user!.email;
      phoneController.text = widget.user!.phone ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir les champs obligatoires"),
        ),
      );
      return;
    }

    if (!isEdit && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir un mot de passe"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ManagerProvider>();

    try {
      bool success = false;

      if (isEdit) {
        final updatedUser = User(
          id: widget.user!.id,
          name: name,
          email: email,
          role: UserRole.manager,
          phone: phone.isEmpty ? null : phone,
          birthDate: widget.user!.birthDate,
          photoPath: widget.user!.photoPath,
        );

        success = await provider.updateManager(updatedUser);
      } else {
        success = await provider.addManager(
          name: name,
          email: email,
          password: password,
          phone: phone,
        );
      }

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? "Manager modifié avec succès"
                  : "Manager ajouté avec succès",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ??
                  (isEdit
                      ? "Erreur lors de la modification"
                      : "Erreur lors de l'ajout"),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
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
    final title = isEdit ? "Modifier Manager" : "Ajouter Manager";
    final buttonText = isEdit ? "Modifier" : "Ajouter";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.border,
              child: const Icon(
                Icons.manage_accounts,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),
            _buildField("Nom", nameController),
            _buildField(
              "Email",
              emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildField(
              "Téléphone",
              phoneController,
              keyboardType: TextInputType.phone,
            ),
            if (!isEdit)
              _buildField(
                "Mot de passe",
                passwordController,
                obscureText: true,
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : save,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        buttonText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}