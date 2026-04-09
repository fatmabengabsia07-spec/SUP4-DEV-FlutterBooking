
class ValidationService {
  static const int minPasswordLength = 8;

  static const int maxPasswordLength = 128;

  static const int minNameLength = 2;
  static const int maxNameLength = 100;


  static String? validateEmail(String email) {
    email = email.trim();

    if (email.isEmpty) {
      return "L'email est requis";
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!emailRegex.hasMatch(email)) {
      return "Email invalide";
    }

    if (email.length > 254) {
      return "Email trop long";
    }

    return null;
  }


  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return "Le mot de passe est requis";
    }

    if (password.length < minPasswordLength) {
      return "Le mot de passe doit contenir au moins $minPasswordLength caractères";
    }

    if (password.length > maxPasswordLength) {
      return "Le mot de passe ne peut pas dépasser $maxPasswordLength caractères";
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Le mot de passe doit contenir au moins une majuscule";
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return "Le mot de passe doit contenir au moins une minuscule";
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Le mot de passe doit contenir au moins un chiffre";
    }

    const specialChars = '!@#\$%^&*()_+-=[]{};\':\",./<>?\\|`~';
    if (!password.split('').any((char) => specialChars.contains(char))) {
      return "Le mot de passe doit contenir au moins un caractère spécial (@, !, #, etc.)";
    }

    return null;
  }

  static String? validateName(String name) {
    name = name.trim();

    if (name.isEmpty) {
      return "Le nom est requis";
    }

    if (name.length < minNameLength) {
      return "Le nom doit contenir au moins $minNameLength caractères";
    }

    if (name.length > maxNameLength) {
      return "Le nom ne peut pas dépasser $maxNameLength caractères";
    }

    if (!RegExp(r"^[a-zA-Z\s\-'àâäæçéèêëïîôöœùûüœßÀÂÄÆÇÉÈÊËÏÎÔÖŒÙÛÜŒ]+$")
        .hasMatch(name)) {
      return "Le nom ne peut contenir que des lettres, espaces, tirets et accents";
    }

    return null;
  }

  static String? validateSignupForm({
    required String name,
    required String email,
    required String password,
  }) {
    final nameError = validateName(name);
    if (nameError != null) return nameError;

    final emailError = validateEmail(email);
    if (emailError != null) return emailError;

    final passwordError = validatePassword(password);
    if (passwordError != null) return passwordError;

    return null;
  }

  
  static String? validateLoginForm({
    required String email,
    required String password,
  }) {
    final emailError = validateEmail(email);
    if (emailError != null) return emailError;

    if (password.isEmpty) {
      return "Le mot de passe est requis";
    }

    return null;
  }

  static String sanitizeInput(String input) {
    return input.trim().replaceAll(
        RegExp(r'[<>"]'), ''); 
  }

  static List<String> getPasswordRequirements() {
    return [
      "Au moins 8 caractères",
      "Au moins une majuscule (A-Z)",
      "Au moins une minuscule (a-z)",
      "Au moins un chiffre (0-9)",
      "Au moins un caractère spécial (!@#\$%^&*)",
    ];
  }

  static int getPasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;

    const specialChars = '!@#\$%^&*()_+-=[]{};\':\",./<>?\\|`~';
    if (password.split('').any((char) => specialChars.contains(char)))
      strength++;

    return strength;
  }
}
