import 'package:flutter/material.dart';

import '../../main.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leadingIcon,
    this.actions,
  });

  final String title;
  final IconData? leadingIcon;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kBackgroundColor,
      elevation: 0,
      titleSpacing: 16,
      iconTheme: const IconThemeData(color: kPrimaryColor),
      title: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, color: kPrimaryColor),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
