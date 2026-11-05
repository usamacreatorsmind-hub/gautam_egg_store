import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditions extends ConsumerWidget {
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
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
                  "Terms and Conditions",
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Last updated: May 26, 2026",
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text(
                  "Please read these terms and conditions carefully before using Our Service.",
                  style: textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  "Interpretation and Definitions",
                  "The words whose initial letters are capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.",
                ),
                _section(
                  context,
                  "Definitions",
                  "Application means the software program provided by the Company downloaded by You on any electronic device, named Surewholesaler.\n\n"
                      "Application Store means the digital distribution service operated and developed by Apple Inc. (Apple App Store) or Google Inc. (Google Play Store) in which the Application has been downloaded.\n\n"
                      "Affiliate means an entity that controls, is controlled by, or is under common control with a party, where \"control\" means ownership of 50% or more of the shares, equity interest or other securities entitled to vote for election of directors or other managing authority.\n\n"
                      "Country refers to: Bihar, India.\n\n"
                      "Company (referred to as either \"the Company\", \"We\", \"Us\" or \"Our\") refers to Surewholesaler.\n\n"
                      "Device means any device that can access the Service such as a computer, a cell phone or a digital tablet.\n\n"
                      "Service refers to the Application.\n\n"
                      "You means the individual accessing or using the Service, or the company, or other legal entity on behalf of which such individual is accessing or using the Service, as applicable.",
                ),
                _section(
                  context,
                  "Acknowledgment",
                  "These are the Terms and Conditions governing the use of this Service and the agreement between You and the Company. These Terms and Conditions set out the rights and obligations of all users regarding the use of the Service.\n\n"
                      "Your access to and use of the Service is conditioned on Your acceptance of and compliance with these Terms and Conditions. These Terms and Conditions apply to all visitors, users and others who access or use the Service.\n\n"
                      "By accessing or using the Service You agree to be bound by these Terms and Conditions. If You disagree with any part of these Terms and Conditions then You may not access the Service.\n\n"
                      "You represent that you are over the age of 18. The Company does not permit those under 18 to use the Service.\n\n"
                      "Your access to and use of the Service is also subject to Our Privacy Policy, which describes how We collect, use, and disclose personal information. Please read Our Privacy Policy carefully before using Our Service.",
                ),
                _section(
                  context,
                  "Links to Other Websites",
                  "Our Service may contain links to third-party websites or services that are not owned or controlled by the Company.\n\n"
                      "The Company has no control over, and assumes no responsibility for, the content, privacy policies, or practices of any third-party websites or services. You further acknowledge and agree that the Company shall not be responsible or liable, directly or indirectly, for any damage or loss caused or alleged to be caused by or in connection with the use of or reliance on any such content, goods or services available on or through any such websites or services.\n\n"
                      "We strongly advise You to read the terms and conditions and privacy policies of any third-party websites or services that You visit.",
                ),
                _section(
                  context,
                  "Termination",
                  "We may terminate or suspend Your access immediately, without prior notice or liability, for any reason whatsoever, including without limitation if You breach these Terms and Conditions.\n\n"
                      "Upon termination, Your right to use the Service will cease immediately.",
                ),
                _section(
                  context,
                  "Limitation of Liability",
                  "Notwithstanding any damages that You might incur, the entire liability of the Company and any of its suppliers under any provision of these Terms and Your exclusive remedy for all of the foregoing shall be limited to the amount actually paid by You through the Service or 100 USD if You haven't purchased anything through the Service.\n\n"
                      "To the maximum extent permitted by applicable law, in no event shall the Company or its suppliers be liable for any special, incidental, indirect, or consequential damages whatsoever (including, but not limited to, damages for loss of profits, loss of data or other information, for business interruption, for personal injury, loss of privacy arising out of or in any way related to the use of or inability to use the Service), even if the Company or any supplier has been advised of the possibility of such damages and even if the remedy fails of its essential purpose.",
                ),
                _section(
                  context,
                  "\"AS IS\" and \"AS AVAILABLE\" Disclaimer",
                  "The Service is provided to You \"AS IS\" and \"AS AVAILABLE\" and with all faults and defects without warranty of any kind. To the maximum extent permitted under applicable law, the Company expressly disclaims all warranties, whether express, implied, statutory or otherwise, with respect to the Service, including all implied warranties of merchantability, fitness for a particular purpose, title and non-infringement.\n\n"
                      "Without limiting the foregoing, neither the Company nor any of the company's provider makes any representation or warranty of any kind, express or implied: (i) as to the operation or availability of the Service; (ii) that the Service will be uninterrupted or error-free; (iii) as to the accuracy, reliability, or currency of any information or content provided through the Service; or (iv) that the Service is free of viruses, scripts, trojan horses, worms, malware, timebombs or other harmful components.",
                ),
                _section(
                  context,
                  "Governing Law",
                  "The laws of the Country, excluding its conflicts of law rules, shall govern these Terms and Your use of the Service. Your use of the Application may also be subject to other local, state, national, or international laws.",
                ),
                _section(
                  context,
                  "Disputes Resolution",
                  "If You have any concern or dispute about the Service, You agree to first try to resolve the dispute informally by contacting the Company.",
                ),
                _section(
                  context,
                  "For European Union (EU) Users",
                  "If You are a European Union consumer, you will benefit from any mandatory provisions of the law of the country in which You are resident.",
                ),
                _section(
                  context,
                  "United States Legal Compliance",
                  "You represent and warrant that (i) You are not located in a country that is subject to the United States government embargo, or that has been designated by the United States government as a \"terrorist supporting\" country, and (ii) You are not listed on any United States government list of prohibited or restricted parties.",
                ),
                _section(
                  context,
                  "Severability and Waiver",
                  "If any provision of these Terms is held to be unenforceable or invalid, such provision will be changed and interpreted to accomplish the objectives of such provision to the greatest extent possible under applicable law and the remaining provisions will continue in full force and effect.\n\n"
                      "Except as provided herein, the failure to exercise a right or to require performance of an obligation under these Terms shall not affect a party's ability to exercise such right or require such performance at any time thereafter nor shall the waiver of a breach constitute a waiver of any subsequent breach.",
                ),
                _section(
                  context,
                  "Translation Interpretation",
                  "These Terms and Conditions may have been translated if We have made them available to You on our Service. You agree that the original English text shall prevail in the case of a dispute.",
                ),
                _section(
                  context,
                  "Changes to These Terms and Conditions",
                  "We reserve the right, at Our sole discretion, to modify or replace these Terms at any time. If a revision is material We will make reasonable efforts to provide at least 30 days' notice prior to any new terms taking effect.\n\n"
                      "By continuing to access or use Our Service after those revisions become effective, You agree to be bound by the revised terms. If You do not agree to the new terms, in whole or in part, please stop using the Service.",
                ),
                _section(
                  context,
                  "Contact Us",
                  "If you have any questions about these Terms and Conditions, You can contact us:\n\nBy email: surewholesaler@gmail.com",
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _launchUrl('mailto:surewholesaler@gmail.com'),
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
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
