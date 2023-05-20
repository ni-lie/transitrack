import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:transitrack_web/widgets/shimmer_widget.dart';
import '../MenuController.dart';
import '../address_finder.dart';
import '../components/header.dart';
import '../components/jeep_info_card.dart';
import '../components/pick_ups_shimmer.dart';
import '../components/route_info_chart.dart';
import '../components/sidemenu.dart';
import '../config/keys.dart';
import '../config/responsive.dart';
import '../config/route_coordinates.dart';
import '../config/size_config.dart';
import '../database_manager.dart';
import '../models/heatmap_ride_model.dart';
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
  List<HeatMapEntity> _heatmapCircles = [];
  bool isMouseHoveringRouteInfo = false;
  bool isMouseHoveringDrawer = false;
  int selectedTab = 0;

  bool isHoverJeep = false;
  int hoveredJeep = -1;
  bool _isLoaded = false;
  bool showPickUps = false;


  void _setRoute(int choice){
    setState(() {
      route_choice = choice;
    });
  }

  void addHeatmapLayer(List<HeatMapRideData> heatmap) {
    heatmap.forEach((entity) {
      final Circle = CircleOptions(
        geometry: LatLng(entity.location.latitude, entity.location.longitude),
        circleRadius: 10,
        circleColor: '#FF0000',
        circleOpacity: 0.05*entity.passenger_count,
      );
      _mapController.addCircle(Circle).then((circle) {
        _heatmapCircles.add(HeatMapEntity(heatmap_id: entity.heatmap_id, data: circle));
      });
    });
  }

  void _addSymbols(List<JeepData> Jeepneys) {
    Jeepneys.forEach((Jeepney) {
      double angleRadians = atan2(Jeepney.acceleration[1], Jeepney.acceleration[0]);
      double angleDegrees = angleRadians * (180 / pi);
      final jeepEntity = SymbolOptions(
          geometry: LatLng(Jeepney.location.latitude, Jeepney.location.longitude),
          iconSize: 0.1,
          iconImage: JeepRoutes[route_choice].image,
          textField: Jeepney.device_id,
          textOpacity: 0,
          iconRotate: 90 - angleDegrees,
      );
      _mapController.addSymbol(jeepEntity).then((jeep) {
        _jeeps.add(jeep);
      });
    });
  }

  void _updateSymbols(List<JeepData> Jeepneys) {
    Jeepneys.forEach((Jeepney) {
      double angleRadians = atan2(Jeepney.acceleration[1], Jeepney.acceleration[0]);
      double angleDegrees = angleRadians * (180 / pi);
      if(Jeepney.is_embark){
        _mapController.updateSymbol(_jeeps.firstWhere((symbol) => symbol.options.textField == Jeepney.device_id), SymbolOptions(
          geometry: LatLng(Jeepney.location.latitude, Jeepney.location.longitude),
          iconRotate: 90 - angleDegrees,
          iconOpacity: 1
        ));
      } else {
        _mapController.updateSymbol(_jeeps.firstWhere((symbol) => symbol.options.textField == Jeepney.device_id), SymbolOptions(
            iconOpacity: 0
        ));
      }
    });
  }

  void _updateRoutes(){
    _mapController.removeSymbols(_jeeps);
    _jeeps.clear();

    _lines.forEach((line) => _mapController.removeLine(line));
    _lines.clear();

    _mapController.addLine(Routes.RouteLines[route_choice]).then((line) {
      _lines.add(line);
    });

  }

  Future<void> _subscribeToCoordinates() async {
    _subscribeToHeatMapRide();
    List<JeepData> test = await FireStoreDataBase().loadJeepsByRouteId(route_choice);
    _addSymbols(test);

    FireStoreDataBase().fetchJeepData(route_choice).listen((event) async {
      if(event.isNotEmpty){
        for (var element in event) {
          if (element.route_id == route_choice){
            _updateSymbols(event);
          }
        }
      } else {
        _updateSymbols([]);
      }
    });
    setState(() {
      _isLoaded = true;
    });
  }

  Future<void> _subscribeToHeatMapRide() async {
    _heatmapCircles.forEach((heatmap) {
      _mapController.removeCircle(heatmap.data);
    });
    _heatmapCircles.clear();

    FireStoreDataBase().fetchHeatMapRide(route_choice).listen((event) async {
      for (var element in event) {
        bool isMatching = false;

        for (var heatmap in _heatmapCircles) {
          if (heatmap.heatmap_id == element.heatmap_id) {
            isMatching = true;
            break;
          }
        }

        if (isMatching == false) {
          _mapController.addCircle(CircleOptions(
            geometry: LatLng(element.location.latitude, element.location.longitude),
            circleRadius: showPickUps?10:0,
            circleColor: '#FF0000',
            circleOpacity: 0.05*element.passenger_count,
          )
          ).then((heatmap) {
            _heatmapCircles.add(HeatMapEntity(heatmap_id: element.heatmap_id, data: heatmap));
          });
        }
      }
    });
  }


  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    Future.delayed(const Duration(seconds: 5), () async {
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
    return Scaffold(
      key: context.read<MenuControllers>().scaffoldKey,
      drawer: Drawer(
        elevation: 0.0,
        child: MouseRegion(
          onEnter: (event) {
            setState((){
              isMouseHoveringDrawer = true;
            });
          },
          onExit: (event) {
            setState((){
              isMouseHoveringDrawer = false;
            });
          },
          child: SingleChildScrollView(
            child: Column(
              children: [
                DrawerHeader(
                    child: Image.asset(
                        'assets/logo.png'
                    )
                ),
                DrawerListTile(
                    Route: JeepRoutes[0],
                    icon: Image.asset(JeepSide[0]),
                    isSelected: route_choice == 0,
                    press: route_choice != 0? (){
                      setState(() {
                        _isLoaded = false;
                      });
                      _setRoute(0);
                      _subscribeToCoordinates();
                      _updateRoutes();
                    } : null),
                DrawerListTile(
                    Route: JeepRoutes[1],
                    icon: Image.asset(JeepSide[1]),
                    isSelected: route_choice == 1,
                    press: route_choice != 1? (){
                      setState(() {
                        _isLoaded = false;
                      });
                      _setRoute(1);
                      _subscribeToCoordinates();
                      _updateRoutes();
                    } : null),
                DrawerListTile(
                    Route: JeepRoutes[2],
                    icon: Image.asset(JeepSide[2]),
                    isSelected: route_choice == 2,
                    press: route_choice != 2? (){
                      setState(() {
                        _isLoaded = false;
                      });
                      _setRoute(2);
                      _subscribeToCoordinates();
                      _updateRoutes();
                    } : null),
                DrawerListTile(
                    Route: JeepRoutes[3],
                    icon: Image.asset(JeepSide[3]),
                    isSelected: route_choice == 3,
                    press: route_choice != 3? (){
                      setState(() {
                        _isLoaded = false;
                      });
                      _setRoute(3);
                      _subscribeToCoordinates();
                      _updateRoutes();
                    } : null),
                DrawerListTile(
                    Route: JeepRoutes[4],
                    icon: Image.asset(JeepSide[4]),
                    isSelected: route_choice == 4,
                    press: route_choice != 4? (){
                      setState(() {
                        _isLoaded = false;
                      });
                      _setRoute(4);
                      _subscribeToCoordinates();
                      _updateRoutes();
                    } : null),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if(!Responsive.isMobile(context))
            MapboxMap(
              accessToken: Keys.MapBoxKey,
              styleString: Keys.MapBoxNight,
              zoomGesturesEnabled: !isMouseHoveringRouteInfo && !isMouseHoveringDrawer,
              scrollGesturesEnabled: !isMouseHoveringRouteInfo && !isMouseHoveringDrawer,
              dragEnabled: !isMouseHoveringRouteInfo && !isMouseHoveringDrawer,
              minMaxZoomPreference: const MinMaxZoomPreference(14, 19),
              tiltGesturesEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                _onMapCreated(controller);
              },
              initialCameraPosition: CameraPosition(
                target: Keys.MapCenter,
                zoom: 15,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(Responsive.isDesktop(context))
                Expanded(
                  flex: 1,
                  child: MouseRegion(
                    onEnter: (event) {
                      setState((){
                        isMouseHoveringDrawer = true;
                      });
                    },
                    onExit: (event) {
                      setState((){
                        isMouseHoveringDrawer = false;
                      });
                    },
                    child: Drawer(
                      elevation: 0.0,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                DrawerHeader(
                                    child: Image.asset(
                                      'assets/logo.png'
                                    )
                                ),
                                DrawerListTile(
                                    Route: JeepRoutes[0],
                                    icon: Image.asset(JeepSide[0]),
                                    isSelected: route_choice == 0,
                                    press: route_choice != 0? (){
                                      setState(() {
                                        _isLoaded = false;
                                      });
                                      _setRoute(0);
                                      _subscribeToCoordinates();
                                      _updateRoutes();
                                    } : null),
                                DrawerListTile(
                                    Route: JeepRoutes[1],
                                    icon: Image.asset(JeepSide[1]),
                                    isSelected: route_choice == 1,
                                    press: route_choice != 1? (){
                                      setState(() {
                                        _isLoaded = false;
                                      });
                                      _setRoute(1);
                                      _subscribeToCoordinates();
                                      _updateRoutes();
                                    } : null),
                                DrawerListTile(
                                    Route: JeepRoutes[2],
                                    icon: Image.asset(JeepSide[2]),
                                    isSelected: route_choice == 2,
                                    press: route_choice != 2? (){
                                      setState(() {
                                        _isLoaded = false;
                                      });
                                      _setRoute(2);
                                      _subscribeToCoordinates();
                                      _updateRoutes();
                                    } : null),
                                DrawerListTile(
                                    Route: JeepRoutes[3],
                                    icon: Image.asset(JeepSide[3]),
                                    isSelected: route_choice == 3,
                                    press: route_choice != 3? (){
                                      setState(() {
                                        _isLoaded = false;
                                      });
                                      _setRoute(3);
                                      _subscribeToCoordinates();
                                      _updateRoutes();
                                    } : null),
                                DrawerListTile(
                                    Route: JeepRoutes[4],
                                    icon: Image.asset(JeepSide[4]),
                                    isSelected: route_choice == 4,
                                    press: route_choice != 4? (){
                                      setState(() {
                                        _isLoaded = false;
                                      });
                                      _setRoute(4);
                                      _subscribeToCoordinates();
                                      _updateRoutes();
                                    } : null),
                              ],
                            ),
                            SizedBox(height: Constants.defaultPadding),
                            GestureDetector(
                              onTap: (){
                                setState((){
                                  showPickUps = !showPickUps;
                                  _heatmapCircles.forEach((element) {
                                    _mapController.updateCircle(element.data, CircleOptions(
                                     circleRadius: showPickUps?10:0,
                                    ));
                                  });
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(Constants.defaultPadding),
                                color: Constants.bgColor,
                                child: showPickUps?Text("Showing Pick Ups"):Text("Hiding Pick Ups"),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    height: SizeConfig.screenHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 6,
                            child: !Responsive.isMobile(context)?MouseRegion(
                                onEnter: (event) {
                                  setState((){
                                    isMouseHoveringDrawer = true;
                                  });
                                },
                                onExit: (event) {
                                  setState((){
                                    isMouseHoveringDrawer = false;
                                  });
                                },
                                child: Header()):
                            StreamBuilder(
                              stream: FireStoreDataBase().fetchJeepData(route_choice),
                              builder: (context, snapshot) {
                                if(snapshot.connectionState == ConnectionState.waiting){
                                  return SizedBox();
                                }
                                var data = snapshot.data!;
                                double operating = data.where((jeep) => jeep.is_embark).length.toDouble();
                                double not_operating = data.where((jeep) => !jeep.is_embark).length.toDouble();
                                double passenger_count = data.fold(0, (int previousValue, JeepData jeepney) => previousValue + jeepney.passenger_count).toDouble();
                                return Stack(
                                  children: [
                                    Column(
                                      children: [
                                        Expanded(
                                          flex: 71,
                                          child: Container(
                                            child: MapboxMap(
                                              accessToken: Keys.MapBoxKey,
                                              styleString: Keys.MapBoxNight,
                                              zoomGesturesEnabled: !isMouseHoveringRouteInfo,
                                              scrollGesturesEnabled: !isMouseHoveringRouteInfo,
                                              dragEnabled: !isMouseHoveringRouteInfo,
                                              minMaxZoomPreference: const MinMaxZoomPreference(12, 19),
                                              doubleClickZoomEnabled: false,
                                              rotateGesturesEnabled: false,
                                              tiltGesturesEnabled: false,
                                              compassEnabled: false,
                                              onMapCreated: (controller) {
                                                _onMapCreated(controller);
                                              },
                                              initialCameraPosition: CameraPosition(
                                                target: Keys.MapCenter,
                                                zoom: 15.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
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
                                            padding: const EdgeInsets.all(Constants.defaultPadding),
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
                                                                          Text(
                                                                            "${passenger_count} passengers",
                                                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white54),
                                                                            textAlign: TextAlign.end,
                                                                            maxLines: 1,
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      RichText(
                                                                        textAlign: TextAlign.center,
                                                                        text: TextSpan(
                                                                          children: [
                                                                            TextSpan(
                                                                              text: '$operating',
                                                                              style: Theme.of(context).textTheme.headline4?.copyWith(
                                                                                  color: Colors.white,
                                                                                  fontWeight: FontWeight.w600,
                                                                                  height: 0.5,
                                                                                  fontSize: 20
                                                                              ),
                                                                            ),
                                                                            TextSpan(
                                                                              text: "/${operating + not_operating}",
                                                                              style: Theme.of(context).textTheme.headline4?.copyWith(
                                                                                  color: Colors.white,
                                                                                  fontWeight: FontWeight.w800,
                                                                                  fontSize: 14,
                                                                                  height: 0.5
                                                                              ),
                                                                            ),
                                                                            TextSpan(
                                                                              text: '\njeeps',
                                                                              style: Theme.of(context).textTheme.headline4?.copyWith(
                                                                                color: Colors.white54,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontSize: 14,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
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
                                                              itemCount: data.where((element) => element.is_embark).length, // Replace with the actual item count
                                                              itemBuilder: (context, index) {
                                                                return GestureDetector(
                                                                    onTap: () {
                                                                      if(isHoverJeep){
                                                                        setState((){
                                                                          isHoverJeep = false;
                                                                          for (var i = 0; i < _jeeps.length; i++) {
                                                                            _mapController.updateSymbol(_jeeps[i], SymbolOptions(
                                                                              iconOpacity: 1,
                                                                            ));
                                                                          }
                                                                        });
                                                                      } else {
                                                                        setState((){
                                                                          isHoverJeep = true;
                                                                          hoveredJeep = index;
                                                                          for (var i = 0; i < _jeeps.length; i++) {
                                                                            _mapController.updateSymbol(_jeeps[i], SymbolOptions(
                                                                              iconOpacity: i==hoveredJeep?1:0.5,
                                                                            ));
                                                                          }
                                                                        });
                                                                      }

                                                                    },
                                                                    child: JeepInfoCard(route_choice: route_choice, data: data, index: index, isHovered: hoveredJeep == index && isHoverJeep,)
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
                                );
                              }
                            )
                        ),
                        if(!Responsive.isMobile(context))
                          SizedBox(width: Constants.defaultPadding),
                        if(!Responsive.isMobile(context))
                          Expanded(
                              flex: 2,
                              child: MouseRegion(
                                onEnter: (event) {
                                  setState((){
                                    isMouseHoveringDrawer = true;
                                  });
                                },
                                onExit: (event) {
                                  setState((){
                                    isMouseHoveringDrawer = false;
                                  });
                                },
                                child: SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(left: Constants.defaultPadding, right: Constants.defaultPadding, top: Constants.defaultPadding),
                                        decoration: const BoxDecoration(
                                          color: Constants.secondaryColor,
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                        ),
                                        child: selectedTab == 0
                                            ?StreamBuilder(
                                            stream: FireStoreDataBase().fetchJeepData(route_choice),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData || snapshot.hasError) {
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
                                                                    padding: const EdgeInsets.all(Constants.defaultPadding),
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
                                                          physics: isMouseHoveringRouteInfo?AlwaysScrollableScrollPhysics():NeverScrollableScrollPhysics(),
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
                                              var data = snapshot.data!;
                                              double operating = data.where((jeep) => jeep.is_embark).length.toDouble();
                                              double not_operating = data.where((jeep) => !jeep.is_embark).length.toDouble();
                                              double passenger_count = data.fold(0, (int previousValue, JeepData jeepney) => previousValue + jeepney.passenger_count).toDouble();
                                              return Container(
                                                margin: const EdgeInsets.only(left: Constants.defaultPadding, right: Constants.defaultPadding, top: Constants.defaultPadding),
                                                decoration: const BoxDecoration(
                                                  color: Constants.secondaryColor,
                                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: SingleChildScrollView(
                                                        physics: isMouseHoveringRouteInfo?AlwaysScrollableScrollPhysics():NeverScrollableScrollPhysics(),
                                                        padding: const EdgeInsets.all(Constants.defaultPadding),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    JeepRoutes[route_choice].name,
                                                                    style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    "${passenger_count} passengers",
                                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white54),
                                                                    textAlign: TextAlign.end,
                                                                    maxLines: 2,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(height: Constants.defaultPadding),
                                                            route_info_chart(route_choice: route_choice, operating: operating, not_operating: not_operating),
                                                            ListView.builder(
                                                              shrinkWrap: true,
                                                              itemCount: data.where((element) => element.is_embark).length, // Replace with the actual item count
                                                              itemBuilder: (context, index) {
                                                                return MouseRegion(
                                                                    onEnter: (event) {
                                                                      setState((){
                                                                        isHoverJeep = true;
                                                                        hoveredJeep = index;
                                                                        for (var i = 0; i < _jeeps.length; i++) {
                                                                          _mapController.updateSymbol(_jeeps[i], SymbolOptions(
                                                                            iconOpacity: i==hoveredJeep?1:0.5,
                                                                          ));
                                                                        }
                                                                      });
                                                                    },
                                                                    onExit: (event) {
                                                                      setState((){
                                                                        isHoverJeep = false;
                                                                        hoveredJeep = index;
                                                                        for (var i = 0; i < _jeeps.length; i++) {
                                                                          _jeeps.forEach((element) {
                                                                            _mapController.updateSymbol(element, const SymbolOptions(
                                                                              iconOpacity: 1,
                                                                            ));
                                                                          });
                                                                        }
                                                                      });
                                                                    },
                                                                    child: JeepInfoCard(route_choice: route_choice, data: data, index: index, isHovered: hoveredJeep == index && isHoverJeep,)
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                        )
                                            :StreamBuilder(
                                            stream: FireStoreDataBase().fetchHeatMapRide(route_choice),
                                            builder: (context, heatmapsnapshot) {
                                              if (!heatmapsnapshot.hasData || heatmapsnapshot.hasError){
                                                return const SizedBox();
                                              } else {
                                                var data = heatmapsnapshot.data!;
                                                double passenger_pickedUp = data.fold(0, (int previousValue, HeatMapRideData heatmap) => previousValue + heatmap.passenger_count).toDouble();
                                                return Container(
                                                  margin: const EdgeInsets.only(left: Constants.defaultPadding, right: Constants.defaultPadding, top: Constants.defaultPadding),
                                                  decoration: const BoxDecoration(
                                                    color: Constants.secondaryColor,
                                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: SingleChildScrollView(
                                                          physics: isMouseHoveringRouteInfo?AlwaysScrollableScrollPhysics():NeverScrollableScrollPhysics(),
                                                          padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      JeepRoutes[route_choice].name,
                                                                      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      "$passenger_pickedUp passengers picked up",
                                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white54),
                                                                      textAlign: TextAlign.end,
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(height: Constants.defaultPadding),
                                                              ListView.builder(
                                                                shrinkWrap: true,
                                                                itemCount: data.length, // Replace with the actual item count
                                                                itemBuilder: (context, index) {
                                                                  return StreamBuilder(
                                                                      stream: getAddressFromLatLngStream(data[index].location.latitude, data[index].location.longitude),
                                                                      builder: (context, snapshot) {
                                                                        if(snapshot.data == null){
                                                                          return const PickUpsShimmer();
                                                                        }
                                                                        return Container(
                                                                          padding: const EdgeInsets.all(Constants.defaultPadding),
                                                                          margin: const EdgeInsets.only(bottom: Constants.defaultPadding),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.red.withOpacity(0.02*data[index].passenger_count),
                                                                            border: Border.all(
                                                                              width: 2,
                                                                              color: JeepRoutes[route_choice].color.withOpacity(0.15),
                                                                            ),
                                                                            borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                                          ),
                                                                          child: Expanded(
                                                                              child: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text("${snapshot.data}", maxLines: 1, overflow: TextOverflow.ellipsis),
                                                                                  Text("${data[index].passenger_count} passengers picked up", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                                                ],
                                                                              )
                                                                          ),
                                                                        );
                                                                      }
                                                                  );
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                            }
                                        ),
                                      ),
                                      Container(
                                        height: 50,
                                        margin: const EdgeInsets.only(left: Constants.defaultPadding, right: Constants.defaultPadding, bottom: Constants.defaultPadding),
                                        decoration: const BoxDecoration(
                                          color: Constants.bgColor,
                                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: (){
                                                  if(selectedTab != 0){
                                                    setState((){
                                                      selectedTab = 0;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  height: 50,
                                                  padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                                                  child: Center(
                                                    child: Text("Route Info", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                                        color: selectedTab == 0? Colors.white:Constants.secondary
                                                    )),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: (){
                                                  if(selectedTab != 1){
                                                    setState((){
                                                      selectedTab = 1;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  height: 50,
                                                  padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                                                  child: Center(
                                                    child: Text("Pick-Ups", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                                        color: selectedTab == 1? Colors.white:Constants.secondary
                                                    )),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: (){
                                                  // if(selectedTab != 2){
                                                  //   setState((){
                                                  //     selectedTab = 2;
                                                  //   });
                                                  // }
                                                },
                                                child: Container(
                                                  height: 50,
                                                  padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                                                  child:  Center(
                                                    child: Text("Drop-Offs", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                                        color: selectedTab == 2? Colors.white:Constants.secondary
                                                    )
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                          )
                      ],
                    )
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}








