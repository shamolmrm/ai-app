import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../app/routes.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onSignUp() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthSignUpRequested(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    _buildHeader(context),
                    const SizedBox(height: 40),
                    AppTextField(
                      label: 'Full Name',
                      hint: 'John Doe',
                      controller: _nameCtrl,
                      validator: Validators.displayName,
                      prefixIcon: const Icon(Icons.person_outline,
                          color: AppColors.darkTextHint, size: 20),
                      textInputAction: TextInputAction.next,
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.15),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: AppColors.darkTextHint, size: 20),
                      textInputAction: TextInputAction.next,
                    ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.15),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      controller: _passwordCtrl,
                      isPassword: true,
                      validator: Validators.password,
                      prefixIcon: const Icon(Icons.lock_outlined,
                          color: AppColors.darkTextHint, size: 20),
                      textInputAction: TextInputAction.next,
                    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.15),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Confirm Password',
                      controller: _confirmCtrl,
                      isPassword: true,
                      validator: (v) =>
                          Validators.confirmPassword(v, _passwordCtrl.text),
                      prefixIcon: const Icon(Icons.lock_outlined,
                          color: AppColors.darkTextHint, size: 20),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onSignUp(),
                    ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.15),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Create Account',
                      onTap: _onSignUp,
                      isLoading: isLoading,
                    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, AppRoutes.signIn),
                          child: const Text('Sign In',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ).animate(delay: 450.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Create Account', style: Theme.of(context).textTheme.displayMedium)
            .animate(delay: 100.ms)
            .fadeIn()
            .slideY(begin: 0.1),
        const SizedBox(height: 8),
        Text(
          'Join AI Assistant and unlock unlimited conversations',
          style: Theme.of(context).textTheme.bodyMedium,
        ).animate(delay: 150.ms).fadeIn(),
      ],
    );
  }
}
