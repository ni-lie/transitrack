import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/widgets/shimmer_widget.dart';

import '../address_finder.dart';
import '../config/route_coordinates.dart';
import '../models/jeep_model.dart';
import '../style/constants.dart';

class JeepInfoCard extends StatelessWidget {
  JeepInfoCard({
    super.key,
    required this.route_choice,
    required this.data,
  });

  final int route_choice;
  final JeepData data;
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
              children: [
                SizedBox(
                  height: 40,
                  width: 40,
                  child: Image.asset(JeepFront[route_choice]),
                ),
                const SizedBox(width: Constants.defaultPadding),
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${data.passenger_count} passengers (${data.slots_remaining} slots left)", maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("${snapshot.data}", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
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