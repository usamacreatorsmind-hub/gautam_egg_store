import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusinessImagesScreen extends ConsumerStatefulWidget {
  const BusinessImagesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BusinessImagesScreenState();
}

class _BusinessImagesScreenState extends ConsumerState<BusinessImagesScreen> {
  Widget uploadCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.upload_file, size: 40),
          const SizedBox(height: 10),
          Text(title),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            uploadCard('GST Certificate'),
            const SizedBox(height: 16),
            uploadCard('PAN Card'),
            const SizedBox(height: 16),
            uploadCard('Shop Photo'),
            const SizedBox(height: 16),
            uploadCard('Owner Photo'),
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
