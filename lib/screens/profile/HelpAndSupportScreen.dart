import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/repositories/settings_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportScreen extends ConsumerStatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends ConsumerState<HelpAndSupportScreen> {
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.value;

    final phone = settings?.supportPhone.isNotEmpty == true
        ? settings!.supportPhone
        : AppConfig.supportPhone;
    final email = settings?.storeEmail.isNotEmpty == true
        ? settings!.storeEmail
        : AppConfig.supportEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// =========================
            /// CONTACT OPTIONS
            /// =========================
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    context,
                    icon: Icons.call,
                    title: "Call Us",
                    subtitle: phone,
                    onTap: () => _launchUrl('tel:$phone'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    context,
                    icon: Icons.email,
                    title: "Email",
                    subtitle: email,
                    onTap: () => _launchUrl('mailto:$email'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// =========================
            /// FAQ SECTION
            /// =========================
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Frequently Asked Questions",
                style: textTheme.titleLarge,
              ),
            ),

            const SizedBox(height: 12),

            _faqTile(
              "How do I place an order?",
              "Browse products, add to cart and checkout using your preferred payment method.",
            ),
            _faqTile(
              "How can I track my order?",
              "Go to My Orders → Order Details → Track delivery status.",
            ),
            _faqTile(
              "How do I cancel an order?",
              "Open order details and tap cancel before it is shipped.",
            ),
            _faqTile(
              "How do I contact support?",
              "Use call or email options above. Our team responds quickly.",
            ),

            const SizedBox(height: 30),

            /// FOOTER
            Text(
              "We're here to help you 24/7 ❤️",
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// Contact Card
  /// =========================
  Widget _actionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon,
                  size: 30, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  /// =========================
  /// FAQ Tile
  /// =========================
  Widget _faqTile(String title, String body) {
    return Card(
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(title),
        childrenPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Text(body),
        ],
      ),
    );
  }
}