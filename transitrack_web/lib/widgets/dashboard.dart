import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/style/big_text.dart';
import 'package:transitrack_web/widgets/shimmer_widget.dart';
import '../address_finder.dart';
import '../components/jeep_info_card.dart';
import '../components/main_screen.dart';
import '../components/route_info_panel_shimmer.dart';
import '../components/route_statistics.dart';
import '../components/sidemenu.dart';
import '../config/keys.dart';
import '../config/route_coordinates.dart';
import '../config/size_config.dart';
import '../database_manager.dart';
import '../models/jeep_model.dart';
import '../style/constants.dart';

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
      if(Jeepney.is_embark){
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
      }
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
    Future.delayed(Duration(seconds: 5), () async {
      _updateRoutes();
      await _subscribeToCoordinates();
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DrawerHeader(
                          child: Icon(Icons.directions_transit)
                      ),
                      DrawerListTile(
                          Route: JeepRoutes[0],
                          icon: Image.asset(JeepSide[0]),
                          isSelected: route_choice == 0,
                          press: route_choice != 0? (){
                            _setRoute(0);
                            _subscribeToCoordinates();
                            _updateRoutes();
                          } : null),
                      DrawerListTile(
                          Route: JeepRoutes[1],
                          icon: Image.asset(JeepSide[1]),
                          isSelected: route_choice == 1,
                          press: route_choice != 1? (){
                            _setRoute(1);
                            _subscribeToCoordinates();
                            _updateRoutes();
                          } : null),
                      DrawerListTile(
                          Route: JeepRoutes[2],
                          icon: Image.asset(JeepSide[2]),
                          isSelected: route_choice == 2,
                          press: route_choice != 2? (){
                            _setRoute(2);
                            _subscribeToCoordinates();
                            _updateRoutes();
                          } : null),
                      DrawerListTile(
                          Route: JeepRoutes[3],
                          icon: Image.asset(JeepSide[3]),
                          isSelected: route_choice == 3,
                          press: route_choice != 3? (){
                            _setRoute(3);
                            _subscribeToCoordinates();
                            _updateRoutes();
                          } : null),
                      DrawerListTile(
                          Route: JeepRoutes[4],
                          icon: Image.asset(JeepSide[4]),
                          isSelected: route_choice == 4,
                          press: route_choice != 4? (){
                            _setRoute(4);
                            _subscribeToCoordinates();
                            _updateRoutes();
                          } : null),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                height: SizeConfig.screenHeight,
                child: Stack(
                  children: [
                    MapboxMap(
                      accessToken: Keys.MapBoxKey,
                      styleString: Keys.MapBoxNight,
                      compassEnabled: false,
                      onMapCreated: (controller) {
                        _onMapCreated(controller);
                      },
                      initialCameraPosition: CameraPosition(
                        target: Keys.MapCenter,
                        zoom: 15.0,
                      ),
                    ),
                    StreamBuilder(
                      stream: JeepInfo,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.hasError) {
                          return SizedBox();
                        }
                        var data = snapshot.data!;
                        double operating = data.where((jeep) => jeep.is_embark).length.toDouble();
                        double not_operating = data.where((jeep) => !jeep.is_embark).length.toDouble();
                        double passenger_count = data.fold(0, (int previousValue, JeepData jeepney) => previousValue + jeepney.passenger_count).toDouble();

                        return SingleChildScrollView(
                          padding: EdgeInsets.all(Constants.defaultPadding),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: SizedBox()
                              ),
                              SizedBox(width: Constants.defaultPadding),
                              Expanded(
                                flex: 2,
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
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  JeepRoutes[route_choice].name,
                                                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                                                ),
                                                Text(
                                                  "${passenger_count} passengers",
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white54),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: Constants.defaultPadding),
                                            SizedBox(
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
                                                          radius: 25,
                                                        ),
                                                        PieChartSectionData(
                                                          color: JeepRoutes[route_choice].color.withOpacity(0.1),
                                                          value: not_operating,
                                                          showTitle: false,
                                                          radius: 25,
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
                                            ),
                                            // Make this into a listview builder
                                            ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: data.where((element) => element.is_embark).length, // Replace with the actual item count
                                              itemBuilder: (context, index) {
                                                  return Column(
                                                    children: [
                                                      SizedBox(height: Constants.defaultPadding),
                                                      JeepInfoCard(route_choice: route_choice, data: data, index: index),
                                                    ],
                                                  );
                                                }
                                              ,
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              )
                            ],
                          ),
                        );
                      }
                    )
                  ],
                ),
              ),
            ),
            // Expanded(
            //   flex: 6,
            //   child: MainScreen()
            // ),
            // Expanded(
            //   flex: 2,
            //   child: Container(
            //       width: double.infinity,
            //       height: SizeConfig.screenHeight,
            //       color: AppColors.primaryBg,
            //       padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
            //       child: StreamBuilder(
            //         stream: JeepInfo,
            //         builder: (context, snapshot) {
            //           if (!snapshot.hasData || snapshot.hasError) {
            //             return RouteInfoPanelShimmer();
            //           }
            //           List<JeepData> jeepList = snapshot.data!;
            //           return Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               BigText(text: JeepRoutes[route_choice].name, size: 50),
            //               SizedBox(height: 20),
            //               RouteStatistics(jeepList: jeepList),
            //               SizedBox(height: 20),
            //               JeepneyStatistics(jeepList: jeepList),
            //             ],
            //           );
            //         },
            //       )
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}






