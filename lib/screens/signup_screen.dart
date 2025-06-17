import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Country code selection
  String _selectedCountryCode = '+250'; // Rwanda default
  final List<Map<String, String>> _countryCodes = [
    {'code': '+250', 'country': 'Rwanda', 'flag': '🇷🇼'},
    {'code': '+254', 'country': 'Kenya', 'flag': '🇰🇪'},
    {'code': '+256', 'country': 'Uganda', 'flag': '🇺🇬'},
    {'code': '+255', 'country': 'Tanzania', 'flag': '🇹🇿'},
    {'code': '+257', 'country': 'Burundi', 'flag': '🇧🇮'},
    {'code': '+243', 'country': 'DR Congo', 'flag': '🇨🇩'},
    {'code': '+1', 'country': 'US/Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with numbers and symbols';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'operation-not-allowed':
        return 'This sign-up method is not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      default:
        return 'Registration failed. Please try again';
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        if (_nameController.text.trim().isNotEmpty) {
          await userCredential.user!
              .updateDisplayName(_nameController.text.trim());
          await userCredential.user!.reload();
        }

        if (!mounted) return;
        _showSuccessSnackBar('Account created successfully!');
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_getErrorMessage(e.code));
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            if (!mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove any non-digit characters for validation
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check length based on country code
    if (_selectedCountryCode == '+250') {
      // Rwanda: 9 digits after country code (e.g., 788123456)
      if (digitsOnly.length != 9) {
        return 'Rwanda phone numbers should have 9 digits';
      }
      if (!RegExp(r'^[7][0-9]{8}$').hasMatch(digitsOnly)) {
        return 'Rwanda phone numbers should start with 7';
      }
    } else {
      // General validation for other countries
      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
        return 'Please enter a valid phone number';
      }
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  Widget _buildCountryCodeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountryCode,
          isDense: true,
          onChanged: (String? newValue) {
            setState(() {
              _selectedCountryCode = newValue!;
            });
          },
          items: _countryCodes
              .map<DropdownMenuItem<String>>((Map<String, String> country) {
            return DropdownMenuItem<String>(
              value: country['code'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(country['flag']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(country['code']!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: const Color(0xFF80441E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Using the warning icon as requested (second logo)
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: Color(0xFF80441E),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF80441E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join Rwanda Resilience Hub',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Phone number field with country code
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCountryCodeDropdown(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_outlined),
                            helperText: 'Used for emergency notifications',
                          ),
                          validator: _validatePhone,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      helperText:
                          'At least 8 characters with numbers, letters & symbols',
                    ),
                    validator: _validatePassword,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: _validateConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signup(),
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF80441E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Login Link
                  TextButton(
                    onPressed: _isLoading ? null : () => context.go('/login'),
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(color: Color(0xFF80441E)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
