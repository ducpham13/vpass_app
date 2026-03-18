import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';
import 'auth_utils.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isInitialized;

  AuthState({this.user, this.isLoading = false, this.isInitialized = false});

  AuthState copyWith({UserModel? user, bool? isLoading, bool? isInitialized}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;
  StreamSubscription<UserModel?>? _userDataSubscription;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _init();
    return AuthState(isLoading: false, isInitialized: false);
  }

  void _init() {
    _repository.authStateChanges.listen((firebaseUser) async {
      _userDataSubscription?.cancel();
      
      if (firebaseUser != null) {
        state = state.copyWith(isLoading: true);
        
        // Listen to real-time updates for this user
        _userDataSubscription = _repository.userDataStream(firebaseUser.uid).listen((userData) {
          if (userData != null && userData.isLocked) {
             _repository.signOut();
             state = AuthState(user: null, isLoading: false, isInitialized: true);
             return;
          }
          
          state = AuthState(
            user: userData,
            isLoading: false,
            isInitialized: true,
          );
        });
      } else {
        state = AuthState(user: null, isLoading: false, isInitialized: true);
      }
    });

    ref.onDispose(() {
      _userDataSubscription?.cancel();
    });
  }

  // Trả về error message nếu thất bại, null nếu thành công
  Future<String?> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true);
      final cred = await _repository.signInWithEmailAndPassword(email, password);
      
      // Check if locked immediately after login
      final userData = await _repository.getUserData(cred.user!.uid);
      if (userData != null && userData.isLocked) {
        await _repository.signOut();
        state = state.copyWith(isLoading: false);
        return "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ Admin.";
      }

      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return AuthUtils.cleanErrorMessage(e);
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
  }

  Future<void> topUp(double amount) async {
    final user = state.user;
    if (user == null) return;
    await _repository.updateBalance(user.uid, amount);
    final updatedUser = await _repository.getUserData(user.uid);
    state = state.copyWith(user: updatedUser);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = 'customer',
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordResetEmail(email);
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final user = state.user;
    if (user == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateProfile(uid: user.uid, name: name, phone: phone);
      final updatedUser = await _repository.getUserData(user.uid);
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> changePassword(String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updatePassword(newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> refreshUserData() async {
    final user = state.user;
    if (user == null) return;
    final updatedUser = await _repository.getUserData(user.uid);
    state = state.copyWith(user: updatedUser);
  }
}
