import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import '../components/jeepney_statistics.dart';
import '../components/route_info_panel_shimmer.dart';
import '../components/route_statistics.dart';
import '../config/keys.dart';
import '../config/route_coordinates.dart';
import '../config/size_config.dart';
import '../database_manager.dart';
import '../models/jeep_model.dart';
import '../models/route_model.dart';
import '../style/colors.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late MapboxMapController _mapController;
  int route_choice = 0;
  late Stream<Stream<List<JeepData>>> jeeps_snapshot;
  List<Circle> _circles = [];

  late Stream<List<RouteData>> RouteInfo;
  late Stream<List<JeepData>> JeepInfo;

  Line _currentLine = Line(
      "currentLine",
      Routes.RouteLines[0]
  );

  void _setRoute(int choice){
    setState(() {
      route_choice = choice;
    });
  }

  void _updateCircles(List<JeepData> Jeepneys) {
    _circles.forEach((circle) => _mapController.removeCircle(circle));
    _circles.clear();

    Jeepneys.forEach((Jeepney) {
      final circleOptions = CircleOptions(
        circleRadius: 10.0,
        circleColor: "#FFC107",
        circleOpacity: 0.7,
        geometry: LatLng(Jeepney.location.latitude, Jeepney.location.longitude),
      );
      _mapController.addCircle(circleOptions).then((circle) {
        _circles.add(circle);
      });
    });
  }

  void _subscribeToCoordinates() {
    Stream<List<RouteData>> RouteMap = FireStoreDataBase().fetchRouteData(route_choice);
    List<String> deviceList = [];
    RouteMap.forEach((element) {
      element.forEach((element) {
        deviceList.add(element.device_id);
      });
      Stream<List<JeepData>> JeepMap = FireStoreDataBase().fetchJeepData(deviceList);
      JeepMap.listen((event) {_updateCircles(event);});
    });
  }

  void _onMapCreated(MapboxMapController controller) {
    this._mapController = controller;
    Future.delayed(Duration(seconds: 3), () {
      _subscribeToCoordinates();
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RouteInfo = FireStoreDataBase().fetchRouteData(route_choice);
    List<String> deviceList = [];
    RouteInfo.forEach((element) {
      element.forEach((element) {
        deviceList.add(element.device_id);
      });
      JeepInfo = FireStoreDataBase().fetchJeepData(deviceList);
    });

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
                  color: AppColors.primaryBg,
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
                                child: Icon(
                                    Icons.bus_alert_rounded,
                                )
                            ),
                          ),
                          IconButton(
                            onPressed: route_choice != 0 ? (){
                              _setRoute(0);
                              _subscribeToCoordinates();
                              // _mapController.updateLine(_currentLine, Routes.RouteLines[0]);
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
                              _subscribeToCoordinates();
                              // _mapController.updateLine(_currentLine, Routes.RouteLines[1]);
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
                child: MapboxMap(
                  accessToken: Keys.MapBoxKey,
                  styleString: Keys.MapBoxStyle,
                  onMapCreated: (controller) {
                    _onMapCreated(controller);
                  },
                  onStyleLoadedCallback: (){
                  },
                  initialCameraPosition: CameraPosition(
                    target: Keys.MapCenter,
                    zoom: 15.0,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                height: SizeConfig.screenHeight,
                color: AppColors.primaryBg,
                padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                child: StreamBuilder(
                  stream: RouteInfo,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return RouteInfoPanelShimmer();
                    }
                    if (!snapshot.hasData) {
                      return RouteInfoPanelShimmer();
                    }
                    return StreamBuilder(
                      stream: JeepInfo,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return RouteInfoPanelShimmer();
                        }
                        if (!snapshot.hasData) {
                          return RouteInfoPanelShimmer();
                        }
                        List<JeepData> jeepList = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RouteStatistics(jeepList: jeepList),
                            SizedBox(height: 20),
                            JeepneyStatistics(jeepList: jeepList),
                          ],
                        );
                      },
                    );
                  },
                )
              ),
            )
          ],
        ),
      ),
    );
  }
}




