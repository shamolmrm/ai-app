import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final void Function(String) onSend;
  final bool isStreaming;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.isStreaming = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;
  String _provider = 'groq';
  String _model = AppConstants.groqModel;

  static const _providers = [
    {'id': 'groq',      'label': 'Groq',      'icon': '⚡', 'model': AppConstants.groqModel},
    {'id': 'anthropic', 'label': 'Claude',    'icon': '🟣', 'model': AppConstants.anthropicModel},
    {'id': 'openai',    'label': 'GPT-4o',    'icon': '🟢', 'model': AppConstants.openaiModel},
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString(AppConstants.aiProviderKey) ?? 'groq';
    final m = prefs.getString(AppConstants.customModelKey) ?? '';
    final defaultModel = _providers.firstWhere(
      (x) => x['id'] == p,
      orElse: () => _providers.first,
    )['model'] as String;
    if (mounted) setState(() {
      _provider = p;
      _model = m.isNotEmpty ? m : defaultModel;
    });
  }

  Future<void> _saveProvider(String provider, String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.aiProviderKey, provider);
    await prefs.setString(AppConstants.customModelKey, model);
    setState(() { _provider = provider; _model = model; });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isStreaming) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Select AI Model',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._providers.map((p) => _modelTile(p)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _modelTile(Map<String, String> p) {
    final selected = _provider == p['id'];
    return GestureDetector(
      onTap: () {
        _saveProvider(p['id']!, p['model']!);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.darkBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(p['icon']!, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['label']!,
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                  Text(p['model']!,
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  String get _providerLabel {
    final p = _providers.firstWhere(
      (x) => x['id'] == _provider,
      orElse: () => _providers.first,
    );
    return '${p['icon']} ${p['label']}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Model selector strip
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: GestureDetector(
                onTap: widget.isStreaming ? null : _showModelPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_providerLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Input row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        enabled: !widget.isStreaming,
                        style: const TextStyle(
                            color: AppColors.darkTextPrimary, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                              color: AppColors.darkTextHint, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.isStreaming ? null : _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: (_hasText && !widget.isStreaming)
                            ? AppColors.primaryGradient
                            : null,
                        color: (_hasText && !widget.isStreaming)
                            ? null
                            : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.isStreaming
                            ? Icons.stop_rounded
                            : Icons.send_rounded,
                        color: (_hasText && !widget.isStreaming)
                            ? Colors.white
                            : AppColors.darkTextHint,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
