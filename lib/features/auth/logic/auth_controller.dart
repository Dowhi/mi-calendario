import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/features/auth/data/repositories/auth_repository.dart';
import 'dart:async';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  late final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _authSubscription;
  
  @override
  AppUser? build() {
    _authRepository = AuthRepository();
    print('🔧 AuthController build() iniciado');
    
    // Verificar si ya hay una sesión activa
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      print('🔧 Sesión activa detectada: ${currentUser.displayName}');
      // Cargar datos completos de forma asíncrona
      _loadFullUserData(currentUser.uid);
    }
    
    // Suscribirse a cambios de autenticación
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      print('🔄 AuthController: Cambio de estado detectado: ${user?.displayName ?? 'null'}');
      state = user;
    });
    
    // Retornar el usuario básico si existe, o null si no hay sesión
    return currentUser;
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
  }
  
  Future<void> _loadFullUserData(String uid) async {
    try {
      final fullUserData = await _authRepository.getUserData(uid);
      if (fullUserData != null) {
        print('✅ Datos completos cargados: ${fullUserData.displayName}');
        state = fullUserData;
      }
    } catch (e) {
      print('❌ Error cargando datos completos: $e');
    }
  }
  
  Future<void> refreshCurrentUser() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      await _loadFullUserData(currentUser.uid);
    }
  }
  
  /// Registro por correo electrónico y contraseña
  Future<AppUser?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      print('🔧 Iniciando registro con email: $email');
      final user = await _authRepository.signUpWithEmail(email, password, displayName);
      if (user != null) {
        state = user;
        print('✅ Registro exitoso: ${user.displayName}');
      }
      return user;
    } catch (e) {
      print('❌ Error en signUpWithEmail: $e');
      rethrow;
    }
  }
  
  /// Inicio de sesión por correo electrónico y contraseña
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      print('🔧 Iniciando sesión con email: $email');
      final user = await _authRepository.signInWithEmail(email, password);
      if (user != null) {
        state = user;
        print('✅ Inicio de sesión exitoso: ${user.displayName}');
      }
      return user;
    } catch (e) {
      print('❌ Error en signInWithEmail: $e');
      rethrow;
    }
  }
  
  Future<void> signInWithGoogle() async {
    try {
      print('🔧 AuthController: Iniciando Google Sign-In...');
      final user = await _authRepository.signInWithGoogle();
      
      if (user != null) {
        print('✅ AuthController: Google Sign-In exitoso: ${user.displayName}');
        state = user;
      } else {
        print('❌ AuthController: Google Sign-In falló: usuario es null');
        throw Exception('No se pudo obtener usuario de Google Sign-In');
      }
    } catch (e) {
      print('❌ AuthController: Error en signInWithGoogle: $e');
      // Propagar el error para que el LoginScreen lo maneje
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = null;
    } catch (e) {
      print('Error en signOut: $e');
    }
  }
  
  /// Verificar si el usuario actual tiene familia
  Future<bool> currentUserHasFamily() async {
    try {
      final currentUser = state;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return false;
      }
      
      final hasFamily = await _authRepository.userHasFamily(currentUser.uid);
      print('🔍 Usuario actual tiene familia: $hasFamily');
      return hasFamily;
    } catch (e) {
      print('❌ Error verificando si usuario actual tiene familia: $e');
      return false;
    }
  }
  
  /// Obtener el rol del usuario actual en su familia
  Future<String?> getCurrentUserFamilyRole() async {
    try {
      final currentUser = state;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return null;
      }
      
      final role = await _authRepository.getUserFamilyRole(currentUser.uid);
      print('🔍 Rol del usuario actual: $role');
      return role;
    } catch (e) {
      print('❌ Error obteniendo rol del usuario actual: $e');
      return null;
    }
  }
  
  Future<void> updateUserFamilyId(String? familyId) async {
    try {
      final currentUser = state;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return;
      }
      
      await _authRepository.updateUserFamilyId(currentUser.uid, familyId);
      
      // Actualizar el estado local
      state = currentUser.copyWith(familyId: familyId);
      
      print('✅ FamilyId actualizado: $familyId');
    } catch (e) {
      print('Error actualizando familyId: $e');
      rethrow;
    }
  }
  
  Future<void> updateDeviceToken(String token) async {
    final currentUser = state;
    if (currentUser == null) return;
    
    try {
      await _authRepository.updateDeviceToken(currentUser.uid, token);
      final updatedTokens = List<String>.from(currentUser.deviceTokens);
      if (!updatedTokens.contains(token)) {
        updatedTokens.add(token);
      }
      final updatedUser = currentUser.copyWith(deviceTokens: updatedTokens);
      state = updatedUser;
    } catch (e) {
      print('Error actualizando device token: $e');
    }
  }
}

