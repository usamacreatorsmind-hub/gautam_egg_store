import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/asset_constants.dart';

List<PageViewModel> pageViewModelList(BuildContext context) {
  final titleStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: Theme.of(context).colorScheme.primary,
    height: 1.2,
  );

  const bodyStyle = TextStyle(
    fontSize: 15,
    color: AppColors.grey600,
    height: 1.6,
  );

  const decoration = PageDecoration(
    titleTextStyle: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.2,
    ),
    bodyTextStyle: bodyStyle,
    bodyPadding: EdgeInsets.symmetric(horizontal: 28),
    titlePadding: EdgeInsets.fromLTRB(28, 24, 28, 12),
    imagePadding: EdgeInsets.only(top: 40),
    pageColor: Colors.white,
  );

  return [
    PageViewModel(
      title: IntroductionScreenConstants.page1Title,
      body: IntroductionScreenConstants.page1Body,
      image: _buildImage(IntroductionScreenConstants.img1),
      decoration: decoration.copyWith(
        titleTextStyle: titleStyle.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
    PageViewModel(
      title: IntroductionScreenConstants.page2Title,
      body: IntroductionScreenConstants.page2Body,
      image: _buildImage(IntroductionScreenConstants.img2),
      decoration: decoration.copyWith(
        titleTextStyle: titleStyle.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
    PageViewModel(
      title: IntroductionScreenConstants.page3Title,
      body: IntroductionScreenConstants.page3Body,
      image: _buildImage(IntroductionScreenConstants.img3),
      decoration: decoration.copyWith(
        titleTextStyle: titleStyle.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  ];
}

Widget _buildImage(String assetPath) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Image.asset(
      assetPath,
      fit: BoxFit.contain,
    ),
  );
}
