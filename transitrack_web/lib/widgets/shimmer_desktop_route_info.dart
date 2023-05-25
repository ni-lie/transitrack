import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../style/constants.dart';
import 'shimmer_widget.dart';

class ShimmerDesktopRouteInfo extends StatelessWidget {
  const ShimmerDesktopRouteInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      decoration: const BoxDecoration(
        color: Constants.secondaryColor,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  flex: 3,
                  child: ShimmerWidget(height: 25)),
              const Spacer(),
              Expanded(
                  flex: 2,
                  child: ShimmerWidget(height: 25))
            ],
          ),
          const SizedBox(height: Constants.defaultPadding),
          Shimmer.fromColors(
              baseColor: Colors.grey.withOpacity(0.5),
              highlightColor: Colors.white.withOpacity(0.2),
              child: SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: Colors.white70,
                        value: 1,
                        showTitle: false,
                        radius: 20,
                      ),
                    ],
                  ),
                ),
              )
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
        ],
      ),
    );
  }
}