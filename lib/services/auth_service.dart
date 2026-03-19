import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/models.dart';
import 'package:uuid/uuid.dart';

// ════════════════════════════════════════════════════════════
// Résultat d'une opération d'auth
// ════════════════════════════════════════════════════════════
class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
  });

  factory AuthResult.ok(UserModel user, [String? message]) =>
      AuthResult(success: true, user: user, message: message);

  factory AuthResult.error(String message) =>
      AuthResult(success: false, message: message);
}

// ════════════════════════════════════════════════════════════
// Service d'authentification
// ════════════════════════════════════════════════════════════
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _usersKey = 'registered_users';
  static const _currentUserKey = 'current_user_email';

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ── Inscription email/password ──
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required DateTime dateOfBirth,
    required String residence,
    required String district,
  }) async {
    // Validations
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      return AuthResult.error('Le prénom et le nom sont obligatoires.');
    }
    if (!_isValidEmail(email)) {
      return AuthResult.error('Adresse email invalide.');
    }
    if (phone.trim().isEmpty) {
      return AuthResult.error('Le numéro de téléphone est obligatoire.');
    }
    if (password.length < 6) {
      return AuthResult.error(
          'Le mot de passe doit contenir au moins 6 caractères.');
    }
    if (password != confirmPassword) {
      return AuthResult.error('Les mots de passe ne correspondent pas.');
    }

    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);

    // Vérifier email déjà utilisé
    if (users.any((u) => u['email'] == email.toLowerCase().trim())) {
      return AuthResult.error('Cette adresse email est déjà utilisée.');
    }

    // Créer l'utilisateur
    final user = UserModel(
      id: const Uuid().v4(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.toLowerCase().trim(),
      phone: phone.trim(),
      dateOfBirth: dateOfBirth,
      residence: residence.trim(),
      district: district.trim(),
      healthStatus: 'non_patient',
    );

    // Sauvegarder
    users.add({
      'id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': user.email,
      'phone': user.phone,
      'dateOfBirth': user.dateOfBirth.toIso8601String(),
      'residence': user.residence,
      'district': user.district,
      'healthStatus': user.healthStatus,
      'password': _hashPassword(password),
      'isGoogleUser': false,
    });

    await prefs.setString(_usersKey, jsonEncode(users));
    return AuthResult.ok(user, 'Compte créé avec succès ! Bienvenue 🎉');
  }

  // ── Connexion email/password ──
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) {
      return AuthResult.error('Veuillez entrer votre adresse email.');
    }
    if (!_isValidEmail(email)) {
      return AuthResult.error('Adresse email invalide.');
    }
    if (password.isEmpty) {
      return AuthResult.error('Veuillez entrer votre mot de passe.');
    }

    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);

    final userData = users.firstWhere(
      (u) =>
          u['email'] == email.toLowerCase().trim() &&
          u['password'] == _hashPassword(password),
      orElse: () => {},
    );

    if (userData.isEmpty) {
      return AuthResult.error('Email ou mot de passe incorrect.');
    }

    final user = _userFromMap(userData);
    await prefs.setString(_currentUserKey, email.toLowerCase().trim());
    return AuthResult.ok(user, 'Connexion réussie ! Bienvenue ${user.firstName} 👋');
  }

  // ── Connexion Google ──
  Future<AuthResult> loginWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // toujours proposer le sélecteur de compte

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.error('Connexion Google annulée.');
      }

      final email = googleUser.email.toLowerCase().trim();
      final prefs = await SharedPreferences.getInstance();
      final users = _loadUsers(prefs);

      // Chercher si l'utilisateur existe déjà
      final existing = users.firstWhere(
        (u) => u['email'] == email,
        orElse: () => {},
      );

      UserModel user;

      if (existing.isNotEmpty) {
        // Utilisateur existant → connexion directe
        user = _userFromMap(existing);
      } else {
        // Nouvel utilisateur Google → créer le profil
        final nameParts = googleUser.displayName?.split(' ') ?? ['', ''];
        user = UserModel(
          id: const Uuid().v4(),
          firstName: nameParts.isNotEmpty ? nameParts[0] : googleUser.displayName ?? '',
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          email: email,
          phone: '',
          dateOfBirth: DateTime(1990, 1, 1), // à compléter dans le profil
          residence: '',
          district: '',
          healthStatus: 'non_patient',
          avatarUrl: googleUser.photoUrl,
          isGoogleUser: true,
        );

        // Sauvegarder
        users.add({
          'id': user.id,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'email': user.email,
          'phone': user.phone,
          'dateOfBirth': user.dateOfBirth.toIso8601String(),
          'residence': user.residence,
          'district': user.district,
          'healthStatus': user.healthStatus,
          'avatarUrl': user.avatarUrl,
          'password': null,
          'isGoogleUser': true,
        });
        await prefs.setString(_usersKey, jsonEncode(users));
      }

      await prefs.setString(_currentUserKey, email);
      return AuthResult.ok(user, 'Connexion Google réussie ! Bienvenue ${user.firstName} 👋');
    } catch (e) {
      return AuthResult.error('Erreur lors de la connexion Google : $e');
    }
  }

  // ── Mettre à jour un utilisateur dans le stockage ──
  Future<void> updateStoredUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);
    final idx = users.indexWhere((u) => u['id'] == user.id);
    if (idx != -1) {
      final existing = Map<String, dynamic>.from(users[idx]);
      existing['firstName'] = user.firstName;
      existing['lastName'] = user.lastName;
      existing['phone'] = user.phone;
      existing['residence'] = user.residence;
      existing['district'] = user.district;
      existing['healthStatus'] = user.healthStatus;
      existing['diseaseType'] = user.diseaseType;
      existing['weight'] = user.weight;
      existing['height'] = user.height;
      existing['gpsLocation'] = user.gpsLocation;
      users[idx] = existing;
      await prefs.setString(_usersKey, jsonEncode(users));
    }
  }

  // ── Helpers privés ──
  List<Map<String, dynamic>> _loadUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } catch (_) {
      return [];
    }
  }

  UserModel _userFromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? const Uuid().v4(),
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      dateOfBirth: DateTime.tryParse(map['dateOfBirth'] ?? '') ??
          DateTime(1990, 1, 1),
      residence: map['residence'] ?? '',
      district: map['district'] ?? '',
      healthStatus: map['healthStatus'] ?? 'non_patient',
      diseaseType: map['diseaseType'],
      weight: map['weight'] != null
          ? double.tryParse(map['weight'].toString())
          : null,
      height: map['height'] != null
          ? double.tryParse(map['height'].toString())
          : null,
      gpsLocation: map['gpsLocation'],
      avatarUrl: map['avatarUrl'],
      isGoogleUser: map['isGoogleUser'] ?? false,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(email.trim());
  }

  // Simple hash (pour une vraie app → bcrypt ou Firebase Auth)
  String _hashPassword(String password) {
    // XOR simple + base64 — suffisant pour un stockage local de démo
    // En production → utilisez Firebase Auth ou un vrai hash
    final bytes = password.codeUnits
        .asMap()
        .entries
        .map((e) => e.value ^ (e.key % 7 + 42))
        .toList();
    return base64Encode(bytes);
  }
}