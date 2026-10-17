import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/secure_window.dart';
import '../../theme/glow_background.dart';
import '../backup/backup_worker.dart';
import 'export_import_page.dart';
import 'settings_providers.dart';

const _backupPasswordKey = 'backup_password';

/// Settings (spec 6.6): transaction export/import, screenshot blocking and
/// the encrypted weekly backup. Category flags live in the Money page's
/// Categories view.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const {};
    final repo = ref.read(settingsRepositoryProvider);

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          children: [
            const _SectionHeader('Data'),
            ListTile(
              leading: const Icon(Icons.import_export),
              title: const Text('Export / Import'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportImportPage()),
              ),
            ),
            const _SectionHeader('Privacy'),
            SwitchListTile(
              title: const Text('Block screenshots'),
              subtitle: const Text('FLAG_SECURE, off by default'),
              value: settings['flag_secure'] == 'true',
              onChanged: (on) async {
                await repo.set('flag_secure', on.toString());
                // Apply right away, not only on the next app start.
                await (on ? SecureWindow.enable() : SecureWindow.disable());
              },
            ),
            const Divider(),
            const _SectionHeader('Backup'),
            ListTile(
              title: const Text('Backup folder'),
              subtitle: Text(settings['backup_dir_uri'] ?? 'Not set'),
              trailing: const Icon(Icons.folder_open),
              onTap: () async {
                final dir = await FilePicker.platform.getDirectoryPath();
                if (dir != null) await repo.set('backup_dir_uri', dir);
              },
            ),
            SwitchListTile(
              title: const Text('Weekly automatic backup'),
              subtitle: const Text('Sundays 03:00, encrypted'),
              value: settings['backup_enabled'] == 'true',
              onChanged: (on) async {
                if (on && !await _ensurePassword(context)) return;
                await repo.set('backup_enabled', on.toString());
                on
                    ? await BackupScheduler.register()
                    : await BackupScheduler.cancel();
              },
            ),
            ListTile(
              title: const Text('Back up now'),
              trailing: const Icon(Icons.backup),
              onTap: () => _backupNow(context, ref, settings),
            ),
          ],
        ),
      ),
    );
  }

  /// First-time password setup with the loss warning (spec 10.3).
  Future<bool> _ensurePassword(BuildContext context) async {
    const storage = FlutterSecureStorage();
    if (await storage.read(key: _backupPasswordKey) != null) return true;
    if (!context.mounted) return false;
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _BackupPasswordDialog(),
    );
    if (password == null || password.isEmpty) return false;
    await storage.write(key: _backupPasswordKey, value: password);
    return true;
  }

  Future<void> _backupNow(
    BuildContext context,
    WidgetRef ref,
    Map<String, String> settings,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final dir = settings['backup_dir_uri'];
    if (dir == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pick a backup folder first.')),
      );
      return;
    }
    if (!await _ensurePassword(context)) return;
    const storage = FlutterSecureStorage();
    final password = await storage.read(key: _backupPasswordKey);
    if (password == null) return;
    final file = await ref
        .read(backupServiceProvider)
        .backupTo(Directory(dir), password);
    messenger.showSnackBar(
      SnackBar(content: Text('Backed up to ${file.path}')),
    );
  }
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog();

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'If you lose this password, your backups CANNOT '
            'be opened.',
          ),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
