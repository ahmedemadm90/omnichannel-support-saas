import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/inbox_provider.dart';
import 'views/inbox_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OmniChannelApp());
}

class OmniChannelApp extends StatelessWidget {
  const OmniChannelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InboxProvider(),
      child: MaterialApp(
        title: 'OmniDesk',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B8F80)),
          scaffoldBackgroundColor: const Color(0xFFF4F6FA),
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        home: const InboxView(),
      ),
    );
  }
}
