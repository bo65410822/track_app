import 'package:shared_preferences/shared_preferences.dart';

class PrivacyConsentStore {
  const PrivacyConsentStore({this.version = 1});

  final int version;
  static const String _key = 'privacy_consent_version';

  Future<void> markAgreed() async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_key, version);
    });
  }

  Future<bool> isAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_key);
    return savedVersion == version;
  }
}
