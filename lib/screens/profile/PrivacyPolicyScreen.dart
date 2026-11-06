import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/providers/policy_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Privacypolicyscreen extends ConsumerStatefulWidget {
  const Privacypolicyscreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PrivacypolicyscreenState();
}

class _PrivacypolicyscreenState extends ConsumerState<Privacypolicyscreen> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Privacy Policy",
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Last updated: May 26, 2026",
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  "This Privacy Policy applies to the Surewholesaler application and related services operated by Indian Developers. By using our application, you agree to the collection and use of information in accordance with this policy.",
                  style: textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  "Information We Collect",
                  "We may collect the following information from users:\n\n"
                      "• PAN Card Photo\n"
                      "• PAN Number\n"
                      "• GST Number\n"
                      "• GST Photo\n"
                      "• GST Bill\n"
                      "• GST Certificate\n"
                      "• Shop Address Proof\n"
                      "• Shop Address\n"
                      "• Shop Coordinates (Latitude & Longitude)\n"
                      "• Phone Number\n"
                      "• Email Address",
                ),
                _section(
                  context,
                  "Why We Collect This Information",
                  "The collected information is used for:\n\n"
                      "• Business verification\n"
                      "• GST and PAN validation\n"
                      "• Preventing fraud and fake registrations\n"
                      "• Customer support and communication\n"
                      "• Improving our services",
                ),
                _section(
                  context,
                  "Document Uploads",
                  "Users may upload business-related documents including GST certificates, PAN cards, bills, and address proof for verification purposes. These documents are securely stored and are not shared publicly.",
                ),
                _section(
                  context,
                  "Location Information",
                  "We may collect shop coordinates and location details to verify business addresses and improve delivery or service availability.",
                ),
                _section(
                  context,
                  "Data Security",
                  "We implement appropriate security measures to protect your personal information and uploaded documents from unauthorized access, misuse, or disclosure.",
                ),
                _section(
                  context,
                  "Third-Party Services",
                  "Our application may use trusted third-party services such as Firebase Analytics, Crashlytics, or notification services to improve app performance and user experience.",
                ),
                _section(
                  context,
                  "User Rights",
                  "Users may request correction or deletion of their personal information by contacting us through the email provided below.",
                ),
                _section(
                  context,
                  "Children's Privacy",
                  "Our services are not intended for children under 18 years of age. We do not knowingly collect personal information from minors.",
                ),
                _section(
                  context,
                  "Changes to This Policy",
                  "We may update this Privacy Policy from time to time. Any changes will be posted on this page with an updated effective date.",
                ),
                _section(
                  context,
                  "Contact Us",
                  "If you have any questions regarding this Privacy Policy, you can contact us at:\n\nEmail: surewholesaler@gmail.com",
                ),
// link to privacy policy document

                Text(
                  "For more details, please refer to our full Privacy Policy document available on our website.",
                  style: textTheme.bodyMedium?.copyWith(height: 1.4),
                ),

                SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final policy = await ref.read(policyProvider.future);
                      _launchUrl(policy.privacyUrl);
                    },
                    child: const Text('View Full Privacy Policy'),
                  ),
                ),

                SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final policy = await ref.read(policyProvider.future);
                      _launchUrl(policy.termsUrl);
                    },
                    child: const Text('View Full Terms of Service'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        _launchUrl('mailto:surewholesaler@gmail.com'),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('surewholesaler@gmail.com'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Last updated: May 26, 2026",
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _section(BuildContext context, String title, String body) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(body, style: textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
