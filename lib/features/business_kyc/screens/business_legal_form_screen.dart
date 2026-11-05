import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/features/business_kyc/widgets/kyc_text_field.dart';

class LegalDocumentsScreen extends ConsumerStatefulWidget {
  const LegalDocumentsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _LegalDocumentsScreenState();
}

class _LegalDocumentsScreenState extends ConsumerState<LegalDocumentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal Documents')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const KycTextField(
              label: 'GST Number',
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            const KycTextField(
              label: 'PAN Number',
              textCapitalization: TextCapitalization.characters,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
