import 'package:flutter/material.dart';

import 'pages/map_page.dart';

class TrackApp extends StatelessWidget {
  const TrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '轨迹记',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688), // 青绿主色
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F7F4),
      ),
      home: const MapPage(),
    );
  }
}
