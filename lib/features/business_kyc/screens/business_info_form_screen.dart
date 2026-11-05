import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/features/business_kyc/widgets/kyc_text_field.dart';

class BusinessInfoScreen extends ConsumerStatefulWidget {
  const BusinessInfoScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends ConsumerState<BusinessInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const KycTextField(label: 'Business Name'),
            const SizedBox(height: 16),
            const KycTextField(label: 'Owner Name'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Business Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'sole_proprietor',
                  child: Text('Sole Proprietor'),
                ),
                DropdownMenuItem(
                  value: 'partnership',
                  child: Text('Partnership'),
                ),
                DropdownMenuItem(
                  value: 'llp',
                  child: Text('LLP'),
                ),
                DropdownMenuItem(
                  value: 'private_limited',
                  child: Text('Private Limited'),
                ),
              ],
              onChanged: (value) {},
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
