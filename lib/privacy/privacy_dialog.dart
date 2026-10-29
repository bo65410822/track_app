import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> showPrivacyConsentDialog(BuildContext context) async {
  final agreed = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('隐私保护提示'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '欢迎使用“轨迹记”。\n\n'
              '为了提供地图展示、当前位置显示和轨迹记录功能，'
              '我们需要使用高德地图 SDK，并在取得你的同意后申请定位权限。\n\n'
              '你的轨迹记录保存在本机，轨迹记不会将轨迹数据上传到自有服务器。',
            ),
            SizedBox(height: 12.0),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyPolicyPage(),
                  ),
                );
              },
              child: Text('查看《轨迹记隐私政策》'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('不同意'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('同意'),
        ),
      ],
    ),
  );
  return agreed ?? false;
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('隐私政策')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SelectableText('''
轨迹记隐私政策

更新日期：2026-10-01
生效日期：2026-10-01

轨迹记使用设备位置提供地图展示、当前位置显示和轨迹记录功能。

当你使用相关功能时，应用会在取得授权后处理经纬度、定位时间、
定位精度、速度和方向等信息。轨迹记录保存在设备本地，
轨迹记不会将轨迹数据上传至自有服务器。

第三方 SDK：

SDK 名称：高德开放平台地图 SDK
第三方名称：北京高德图强科技有限公司
使用目的：地图展示、定位及相关地图服务
'''),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _openAmapPrivacyPolicy(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('查看《高德地图开放平台隐私权政策》'),
            ),
            const SizedBox(height: 8),
            const SelectableText('''
你可以通过 Android 系统设置随时关闭位置权限。
关闭后，地图定位和轨迹记录功能将无法正常使用。

开发者：[小哥怡情]
联系邮箱：[15811131141@163.com]
'''),
          ],
        ),
      ),
    );
  }

  Future<void> _openAmapPrivacyPolicy(BuildContext context) async  {
    final uri = Uri.parse('https://lbs.amap.com/pages/privacy');
    final success = await launchUrl(uri);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开高德隐私政策')),
      );
    }
  }
}
//你可以通过 Android 系统设置随时关闭位置权限。
// 关闭后，地图定位和轨迹记录功能将无法正常使用。
//
// 开发者：[小哥怡情]
// 联系邮箱：[15811131141@163.com]
