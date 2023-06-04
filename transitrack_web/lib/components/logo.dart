import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Logo extends StatelessWidget {
  const Logo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
            'assets/logo.png',
            scale: 0.9
        ),
        Shimmer.fromColors(
          baseColor: Colors.transparent,
          highlightColor: Colors.white.withOpacity(0.5),
          period: const Duration(seconds: 5),
          child: Image.asset(
              'assets/logo.png',
              scale: 0.9
          ),
        ),
      ],
    );
  }
}