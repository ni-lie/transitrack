import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:transitrack_web/widgets/shimmer_widget.dart';
import '../components/jeepney_statistics.dart';
import '../components/route_info_panel_shimmer.dart';
import '../components/route_statistics.dart';
import '../config/size_config.dart';
import '../database_manager.dart';
import '../models/jeep_model.dart';
import '../models/route_model.dart';
import '../style/big_text.dart';
import '../style/colors.dart';
import '../style/small_text.dart';
import 'maps.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int route_choice = 0;
  late Stream<List<RouteData>> routes_snapshot;


  void _setRoute(int choice){
    setState(() {
      route_choice = choice;
    });
  }

  @override
  Widget build(BuildContext context) {
    routes_snapshot = FireStoreDataBase().fetchRouteData(route_choice);
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Drawer(
                elevation: 0,
                child: Container(
                  width: double.infinity,
                  height: SizeConfig.screenHeight,
                  color: AppColors.secondaryBg,
                  child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            height: 100,
                            alignment: Alignment.topCenter,
                            padding: EdgeInsets.only(top: 20),
                            child: SizedBox(
                                width: 35,
                                height: 35,
                                child: Icon(Icons.bus_alert_rounded)
                            ),
                          ),
                          IconButton(
                            onPressed: route_choice != 0 ? (){
                              _setRoute(0);
                            } : null,
                            icon: Icon(
                                Icons.directions_bus,
                                color: Colors.yellow[700]
                            ),
                            iconSize: 30,
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                          ),
                          IconButton(
                            onPressed: route_choice != 1 ? (){
                              _setRoute(1);
                            } : null,
                            icon: Icon(
                                Icons.directions_bus,
                                color: Colors.yellow[900]
                            ),
                            iconSize: 30,
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                          ),
                          IconButton(
                            onPressed: route_choice != 2 ? (){
                              _setRoute(2);
                            } : null,
                            icon: Icon(
                                Icons.directions_bus,
                                color: Colors.red[800]
                            ),
                            iconSize: 30,
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                          ),
                          IconButton(
                            onPressed: route_choice != 3 ? (){
                              _setRoute(3);
                            } : null,
                            icon: Icon(
                                Icons.directions_bus,
                                color: Colors.green[700]
                            ),
                            iconSize: 30,
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                          ),
                          IconButton(
                            onPressed: route_choice != 4 ? (){
                              _setRoute(4);
                            } : null,
                            icon: Icon(
                                Icons.directions_bus,
                                color: Colors.blue[500]
                            ),
                            iconSize: 30,
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                          ),
                        ],
                      )
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Container(
                width: double.infinity,
                height: SizeConfig.screenHeight,
                child: StreamBuilder(
                    stream: routes_snapshot,
                    builder: (context, snapshot) {
                      if(snapshot.connectionState == ConnectionState.waiting || snapshot.hasError){
                        return ShimmerWidget(radius: 0);
                      } else {
                        List<RouteData> routeList = snapshot.data!;
                        List<String> device_list = [];
                        for (RouteData routeData in routeList) {
                          device_list.add(routeData.device_id);
                        }
                        return StreamBuilder(
                            stream: FireStoreDataBase().fetchJeepData(device_list),
                            builder: (context, snapshot) {
                              if(snapshot.connectionState == ConnectionState.waiting || snapshot.hasError){
                                return ShimmerWidget(radius: 0);
                              } else {
                                List<JeepData> jeepList = snapshot.data!;
                                return  GoogleMap(route: route_choice, jeepList: jeepList,);
                              }
                            }
                        );
                      }
                    }
                ),// GoogleMap(route: route_choice),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                height: SizeConfig.screenHeight,
                color: AppColors.secondaryBg,
                padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                child: StreamBuilder(
                    stream: routes_snapshot,
                    builder: (context, snapshot) {
                      if(snapshot.connectionState == ConnectionState.waiting || snapshot.hasError){
                        return RouteInfoPanelShimmer();
                      } else {
                        List<RouteData> routeList = snapshot.data!;
                        List<String> device_list = [];
                        for (RouteData routeData in routeList) {
                          device_list.add(routeData.device_id);
                        }
                        return StreamBuilder(
                            stream: FireStoreDataBase().fetchJeepData(device_list),
                            builder: (context, snapshot) {
                              if(snapshot.connectionState == ConnectionState.waiting || snapshot.hasError){
                                return RouteInfoPanelShimmer();
                              } else {
                                List<JeepData> jeepList = snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RouteStatistics(jeepList: jeepList),
                                    SizedBox(height: 20),
                                    JeepneyStatistics(jeepList: jeepList),
                                  ],
                                );
                              }
                            }
                        );
                      }
                    }
                )
              ),
            )
          ],
        ),
      ),
    );
  }
}



