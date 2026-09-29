import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/ledger_provider.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

class LedgerApp extends StatelessWidget {
  const LedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<LedgerProvider, ThemeMode>(
      (provider) => provider.themeMode,
    );

    return MaterialApp(
      title: '轻记账',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const RootShell(),
    );
  }
}
