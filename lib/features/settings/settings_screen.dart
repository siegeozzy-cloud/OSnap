import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../services/backup_service.dart';
import '../../services/settings_store.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _markup = TextEditingController();
  final _baseUrl = TextEditingController();
  final _apiKey = TextEditingController();
  final _model = TextEditingController();
  bool _sendImage = true;
  bool _saveToGallery = false;
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(settingsProvider);
    final ai = await store.ai();
    final markup = await store.defaultMarkupCents();
    final gallery = await store.saveToGallery();
    if (!mounted) return;
    setState(() {
      _markup.text = markup == null ? '' : centsToInput(markup);
      _baseUrl.text = ai.baseUrl;
      _apiKey.text = ai.apiKey;
      _model.text = ai.model;
      _sendImage = ai.sendImage;
      _saveToGallery = gallery;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _markup.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _saveAi() async {
    await ref
        .read(settingsProvider)
        .saveAi(
          AiSettings(
            baseUrl: _baseUrl.text,
            apiKey: _apiKey.text,
            model: _model.text,
            sendImage: _sendImage,
          ),
        );
    if (mounted) showMessage(context, 'AI settings saved.');
  }

  BackupService get _backup =>
      BackupService(ref.read(dbProvider), ref.read(imagesDirProvider));

  Future<void> _share(Future<File> Function() make) async {
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _busy = true);
    try {
      final file = await make();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      if (mounted) showMessage(context, 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = picked?.path;
    if (path == null || !mounted) return;
    final ok = await confirm(
      context,
      title: 'Restore this backup?',
      message:
          'Everything currently in the app is replaced by the contents of '
          'the backup. This cannot be undone.',
      action: 'Restore',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await _backup.restore(File(path));
      if (mounted) showMessage(context, 'Backup restored.');
    } catch (e) {
      if (mounted) showMessage(context, 'Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    final store = ref.read(settingsProvider);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (_busy) const LinearProgressIndicator(),
        header('Pricing'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _markup,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Default markup per piece',
              prefixText: '+₱',
              helperText:
                  'Used for new items when you leave the markup empty. An '
                  'item you bought before keeps its last markup.',
              helperMaxLines: 3,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => store.setDefaultMarkupCents(parseCents(v)),
          ),
        ),
        header('Photos'),
        SwitchListTile(
          title: const Text('Also save photos to the phone gallery'),
          subtitle: const Text('The app always keeps its own copy.'),
          value: _saveToGallery,
          onChanged: (v) {
            setState(() => _saveToGallery = v);
            store.setSaveToGallery(v);
          },
        ),
        header('AI clean-up (optional)'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scanning works offline without this. "Fix with AI" on the '
                'review screen sends the scanned text (and the photo, if '
                'turned on below) to this service to tidy up messy receipts. Any OpenAI-compatible service '
                'works: GitHub Models, or an open-source model you run with '
                'Ollama or LM Studio.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _baseUrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Service URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKey,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'API key or GitHub token',
                  helperText: 'Stored only on this phone.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _model,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Send the photo too'),
          subtitle: const Text(
            'More accurate, but needs a model that can read images. Turn '
            'off to send only the scanned text.',
          ),
          value: _sendImage,
          onChanged: (v) => setState(() => _sendImage = v),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _saveAi,
              child: const Text('Save AI settings'),
            ),
          ),
        ),
        header('Backup and export'),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Back up everything'),
          subtitle: const Text('A .zip with all receipts and photos'),
          enabled: !_busy,
          onTap: () => _share(_backup.createBackup),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Restore from a backup'),
          enabled: !_busy,
          onTap: _restore,
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('Export items as CSV'),
          subtitle: const Text('Opens in Excel or Google Sheets'),
          enabled: !_busy,
          onTap: () => _share(_backup.createCsv),
        ),
      ],
    );
  }
}
