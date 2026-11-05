import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/features/business_kyc/widgets/kyc_text_field.dart';

class BusinessAddressScreen extends ConsumerStatefulWidget {
  const BusinessAddressScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BusinessAddressScreenState();
}

class _BusinessAddressScreenState extends ConsumerState<BusinessAddressScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const KycTextField(label: 'Address Line 1'),
            const SizedBox(height: 16),
            const KycTextField(label: 'Address Line 2'),
            const SizedBox(height: 16),
            const KycTextField(label: 'City'),
            const SizedBox(height: 16),
            const KycTextField(label: 'State'),
            const SizedBox(height: 16),
            const KycTextField(
              label: 'Pincode',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
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
