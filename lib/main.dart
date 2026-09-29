import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/ledger_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider<LedgerProvider>(
      create: (_) => LedgerProvider()..init(),
      child: const LedgerApp(),
    ),
  );
}
