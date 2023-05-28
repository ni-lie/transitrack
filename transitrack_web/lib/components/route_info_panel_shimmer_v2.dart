import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../style/constants.dart';
import '../widgets/shimmer_widget.dart';

class RouteInfoShimmerV2 extends StatelessWidget {
  const RouteInfoShimmerV2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(Constants.defaultPadding),
        child: Column(
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerWidget(height: 20, width: 150),
                  ]
              ),
              const SizedBox(height: Constants.defaultPadding/2),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerWidget(height: 15, width: 125),
                    ShimmerWidget(height: 15, width: 60),
                  ]
              ),
              const SizedBox(height: Constants.defaultPadding),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(Constants.defaultPadding),
                margin: const EdgeInsets.only(top: Constants.defaultPadding),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: Colors.grey.withOpacity(0.15),
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                ),
                child: Row(
                  children: [
                    Container(
                      child: ShimmerWidget(height: 40, width: 40, radius: Constants.defaultPadding),
                    ),
                    const SizedBox(width: Constants.defaultPadding),
                    Expanded(
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
                            SizedBox(height: Constants.defaultPadding/2),
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
                  ],
                ),
              ),
            ]
        )
    );
  }
}