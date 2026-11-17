import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiSettings {
  AiSettings({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.sendImage,
  });
  final String baseUrl;
  final String apiKey;
  final String model;

  /// When false only the recognised text is sent, never the photo.
  final bool sendImage;

  bool get isConfigured => baseUrl.isNotEmpty && model.isNotEmpty;
}

/// Small key-value settings, kept in the platform keystore because one of
/// them is an API key.
class SettingsStore {
  static const defaultBaseUrl = 'https://models.github.ai/inference';
  static const defaultModel = 'openai/gpt-4.1-mini';

  final _storage = const FlutterSecureStorage();

  Future<AiSettings> ai() async {
    final all = await _storage.readAll();
    return AiSettings(
      baseUrl: all['ai_base_url'] ?? defaultBaseUrl,
      apiKey: all['ai_key'] ?? '',
      model: all['ai_model'] ?? defaultModel,
      sendImage: (all['ai_send_image'] ?? 'true') == 'true',
    );
  }

  Future<void> saveAi(AiSettings s) async {
    await _storage.write(key: 'ai_base_url', value: s.baseUrl.trim());
    await _storage.write(key: 'ai_key', value: s.apiKey.trim());
    await _storage.write(key: 'ai_model', value: s.model.trim());
    await _storage.write(key: 'ai_send_image', value: '${s.sendImage}');
  }

  Future<int?> defaultMarkupCents() async {
    final v = await _storage.read(key: 'default_markup_cents');
    return v == null ? null : int.tryParse(v);
  }

  Future<void> setDefaultMarkupCents(int? cents) async {
    if (cents == null) {
      await _storage.delete(key: 'default_markup_cents');
    } else {
      await _storage.write(key: 'default_markup_cents', value: '$cents');
    }
  }

  Future<bool> saveToGallery() async =>
      (await _storage.read(key: 'save_to_gallery')) == 'true';

  Future<void> setSaveToGallery(bool v) =>
      _storage.write(key: 'save_to_gallery', value: '$v');
}
