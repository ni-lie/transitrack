import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config/responsive.dart';
import '../config/route_coordinates.dart';
import '../style/constants.dart';
import '../widgets/shimmer_widget.dart';
import 'header.dart';

class InfoShimmer extends StatelessWidget {
  const InfoShimmer({
    super.key,
    required this.route_choice,
    required bool isLoaded,
  }) : _isLoaded = isLoaded;

  final int route_choice;
  final bool _isLoaded;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 6,
            child: !Responsive.isMobile(context)?Header():
            Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 71,
                      child: Container(
                          child: ShimmerWidget()
                      ),
                    ),
                    const Expanded(
                      flex: 29,
                      child: SizedBox(),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Expanded(
                      flex: 70,
                      child: SizedBox(),
                    ),
                    Expanded(
                      flex: 30,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Constants.secondaryColor,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15)),
                        ),
                        child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Container(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        JeepRoutes[route_choice].name,
                                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      ShimmerWidget()
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // route_info_chart(route_choice: route_choice, operating: operating, not_operating: not_operating),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: NeverScrollableScrollPhysics(),
                                          itemCount: 3, // Replace with the actual item count
                                          itemBuilder: (context, index) {
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
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                        ),
                      ),
                    ),
                  ],
                ),
                Header(),
                if(!_isLoaded)
                  Positioned(
                      top: Constants.defaultPadding,
                      right: Constants.defaultPadding,
                      child: CircularProgressIndicator()
                  ),
              ],
            )
        ),
        if(!Responsive.isMobile(context))
          SizedBox(width: Constants.defaultPadding),
        if(!Responsive.isMobile(context))
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Container(
                padding: const EdgeInsets.all(Constants.defaultPadding),
                decoration: const BoxDecoration(
                  color: Constants.secondaryColor,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  flex: 7,
                                  child: ShimmerWidget()
                              ),
                              Spacer(
                                flex: 1,
                              ),
                              Expanded(
                                  flex: 2,
                                  child: ShimmerWidget()
                              ),
                            ],
                          ),
                          SizedBox(height: Constants.defaultPadding),
                          Center(
                            child: CircleAvatar(
                              backgroundColor: Colors.white24,
                              radius: 70,
                              child: ShimmerWidget(
                                radius: 70,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: 3, // Replace with the actual item count
                            itemBuilder: (context, index) {
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
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }
}