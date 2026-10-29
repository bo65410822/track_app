import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:track_app/privacy/privacy_consent_store.dart';
import 'package:track_app/privacy/privacy_dialog.dart';

class PrivacyGate {
  const PrivacyGate({this.store = const PrivacyConsentStore()});

  final PrivacyConsentStore store;

  /// 确保用户已同意当前版本隐私协议。
  /// 返回 true 表示可以继续；false 表示未通过（已触发退出）。
  Future<bool> ensureConsent(BuildContext context) async {
    if (await store.isAgreed()) {
      return true;
    } else {
      if (!context.mounted) return false;
      var agreed = await showPrivacyConsentDialog(context);
      if (agreed) {
        await store.markAgreed();
      } else {
        await SystemNavigator.pop();
      }
      return agreed;
    }
  }
}
