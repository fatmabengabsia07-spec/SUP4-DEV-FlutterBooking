
class RateLimitService {
  // Stocke les tentatives par email
  static final Map<String, List<DateTime>> _loginAttempts = {};

  static final Map<String, List<DateTime>> _signupAttempts = {};
  static const int maxLoginAttemptsPerMinute = 5;
  static const int maxSignupAttemptsPerMinute = 3;
  static const int timeWindowInSeconds = 60;
  static const int lockoutDurationInSeconds = 900;


  static bool canAttemptLogin(String email) {
    final normalizedEmail = email.toLowerCase().trim();

    if (!_loginAttempts.containsKey(normalizedEmail)) {
      _loginAttempts[normalizedEmail] = [];
      return true;
    }

    final attempts = _loginAttempts[normalizedEmail]!;
    final now = DateTime.now();

    attempts.removeWhere(
        (time) => now.difference(time).inSeconds > timeWindowInSeconds);

    if (attempts.length >= maxLoginAttemptsPerMinute) {
      final oldestAttempt = attempts.first;
      if (now.difference(oldestAttempt).inSeconds < lockoutDurationInSeconds) {
        return false;
      } else {
        attempts.clear();
        return true;
      }
    }

    return true;
  }

  static void recordFailedLoginAttempt(String email) {
    final normalizedEmail = email.toLowerCase().trim();

    if (!_loginAttempts.containsKey(normalizedEmail)) {
      _loginAttempts[normalizedEmail] = [];
    }

    _loginAttempts[normalizedEmail]!.add(DateTime.now());
  }

  static void clearLoginAttempts(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    _loginAttempts.remove(normalizedEmail);
  }

  static bool canAttemptSignup(String email) {
    final normalizedEmail = email.toLowerCase().trim();

    if (!_signupAttempts.containsKey(normalizedEmail)) {
      _signupAttempts[normalizedEmail] = [];
      return true;
    }

    final attempts = _signupAttempts[normalizedEmail]!;
    final now = DateTime.now();

    attempts.removeWhere(
        (time) => now.difference(time).inSeconds > timeWindowInSeconds);

    if (attempts.length >= maxSignupAttemptsPerMinute) {
      final oldestAttempt = attempts.first;
      if (now.difference(oldestAttempt).inSeconds < lockoutDurationInSeconds) {
        return false;
      } else {
        attempts.clear();
        return true;
      }
    }

    return true;
  }

  static void recordFailedSignupAttempt(String email) {
    final normalizedEmail = email.toLowerCase().trim();

    if (!_signupAttempts.containsKey(normalizedEmail)) {
      _signupAttempts[normalizedEmail] = [];
    }

    _signupAttempts[normalizedEmail]!.add(DateTime.now());
  }

  static void clearSignupAttempts(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    _signupAttempts.remove(normalizedEmail);
  }

  static int? getLoginLockoutTimeRemaining(String email) {
    final normalizedEmail = email.toLowerCase().trim();

    if (!_loginAttempts.containsKey(normalizedEmail)) {
      return null;
    }

    final attempts = _loginAttempts[normalizedEmail]!;
    if (attempts.isEmpty) {
      return null;
    }

    final oldestAttempt = attempts.first;
    final now = DateTime.now();
    final elapsed = now.difference(oldestAttempt).inSeconds;

    if (elapsed >= lockoutDurationInSeconds) {
      return null;
    }

    return lockoutDurationInSeconds - elapsed;
  }

  static void reset() {
    _loginAttempts.clear();
    _signupAttempts.clear();
  }
}
