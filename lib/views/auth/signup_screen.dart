import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_colors.dart';
import '../../services/validation_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String password) {
    setState(() {
      _passwordStrength = ValidationService.getPasswordStrength(password);
    });
  }

  Future<void> _handleSignup() async {
    final authProvider = context.read<AuthProvider>();

    final signupValidationError = ValidationService.validateSignupForm(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (signupValidationError != null) {
      authProvider.setError(signupValidationError);
      return;
    }

    final confirmPasswordError = ValidationService.validateConfirmPassword(
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (confirmPasswordError != null) {
      authProvider.setError(confirmPasswordError);
      return;
    }

    final success = await authProvider.signup(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Compte créé avec succès ! Vérifiez votre email'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              _buildLogo(),
              const SizedBox(height: 10),
              Text(
                'Créez votre compte',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Nom complet',
                      hint: 'Jean Dupont',
                      controller: _nameController,
                      validator: ValidationService.validateName,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Email',
                      hint: 'exemple@resapro.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: ValidationService.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _buildSecurePasswordField(),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPasswordRequirements(),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Votre rôle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildRoleCard(),
              const SizedBox(height: 16),
              _buildInfoNote(),
              const SizedBox(height: 24),
              if (authProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      authProvider.errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Créer mon compte',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo1.png',
      width: 200,
      height: 200,
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              validator?.call(value);
              setState(() {});
            },
          ),
        ),
        if (validator != null)
          _buildValidationError(validator(controller.text)) ?? const SizedBox(),
      ],
    );
  }

  Widget _buildSecurePasswordField() {
    final passwordError =
        ValidationService.validatePassword(_passwordController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  passwordError == null ? AppColors.success : AppColors.primary,
              width: 2,
            ),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            onChanged: _updatePasswordStrength,
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordStrengthIndicator(),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final percentage = (_passwordStrength / 5).clamp(0.0, 1.0);
    Color strengthColor;
    String strengthText;

    if (_passwordStrength < 2) {
      strengthColor = AppColors.error;
      strengthText = 'Faible';
    } else if (_passwordStrength < 4) {
      strengthColor = AppColors.warning;
      strengthText = 'Moyen';
    } else {
      strengthColor = AppColors.success;
      strengthText = 'Fort';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    final confirmPasswordError = ValidationService.validateConfirmPassword(
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmer le mot de passe',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: confirmPasswordError == null
                  ? AppColors.success
                  : AppColors.primary,
              width: 2,
            ),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ),
        _buildValidationError(confirmPasswordError) ?? const SizedBox(),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final requirements = ValidationService.getPasswordRequirements();
    final password = _passwordController.text;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exigences du mot de passe:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...requirements.map((req) {
            final isMet = _checkRequirement(password, req);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    isMet ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: isMet ? AppColors.success : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    req,
                    style: TextStyle(
                      color:
                          isMet ? AppColors.success : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  bool _checkRequirement(String password, String requirement) {
    if (requirement.contains('8 caractères')) {
      return password.length >= 8;
    } else if (requirement.contains('majuscule')) {
      return RegExp(r'[A-Z]').hasMatch(password);
    } else if (requirement.contains('minuscule')) {
      return RegExp(r'[a-z]').hasMatch(password);
    } else if (requirement.contains('chiffre')) {
      return RegExp(r'[0-9]').hasMatch(password);
    } else if (requirement.contains('caractère spécial')) {
      const specialChars = '!@#\$%^&*()_+-=[]{};\':\",./<>?\\|`~';
      return password.split('').any((char) => specialChars.contains(char));
    }
    return false;
  }

  Widget? _buildValidationError(String? error) {
    if (error == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        error,
        style: TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRoleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Utilisateur",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Réserver des ressources",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Note:Les comptes Manager sont créés par l'administrateur.",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Vous avez déjà un compte ? ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: Text(
            'Connectez-vous',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
