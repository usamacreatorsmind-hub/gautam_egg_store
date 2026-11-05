import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/campaign_layout_mixin.dart';

import '../../../../widgets/Product_Card_Widget.dart';

class CountdownCampaignCard extends StatefulWidget {
  final CampaignModel campaign;

  const CountdownCampaignCard({super.key, required this.campaign});

  @override
  State<CountdownCampaignCard> createState() => _CountdownCampaignCardState();
}

class _CountdownCampaignCardState extends State<CountdownCampaignCard>
    with CampaignLayoutMixin {
  late Timer _timer;
  Duration _timeLeft = const Duration(hours: 2, minutes: 45);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.campaign.style;
    return Container(
      margin: EdgeInsets.all(12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.shade900,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.campaign.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r)),
                child: Text(
                  "${_timeLeft.inHours}:${(_timeLeft.inMinutes % 60).toString().padLeft(2, '0')}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: ProductCardWidget.gridHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.campaign.productsIds.length,
              itemBuilder: (context, index) =>
                  buildProductItem(widget.campaign.productsIds[index]),
            ),
          ),
        ],
      ),
    );
  }
}
