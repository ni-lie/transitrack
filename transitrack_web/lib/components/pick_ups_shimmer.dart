import 'package:flutter/material.dart';
import '../style/constants.dart';
import '../widgets/shimmer_widget.dart';

class PickUpsShimmer extends StatelessWidget {
  const PickUpsShimmer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      margin: const EdgeInsets.only(top: Constants.defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: Colors.grey.withOpacity(0.15),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
      ),
      child: Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      flex: 9,
                      child: SizedBox(child: ShimmerWidget(height: 16))),
                  const Expanded(
                      flex: 1,
                      child: SizedBox())
                ],
              ),
              const SizedBox(height: Constants.defaultPadding/2),
              Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: SizedBox(child: ShimmerWidget(height: 12))),
                  const Expanded(
                      flex: 3,
                      child: SizedBox())
                ],
              )
            ],
          )
      ),
    );
  }
}