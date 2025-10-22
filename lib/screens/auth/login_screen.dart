import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Google sign in failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleFacebookSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithFacebook();

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Facebook sign in failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInAnonymously();

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Anonymous sign in failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // App Logo/Icon
                  const Icon(Icons.emergency, size: 80, color: Colors.red),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Emergency App',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Location-aware emergency contacts',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 48),

                  const Text(
                    'Sign in to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 32),

                  // Google Sign In
                  OutlinedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Facebook Sign In
                  OutlinedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : _handleFacebookSignIn,
                    icon: const Icon(Icons.facebook, color: Colors.blue),
                    label: const Text('Continue with Facebook'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Anonymous Sign In
                  OutlinedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : _handleAnonymousSignIn,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Continue as Guest'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
