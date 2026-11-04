import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/empty_state.dart';
import 'core/widgets/phone_frame.dart';

void main() {
  // The Outfit font files are bundled in assets/fonts.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const FridgeNoteApp());
}

class FridgeNoteApp extends StatelessWidget {
  const FridgeNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fridge-note',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) => PhoneFrame(child: child!),
      home: const Scaffold(
        body: EmptyState(message: 'fridge-note is on its way.'),
      ),
    );
  }
}
