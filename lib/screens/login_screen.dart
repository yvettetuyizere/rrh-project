import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  int _loginAttempts = 0;
  DateTime? _lastFailedAttempt;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _resetLoginAttempts() {
    _loginAttempts = 0;
    _lastFailedAttempt = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildRememberMeAndForgotPassword(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildSignUpPrompt(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been temporarily disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait before trying again';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled';
      case 'invalid-credential':
        return 'Invalid email or password combination';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'channel-error':
        return 'Connection error. Please check your internet connection';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password. Please check your credentials';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  bool _isRateLimited() {
    if (_loginAttempts >= 3 && _lastFailedAttempt != null) {
      final timeDifference = DateTime.now().difference(_lastFailedAttempt!);
      return timeDifference.inMinutes < 5;
    }
    return false;
  }

  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();

      // Handle both old and new connectivity_plus versions
      return connectivityResults.contains(ConnectivityResult.mobile) ||
          connectivityResults.contains(ConnectivityResult.wifi);
    } catch (e) {
      if (kDebugMode) {
        print('LoginScreen: Connectivity check failed: $e');
      }
      return true; // Assume connected if check fails
    }
  }

  Future<void> _login() async {
    if (_isRateLimited()) {
      _showErrorSnackBar(
          'Too many failed attempts. Please wait 5 minutes before trying again.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        _showErrorSnackBar(
            'No internet connection. Please check your network settings.');
        return;
      }

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _resetLoginAttempts();
        if (!mounted) return;
        _showSuccessSnackBar('Welcome back! Login successful.');
        context.go('/home');
      }
    } catch (e) {
      _loginAttempts++;
      _lastFailedAttempt = DateTime.now();

      if (!mounted) return;

      String message;
      if (e is FirebaseAuthException) {
        message = _getErrorMessage(e.code);
      } else {
        message = 'Login failed. Please check your credentials and try again.';
      }

      _showErrorSnackBar(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: _loginAttempts < 3
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _login,
              )
            : null,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    final trimmedValue = value.trim();
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }

    if (trimmedValue.length > 254) {
      return 'Email address is too long';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    if (trimmedValue.length > 128) {
      return 'Password is too long';
    }

    return null;
  }

  void _navigateToForgotPassword() {
    if (mounted) {
      try {
        context.go('/forgot-password');
      } catch (e) {
        if (kDebugMode) {
          print('LoginScreen: Navigation error to forgot-password: $e');
        }
        // Fallback navigation
        Navigator.of(context).pushNamed('/forgot-password');
      }
    }
  }

  void _navigateToSignup() {
    if (mounted) {
      try {
        context.go('/signup');
      } catch (e) {
        if (kDebugMode) {
          print('LoginScreen: Navigation error to signup: $e');
        }
        // Fallback navigation
        Navigator.of(context).pushNamed('/signup');
      }
    }
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF80441E).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.security_rounded,
            size: 60,
            color: Color(0xFF80441E),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Rwanda Resilience Hub',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF80441E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome! Please sign in to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email address',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF80441E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: _isLoading ? Colors.grey[50] : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: _validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      enabled: !_isLoading,
      onFieldSubmitted: (_) => _login(),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF80441E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
        ),
        filled: true,
        fillColor: _isLoading ? Colors.grey[50] : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: _validatePassword,
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
              activeColor: const Color(0xFF80441E),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const Text(
              'Remember me',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        TextButton(
          onPressed: _isLoading ? null : _navigateToForgotPassword,
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Color(0xFF80441E),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || _isRateLimited()) ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF80441E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: const Color(0xFF80441E).withValues(alpha: 0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isRateLimited() ? 'Please Wait...' : 'Sign In',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _navigateToSignup,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: Color(0xFF80441E),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
