import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/auth_repository.dart';

class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({super.key});

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  bool _isLoading = false;
  String? _message;

  Future<void> _checkVerification() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final verified = await context
          .read<AuthRepository>()
          .checkEmailVerification();

      if (!mounted) return;

      setState(() {
        _message = verified
            ? 'Email verified! Loading your account...'
            : 'Your email has not been verified yet.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Unable to check verification: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await context.read<AuthRepository>().sendEmailVerification();

      if (!mounted) return;

      setState(() {
        _message = 'Verification email sent. Check your inbox.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Unable to send email: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthRepository>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Check Your Email',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'We sent you a verification link. '
                'Open the email and click the link to verify '
                'your account before accessing QuickSurveys.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_message != null)
                Text(_message!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkVerification,
                  child: const Text('I Have Verified My Email'),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : _resendVerification,
                child: const Text('Resend Verification Email'),
              ),
              TextButton(
                onPressed: _isLoading ? null : _signOut,
                child: const Text('Sign Out'),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
