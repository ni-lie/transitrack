import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/widgets/shimmer_widget.dart';

import '../address_finder.dart';
import '../config/route_coordinates.dart';
import '../models/jeep_model.dart';
import '../style/constants.dart';

class JeepInfoCardDetailed extends StatelessWidget {
  JeepInfoCardDetailed({
    super.key,
    required this.route_choice,
    required this.data,
    required this.isHeatMap
  });

  final int route_choice;
  final JeepData data;
  final bool isHeatMap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: getAddressFromLatLngStream(data.location.latitude, data.location.longitude),
        builder: (context, snapshot) {
          if(snapshot.data == null){
            return Container(
              padding: EdgeInsets.all(Constants.defaultPadding),
              margin: EdgeInsets.only(top: Constants.defaultPadding),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: Colors.grey.withOpacity(0.15),
                ),
                borderRadius: BorderRadius.all(Radius.circular(Constants.defaultPadding)),
              ),
              child: Row(
                children: [
                  Container(
                    child: ShimmerWidget(height: 40, width: 40, radius: Constants.defaultPadding),
                  ),
                  SizedBox(width: Constants.defaultPadding),
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  flex: 9,
                                  child: SizedBox(child: ShimmerWidget(height: 16))),
                              Expanded(
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
                              Expanded(
                                  flex: 3,
                                  child: SizedBox())
                            ],
                          )
                        ],
                      )
                  ),
                ],
              ),
            );
          }
          return Container(
            padding: const EdgeInsets.all(Constants.defaultPadding),
            margin: const EdgeInsets.only(top: Constants.defaultPadding),
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: JeepRoutes[route_choice].color.withOpacity(0.15),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  width: 40,
                  child: isHeatMap?(CircleAvatar(radius: 15, backgroundColor: data.embark?Colors.red:Colors.green)):Image.asset(JeepFront[route_choice]),
                ),
                const SizedBox(width: Constants.defaultPadding),
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${snapshot.data}", maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 5),
                        Text("Device ID: ${data.device_id}", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("Passenger count: ${data.passenger_count} passengers", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("Slots remaining: ${data.slots_remaining} slots", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("Air Quality: ${data.air_qual.toStringAsFixed(2)} ppm", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("Ambient Temperature: ${data.temp} °C", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("Speed: ${data.speed} m/s", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                        data.embark?Text("Passenger Picked Up", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis):(data.disembark?Text("Passenger Dropped Off", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis):SizedBox()),
                        Text("Timestamp: ${data.timestamp.toDate()}", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    )
                ),
              ],
            ),
          );
        }
    );
  }
}