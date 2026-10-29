import 'package:flutter/material.dart';
import 'package:alif_design_system/alif_design_system.dart';

import 'package:alif_student_teacher/models/auth_session.dart';
import 'package:alif_student_teacher/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onSignedIn,
  });

  final ValueChanged<AuthSession> onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController(text: '9999999999');
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _submitting = false;
  String? _error;
  String? _devOtp;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    try {
      setState(() {
        _submitting = true;
        _error = null;
      });

      final devOtp = await AuthService.sendOtp(_phoneController.text.trim());
      if (!mounted) {
        return;
      }

      setState(() {
        _otpSent = true;
        _devOtp = devOtp;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    try {
      setState(() {
        _submitting = true;
        _error = null;
      });

      final session = await AuthService.verifyOtp(
        phone: _phoneController.text.trim(),
        otp: _otpController.text.trim(),
      );
      if (!mounted) {
        return;
      }

      widget.onSignedIn(session);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlifColors.bg,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AlifColors.bg,
                  AlifColors.primaryContainer.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(AlifSpacing.lg),
                child: AlifCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AlifSpacing.sm),
                      Text(
                        'Use your phone number to continue into the student, parent, or teacher experience.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AlifColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AlifSpacing.lg),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '9999999999',
                        ),
                      ),
                      const SizedBox(height: AlifSpacing.md),
                      if (_otpSent) ...[
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'OTP',
                            hintText: 'Enter the OTP',
                          ),
                        ),
                        const SizedBox(height: AlifSpacing.sm),
                      ],
                      if (_devOtp != null)
                        Text(
                          'Dev OTP: $_devOtp',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AlifColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: AlifSpacing.sm),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: AlifSpacing.lg),
                      AlifButton(
                        label: _otpSent ? 'Verify OTP' : 'Send OTP',
                        isLoading: _submitting,
                        onPressed: _submitting ? null : (_otpSent ? _verifyOtp : _sendOtp),
                      ),
                      const SizedBox(height: AlifSpacing.md),
                      Text(
                        'Dev users: 9999999999 admin, 8888888888 teacher, 9999999998 student, 9999999997 parent',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AlifColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
