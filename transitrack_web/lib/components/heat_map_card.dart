import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/components/pick_ups_shimmer.dart';

import '../address_finder.dart';
import '../config/route_coordinates.dart';
import '../models/heatmap_model.dart';
import '../style/constants.dart';

class HeatMapCard extends StatelessWidget {
  const HeatMapCard({
    super.key,
    required this.heatmapData,
    required this.route_choice,
  });

  final HeatMapData heatmapData;
  final int route_choice;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: getAddressFromLatLngStream(heatmapData.location.latitude, heatmapData.location.longitude),
        builder: (context, addrsnapshot) {
          if(addrsnapshot.data == null){
            return const PickUpsShimmer();
          }
          return Container(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              margin: const EdgeInsets.only(bottom: Constants.defaultPadding),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.02*heatmapData.passenger_count),
                border: Border.all(
                  width: 2,
                  color: JeepRoutes[route_choice].color.withOpacity(0.15),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${addrsnapshot.data}", maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("${heatmapData.passenger_count} passengers picked up", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              )
          );
        }
    );
  }
}