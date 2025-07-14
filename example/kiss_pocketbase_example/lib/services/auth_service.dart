import 'package:kiss_auth/kiss_authorization.dart';
import 'package:kiss_auth/kiss_login.dart';
import 'package:kiss_dependencies/kiss_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  
  AuthenticationData? _currentAuthData;
  AuthorizationContext? _currentAuthContext;
  
  AuthenticationData? get currentUser => _currentAuthData;
  AuthorizationContext? get currentAuthContext => _currentAuthContext;
  bool get isAuthenticated => _currentAuthData != null;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token != null) {
      try {
        final authValidator = resolve<AuthValidator>();
        final authorizationService = resolve<AuthorizationService>();
        
        _currentAuthData = await authValidator.validateToken(token);
        _currentAuthContext = await authorizationService.authorize(token);
      } on Exception {
        await prefs.remove(_tokenKey);
      }
    }
  }
  
  Future<AuthenticationData> login({
    required String email,
    required String password,
  }) async {
    final loginService = resolve<LoginService>();
    final authValidator = resolve<AuthValidator>();
    final authorizationService = resolve<AuthorizationService>();
    
    final loginResult = await loginService.loginWithEmail(email, password);
    
    if (!loginResult.isSuccess) {
      throw Exception(loginResult.error ?? 'Login failed');
    }
    
    final authData = await authValidator.validateToken(loginResult.accessToken!);
    _currentAuthData = authData;
    _currentAuthContext = await authorizationService.authorize(loginResult.accessToken!);
    
    if (loginResult.accessToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, loginResult.accessToken!);
    }
    
    return authData;
  }
  
  Future<AuthenticationData> signup({
    required String email,
    required String password,
  }) async {
    return login(email: email, password: password);
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token != null) {
      try {
        final loginProvider = resolve<LoginProvider>();
        await loginProvider.logout(token);
      } on Exception {
        // Continue with local logout even if provider logout fails
      }
    }
    
    _currentAuthData = null;
    _currentAuthContext = null;
    await prefs.remove(_tokenKey);
  }
}