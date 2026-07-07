import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../app/routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  String _selectedProvider = AppConstants.aiProvider;
  bool _apiKeyVisible = false;
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyCtrl.text = prefs.getString(AppConstants.apiKeyKey) ?? '';
      _modelCtrl.text = prefs.getString(AppConstants.customModelKey) ?? '';
      _selectedProvider =
          prefs.getString(AppConstants.aiProviderKey) ?? AppConstants.aiProvider;
      _isDark = prefs.getBool(AppConstants.themeKey) ?? true;
    });
  }

  Future<void> _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.apiKeyKey, _apiKeyCtrl.text.trim());
    await prefs.setString(AppConstants.customModelKey, _modelCtrl.text.trim());
    await prefs.setString(AppConstants.aiProviderKey, _selectedProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _onSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.signIn);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user =
              state is AuthAuthenticated ? state.user : null;
          return Scaffold(
            backgroundColor: AppColors.darkBackground,
            appBar: AppBar(
              title: const Text('Profile & Settings'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.error),
                  onPressed: _onSignOut,
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(context, user?.displayName ?? 'User',
                      user?.email ?? '', user?.initials ?? 'U'),
                  const SizedBox(height: 24),
                  _buildSectionLabel(context, 'AI Configuration'),
                  const SizedBox(height: 12),
                  _buildAiSettings(context),
                  const SizedBox(height: 24),
                  _buildSectionLabel(context, 'Appearance'),
                  const SizedBox(height: 12),
                  _buildThemeToggle(context),
                  const SizedBox(height: 24),
                  _buildSectionLabel(context, 'About'),
                  const SizedBox(height: 12),
                  _buildAboutCard(context),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.15),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _onSignOut,
                      child: const Text('Sign Out',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ).animate(delay: 400.ms).fadeIn(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, String name, String email, String initials) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'user_avatar',
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(email,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildAiSettings(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider selector
          Text('AI Provider',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkTextSecondary,
                    fontWeight: FontWeight.w500,
                  )),
          const SizedBox(height: 8),
          Row(
            children: [
              _providerChip('groq', 'Groq (Free)'),
              const SizedBox(width: 8),
              _providerChip('anthropic', 'Claude'),
              const SizedBox(width: 8),
              _providerChip('openai', 'GPT'),
            ],
          ),
          if (_selectedProvider == 'groq') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Groq is FREE! Get key at console.groq.com → API Keys',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // API Key
          Text('API Key',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkTextSecondary,
                    fontWeight: FontWeight.w500,
                  )),
          const SizedBox(height: 8),
          TextFormField(
            controller: _apiKeyCtrl,
            obscureText: !_apiKeyVisible,
            style: const TextStyle(
                color: AppColors.darkTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'sk-ant-... or sk-...',
              hintStyle: const TextStyle(
                  color: AppColors.darkTextHint, fontSize: 14),
              suffixIcon: IconButton(
                icon: Icon(
                    _apiKeyVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.darkTextHint),
                onPressed: () =>
                    setState(() => _apiKeyVisible = !_apiKeyVisible),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Custom model
          Text('Custom Model ID (optional)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkTextSecondary,
                    fontWeight: FontWeight.w500,
                  )),
          const SizedBox(height: 8),
          TextFormField(
            controller: _modelCtrl,
            style: const TextStyle(
                color: AppColors.darkTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: _selectedProvider == 'anthropic'
                  ? AppConstants.anthropicModel
                  : AppConstants.openaiModel,
              hintStyle: const TextStyle(
                  color: AppColors.darkTextHint, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _saveApiKey,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _providerChip(String value, String label) {
    final selected = _selectedProvider == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.darkBorder,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.darkTextSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Toggle app appearance'),
        value: _isDark,
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) async {
          setState(() => _isDark = v);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.themeKey, v);
        },
        secondary: Icon(
          _isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: AppColors.primary,
        ),
      ),
    ).animate(delay: 200.ms).fadeIn();
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          _infoRow(Icons.info_outline_rounded, 'Version',
              AppConstants.appVersion),
          const Divider(height: 20),
          _infoRow(Icons.smart_toy_outlined, 'AI Engine',
              '${_selectedProvider == "anthropic" ? "Claude" : "GPT"} (Streaming)'),
          const Divider(height: 20),
          _infoRow(Icons.storage_rounded, 'Backend', 'Firebase (Firestore)'),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.darkTextPrimary)),
      ],
    );
  }
}
