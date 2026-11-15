import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/auth_repository.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _message;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await context.read<AuthRepository>().sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() {
        _message =
            'If an account exists for that email, '
            'a password-reset email will be sent.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Unable to process your request. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_reset, size: 72),
              const SizedBox(height: 20),
              const Text(
                'Reset Your Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the email address associated with '
                'your account. We will send you a reset link.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_message != null)
                Text(_message!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  child: Text(_isLoading ? 'Sending...' : 'Send Reset Link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
