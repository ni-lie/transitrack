import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config/route_coordinates.dart';
import '../style/constants.dart';

class route_info_chart extends StatelessWidget {
  const route_info_chart({
    super.key,
    required this.route_choice,
    required this.operating,
    required this.not_operating,
  });

  final int route_choice;
  final double operating;
  final double not_operating;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  color: JeepRoutes[route_choice].color,
                  value: operating,
                  showTitle: false,
                  radius: 20,
                ),
                PieChartSectionData(
                  color: JeepRoutes[route_choice].color.withOpacity(0.1),
                  value: not_operating,
                  showTitle: false,
                  radius: 20,
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$operating',
                        style: Theme.of(context).textTheme.headline4?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: "/${operating + not_operating}",
                        style: Theme.of(context).textTheme.headline4?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      TextSpan(
                        text: '\njeeps',
                        style: Theme.of(context).textTheme.headline4?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Constants.defaultPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }
}