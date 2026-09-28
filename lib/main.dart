import 'package:flutter/material.dart';

import 'screens/email_addresses_screen.dart';
import 'services/mock_email_service.dart';
import 'state/email_controller.dart';
import 'theme/app_theme.dart';

void main() => runApp(const EmailRedesignApp());

class EmailRedesignApp extends StatefulWidget {
  const EmailRedesignApp({super.key});

  @override
  State<EmailRedesignApp> createState() => _EmailRedesignAppState();
}

class _EmailRedesignAppState extends State<EmailRedesignApp> {
  // PROTOTYPE: swap MockEmailService for a real EmailService implementation
  // (see README, "Connecting a real backend"). Nothing else needs to change.
  final MockEmailService _service = MockEmailService();
  late final EmailController _controller = EmailController(_service)..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Email addresses',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: EmailAddressesScreen(
        controller: _controller,
        // PROTOTYPE ONLY: remove together with lib/config/demo_config.dart.
        onSelectScenario: (scenario) {
          _service.useScenario(scenario);
          _controller.load();
        },
      ),
    );
  }
}
