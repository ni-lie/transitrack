import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
    required this.index,
    required this.isHovered,
  });

  final int route_choice;
  final List<JeepData> data;
  final int index;
  bool isHovered;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getAddressFromLatLngStream(data[index].location.latitude, data[index].location.longitude),
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
          padding: EdgeInsets.all(Constants.defaultPadding),
          margin: EdgeInsets.only(top: Constants.defaultPadding),
          decoration: BoxDecoration(
            color: isHovered?Colors.white10:null,
            border: Border.all(
              width: 2,
              color: JeepRoutes[route_choice].color.withOpacity(0.15),
            ),
            borderRadius: BorderRadius.all(Radius.circular(Constants.defaultPadding)),
          ),
          child: Row(
            children: [
              SizedBox(
                height: 40,
                width: 40,
                child: Image.asset(JeepFront[route_choice]),
              ),
              SizedBox(width: Constants.defaultPadding),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${snapshot.data}", maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text("${data[index].passenger_count} passengers", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
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