import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../shared/theme/app_colors.dart';
import '../shared/theme/app_text_styles.dart';
import '../shared/theme/app_theme_mode.dart';
import 'debug_service.dart';

class DebugPanel extends StatefulWidget {
  final VoidCallback onClose;

  const DebugPanel({super.key, required this.onClose});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  final _sessionIdController = TextEditingController();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _sessionIdController.text = DebugService.instance.sessionId;
  }

  @override
  void dispose() {
    _sessionIdController.dispose();
    super.dispose();
  }

  void _setSessionId() {
    DebugService.instance.startSession(_sessionIdController.text);
    FocusScope.of(context).unfocus();
  }

  Future<void> _exportLog() async {
    final format = await _pickFormat();
    if (format == null || !mounted) return;

    setState(() => _exporting = true);
    try {
      final svc = DebugService.instance;
      final content =
          format == 'md' ? svc.exportMarkdown() : svc.exportTxt();
      final bytes = Uint8List.fromList(utf8.encode(content));
      final fileName = '${svc.sessionId}_log.$format';

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save session log',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [format],
        bytes: bytes,
      );

      if (!mounted) return;
      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $savedPath'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<String?> _pickFormat() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Save log as…'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'md'),
            child: const Text('Markdown (.md)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'txt'),
            child: const Text('Plain text (.txt)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final path = await DebugService.instance.saveCsvFile();
      await Share.shareXFiles([XFile(path)], text: 'Session log (CSV)');
    } catch (e) {
      debugPrint('Export error: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withAlpha(40),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent close on panel tap
            child: Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: AppColors.debugBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppColors.debugBorder),
                ),
              ),
              child: Column(
                children: [
                  _buildHandle(),
                  _buildHeader(),
                  _buildSessionRow(),
                  _buildThemeRow(),
                  _buildStatsRow(),
                  const Divider(color: AppColors.debugBorder, height: 1),
                  Expanded(child: _buildEventList()),
                  const Divider(color: AppColors.debugBorder, height: 1),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.buttonBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Text('Debug Panel', style: AppTextStyles.debugLabel),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _sessionIdController,
              style: AppTextStyles.debugMono,
              decoration: InputDecoration(
                hintText: 'Session ID (e.g. P01_LowFi)',
                hintStyle: AppTextStyles.debugMono.copyWith(
                  color: AppColors.textGhost,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.debugBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.debugBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
              onSubmitted: (_) => _setSessionId(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _setSessionId,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(180),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Set',
                style: AppTextStyles.debugLabel.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: ListenableBuilder(
        listenable: AppThemeMode.instance,
        builder: (_, _) {
          final lowFi = AppThemeMode.instance.lowFi;
          return Row(
            children: [
              Icon(
                lowFi
                    ? Icons.grid_view_rounded
                    : Icons.palette_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text('Theme', style: AppTextStyles.debugLabel),
              const SizedBox(width: 10),
              Text(
                lowFi ? 'Low-Fi (wireframe)' : 'Hi-Fi (default)',
                style: AppTextStyles.debugMono,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  AppThemeMode.instance.toggle();
                  DebugService.instance.logEvent(
                    screen: 'debug_panel',
                    eventType: 'tap',
                    elementId:
                        'theme_toggle_${!lowFi ? 'low_fi' : 'hi_fi'}',
                  );
                },
                child: Container(
                  width: 44,
                  height: 24,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: lowFi
                        ? AppColors.accent.withAlpha(180)
                        : AppColors.debugBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    alignment: lowFi
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    return ListenableBuilder(
      listenable: DebugService.instance,
      builder: (_, _) {
        final svc = DebugService.instance;
        final dur = svc.sessionDuration;
        final durStr = '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}';
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              _StatChip(label: 'Events', value: '${svc.eventCount}'),
              const SizedBox(width: 8),
              _StatChip(label: 'Duration', value: durStr),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Feature',
                  value: svc.lastFeature?.replaceAll('_', ' ') ?? '—'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventList() {
    return ListenableBuilder(
      listenable: DebugService.instance,
      builder: (_, _) {
        final events = DebugService.instance.events;
        if (events.isEmpty) {
          return Center(
            child: Text('No events yet', style: AppTextStyles.debugMono),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: events.length,
          itemBuilder: (_, i) {
            final e = events[events.length - 1 - i]; // newest first
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${_formatMs(e.elapsedMs)}  ${e.screen}  ${e.eventType}  ${e.elementId}',
                style: AppTextStyles.debugMono,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Save',
              icon: Icons.save_alt_rounded,
              onTap: _exporting ? null : _exportLog,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'CSV',
              icon: Icons.table_chart_outlined,
              onTap: _exporting ? null : _exportCsv,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'Clear',
              icon: Icons.delete_outline_rounded,
              onTap: () => DebugService.instance.clearSession(),
              destructive: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMs(int ms) {
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.debugBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTextStyles.debugMono.copyWith(
                fontSize: 9,
                color: AppColors.textGhost,
              )),
          Text(value, style: AppTextStyles.debugMono),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: destructive
              ? const Color(0xFFFFEEEE)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.debugBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: destructive
                  ? const Color(0xFFCC4444)
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.debugLabel.copyWith(
                fontSize: 11,
                color: destructive
                    ? const Color(0xFFCC4444)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
