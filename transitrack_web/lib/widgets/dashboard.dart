import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/style/big_text.dart';
import '../components/jeepney_statistics.dart';
import '../components/route_info_panel_shimmer.dart';
import '../components/route_statistics.dart';
import '../config/keys.dart';
import '../config/route_coordinates.dart';
import '../config/size_config.dart';
import '../database_manager.dart';
import '../models/jeep_model.dart';
import '../style/colors.dart';
import 'dart:ui' as ui;

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late MapboxMapController _mapController;
  int route_choice = 0;
  late Stream<Stream<List<JeepData>>> jeeps_snapshot;
  List<Symbol> _jeeps = [];
  List<Line> _lines = [];

  late Stream<List<JeepData>> JeepInfo;

  void _setRoute(int choice){
    setState(() {
      route_choice = choice;
    });
  }

  void _updateSymbols(List<JeepData> Jeepneys) {
    _mapController.removeSymbols(_jeeps);
    _jeeps.clear();

    Jeepneys.forEach((Jeepney) {
      double angleRadians = atan2(Jeepney.acceleration[1], Jeepney.acceleration[0]);
      double angleDegrees = angleRadians * (180 / pi);
      final jeepEntity = SymbolOptions(
        geometry: LatLng(Jeepney.location.latitude, Jeepney.location.longitude),
        iconSize: 0.15625,
        iconImage: JeepRoutes[route_choice].image,
        iconRotate: 90 - angleDegrees
      );
      _mapController.addSymbol(jeepEntity).then((jeep) {
        _jeeps.add(jeep);
      });
    });
  }

  void _updateRoutes(){
    _lines.forEach((line) => _mapController.removeLine(line));
    _lines.clear();

    _mapController.addLine(Routes.RouteLines[route_choice]).then((line) {
      _lines.add(line);
    });

  }

  Future<void> _subscribeToCoordinates() async {
    await FireStoreDataBase().fetchJeepData(route_choice).listen((event) {
      if(event.length > 0){
        event.forEach((element) {
          if (element.route_id == route_choice){
            _updateSymbols(event);
          }
        });
      } else {
        _updateSymbols([]);
      }
    });
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    Future.delayed(Duration(seconds: 3), () {
      _updateRoutes();
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
    JeepInfo = FireStoreDataBase().fetchJeepData(route_choice);
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
                              _updateRoutes();
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
                              _updateRoutes();
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
                              // _setRoute(2);
                              // _subscribeToCoordinates();
                              // _updateRoutes();
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
                  stream: JeepInfo,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.hasError) {
                      return RouteInfoPanelShimmer();
                    }
                    List<JeepData> jeepList = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BigText(text: JeepRoutes[route_choice].name, size: 50),
                        SizedBox(height: 20),
                        RouteStatistics(jeepList: jeepList),
                        SizedBox(height: 20),
                        JeepneyStatistics(jeepList: jeepList),
                      ],
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




