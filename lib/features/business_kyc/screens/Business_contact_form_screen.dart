import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/features/business_kyc/widgets/kyc_text_field.dart';

class BusinessContactScreen extends ConsumerStatefulWidget {
  const BusinessContactScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BusinessContactScreenState();
}

class _BusinessContactScreenState extends ConsumerState<BusinessContactScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const KycTextField(
              label: 'Business Phone',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const KycTextField(
              label: 'WhatsApp Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const KycTextField(
              label: 'Email (Optional)',
              keyboardType: TextInputType.emailAddress,
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
