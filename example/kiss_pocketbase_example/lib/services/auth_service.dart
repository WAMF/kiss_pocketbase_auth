import 'package:kiss_pocketbase_auth/kiss_pocketbase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _baseUrl = 'http://localhost:8090';
  
  final PocketBaseAuthValidator _validator;
  final PocketBaseLoginProvider _loginProvider;
  PocketBaseAuthenticationData? _currentUser;
  
  AuthService() 
    : _validator = PocketBaseAuthValidator(baseUrl: _baseUrl),
      _loginProvider = PocketBaseLoginProvider(baseUrl: _baseUrl);
  
  PocketBaseAuthenticationData? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token != null) {
      try {
        _currentUser = await _validator.validateToken(token) as PocketBaseAuthenticationData;
      } catch (e) {
        await prefs.remove(_tokenKey);
      }
    }
  }
  
  Future<PocketBaseAuthenticationData> login({
    required String email,
    required String password,
  }) async {
    final loginResult = await _loginProvider.loginWithPassword(email, password);
    
    if (!loginResult.isSuccess) {
      throw Exception(loginResult.error ?? 'Login failed');
    }
    
    // Validate the token to get PocketBaseAuthenticationData
    final authData = await _validator.validateToken(loginResult.accessToken!) as PocketBaseAuthenticationData;
    _currentUser = authData;
    
    if (loginResult.accessToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, loginResult.accessToken!);
    }
    
    return authData;
  }
  
  Future<PocketBaseAuthenticationData> signup({
    required String email,
    required String password,
  }) async {
    final signupResult = await _loginProvider.createUser(
      email: email,
      password: password,
    );
    
    if (!signupResult.isSuccess) {
      throw Exception(signupResult.error ?? 'Signup failed');
    }
    
    // Validate the token to get PocketBaseAuthenticationData
    final authData = await _validator.validateToken(signupResult.accessToken!) as PocketBaseAuthenticationData;
    _currentUser = authData;
    
    if (signupResult.accessToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, signupResult.accessToken!);
    }
    
    return authData;
  }
  
  Future<void> logout() async {
    // Try to logout with the provider if we have a token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token != null) {
      try {
        await _loginProvider.logout(token);
      } catch (e) {
        // Continue with local logout even if provider logout fails
      }
    }
    
    _currentUser = null;
    await prefs.remove(_tokenKey);
  }
}