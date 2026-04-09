import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;


class AuthErrorHandler {

  static String handleAuthError(dynamic exception) {
    if (exception is firebase_auth.FirebaseAuthException) {
      switch (exception.code) {
        case 'email-already-in-use':
          return "Cet email est déjà associé à un compte";
        case 'weak-password':
          return "Le mot de passe est trop faible";
        case 'invalid-email':
          return "L'adresse email n'est pas valide";

        case 'invalid-credential':
          return "Email ou mot de passe incorrect";
        case 'user-not-found':
          return "Aucun compte trouvé avec cet email";
        case 'wrong-password':
          return "Email ou mot de passe incorrect";
        case 'user-disabled':
          return "Ce compte a été désactivé";

        case 'network-request-failed':
          return "Problème de connexion réseau. Vérifiez votre connexion internet";
        case 'too-many-requests':
          return "Trop de tentatives. Veuillez réessayer plus tard";
        case 'operation-not-allowed':
          return "Cette opération n'est pas autorisée";
        case 'requires-recent-login':
          return "Veuillez vous reconnecter pour effectuer cette action";

        case 'email-not-verified':
          return "Veuillez vérifier votre email avant de continuer";

        default:
          return "Une erreur s'est produite. Veuillez réessayer";
      }
    }

    return "Une erreur inattendue s'est produite";
  }

  static String? getErrorCode(dynamic exception) {
    if (exception is firebase_auth.FirebaseAuthException) {
      return exception.code;
    }
    return null;
  }

  static bool isNetworkError(dynamic exception) {
    if (exception is firebase_auth.FirebaseAuthException) {
      return exception.code == 'network-request-failed';
    }
    return false;
  }

  static bool isTooManyAttempts(dynamic exception) {
    if (exception is firebase_auth.FirebaseAuthException) {
      return exception.code == 'too-many-requests';
    }
    return false;
  }

  static bool requiresRecentLogin(dynamic exception) {
    if (exception is firebase_auth.FirebaseAuthException) {
      return exception.code == 'requires-recent-login';
    }
    return false;
  }
}
