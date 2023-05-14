import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import '../MenuController.dart';
import '../components/header.dart';
import '../components/jeep_info_card.dart';
import '../components/route_info_chart.dart';
import '../components/sidemenu.dart';
import '../config/keys.dart';
import '../config/responsive.dart';
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
  bool isMouseHoveringRouteInfo = false;
  bool isMouseHoveringDrawer = false;

  bool isHoverJeep = false;
  int hoveredJeep = -1;
  bool _isLoaded = false;

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
            iconSize: 0.1,
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
    setState(() {
      _isLoaded = true;
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
          child: GestureDetector(
            onPanStart: (event) {
              setState((){
                isMouseHoveringDrawer = true;
              });
            },
            onPanUpdate: (event) {
              setState((){
                isMouseHoveringDrawer = true;
              });
            },
            onPanEnd: (event) {
              setState((){
                isMouseHoveringDrawer = false;
              });
            },
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
                          children: [
                            DrawerHeader(
                                child: Icon(Icons.directions_transit)
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
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    height: SizeConfig.screenHeight,
                    child: StreamBuilder(
                        stream: JeepInfo,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.hasError) {
                            return SizedBox();
                          }
                          var data = snapshot.data!;
                          double operating = data.where((jeep) => jeep.is_embark).length.toDouble();
                          double not_operating = data.where((jeep) => !jeep.is_embark).length.toDouble();
                          double passenger_count = data.fold(0, (int previousValue, JeepData jeepney) => previousValue + jeepney.passenger_count).toDouble();
                          return  Row(
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
                                  Stack(
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
                                  )
                                  // Stack(
                                  //   children: [
                                  //     MapboxMap(
                                  //       accessToken: Keys.MapBoxKey,
                                  //       styleString: Keys.MapBoxNight,
                                  //       zoomGesturesEnabled: !isMouseHoveringRouteInfo,
                                  //       scrollGesturesEnabled: !isMouseHoveringRouteInfo,
                                  //       dragEnabled: !isMouseHoveringRouteInfo,
                                  //       doubleClickZoomEnabled: false,
                                  //       rotateGesturesEnabled: false,
                                  //       tiltGesturesEnabled: false,
                                  //       compassEnabled: false,
                                  //       onMapCreated: (controller) {
                                  //         _onMapCreated(controller);
                                  //       },
                                  //       initialCameraPosition: CameraPosition(
                                  //         target: Keys.MapCenter,
                                  //         zoom: 15.0,
                                  //       ),
                                  //     ),
                                  //     Column(
                                  //       children: [
                                  //         Expanded(
                                  //           flex: 6,
                                  //           child: Column(
                                  //             mainAxisAlignment: MainAxisAlignment.start,
                                  //             children: [
                                  //               Header(),
                                  //             ],
                                  //           )),
                                  //         Expanded(
                                  //           flex: 3,
                                  //           child: Container(
                                  //             padding: const EdgeInsets.all(Constants.defaultPadding),
                                  //             decoration: const BoxDecoration(
                                  //               color: Constants.secondaryColor,
                                  //               borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                                  //             ),
                                  //             child: SingleChildScrollView(
                                  //               physics: AlwaysScrollableScrollPhysics(),
                                  //               child: MouseRegion(
                                  //                 onEnter: (event) {
                                  //                   setState((){
                                  //                     isMouseHoveringRouteInfo = true;
                                  //                   });
                                  //                 },
                                  //                 onExit: (event) {
                                  //                   setState((){
                                  //                     isMouseHoveringRouteInfo = false;
                                  //                   });
                                  //                 },
                                  //                 child: GestureDetector(
                                  //                   onTap: () {
                                  //                     setState((){
                                  //                       isMouseHoveringRouteInfo = true;
                                  //                     });
                                  //                   },
                                  //                   onPanUpdate: (event) {
                                  //                     setState((){
                                  //                       isMouseHoveringRouteInfo = true;
                                  //                     });
                                  //                   },
                                  //                   onPanEnd: (event) {
                                  //                     setState((){
                                  //                       isMouseHoveringRouteInfo = false;
                                  //                     });
                                  //                   },
                                  //                   child: Container(
                                  //                     child: Row(
                                  //                       children: [
                                  //                         Expanded(
                                  //                           child: Column(
                                  //                             crossAxisAlignment: CrossAxisAlignment.start,
                                  //                             children: [
                                  //                               Row(
                                  //                                 children: [
                                  //                                   Expanded(
                                  //                                     child: Row(
                                  //                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //                                       children: [
                                  //                                         Column(
                                  //                                           crossAxisAlignment: CrossAxisAlignment.start,
                                  //                                           children: [
                                  //                                             Text(
                                  //                                               JeepRoutes[route_choice].name,
                                  //                                               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                  //                                               maxLines: 1,
                                  //                                               overflow: TextOverflow.ellipsis,
                                  //                                             ),
                                  //                                             Text(
                                  //                                               "${passenger_count} passengers",
                                  //                                               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white54),
                                  //                                               textAlign: TextAlign.end,
                                  //                                               maxLines: 1,
                                  //                                               overflow: TextOverflow.ellipsis,
                                  //                                             ),
                                  //                                           ],
                                  //                                         ),
                                  //                                         RichText(
                                  //                                           textAlign: TextAlign.center,
                                  //                                           text: TextSpan(
                                  //                                             children: [
                                  //                                               TextSpan(
                                  //                                                 text: '$operating',
                                  //                                                 style: Theme.of(context).textTheme.headline4?.copyWith(
                                  //                                                   color: Colors.white,
                                  //                                                   fontWeight: FontWeight.w600,
                                  //                                                   height: 0.5,
                                  //                                                   fontSize: 20
                                  //                                                 ),
                                  //                                               ),
                                  //                                               TextSpan(
                                  //                                                 text: "/${operating + not_operating}",
                                  //                                                 style: Theme.of(context).textTheme.headline4?.copyWith(
                                  //                                                   color: Colors.white,
                                  //                                                   fontWeight: FontWeight.w800,
                                  //                                                   fontSize: 14,
                                  //                                                   height: 0.5
                                  //                                                 ),
                                  //                                               ),
                                  //                                               TextSpan(
                                  //                                                 text: '\njeeps',
                                  //                                                 style: Theme.of(context).textTheme.headline4?.copyWith(
                                  //                                                   color: Colors.white54,
                                  //                                                   fontWeight: FontWeight.w600,
                                  //                                                   fontSize: 14,
                                  //                                                 ),
                                  //                                               ),
                                  //                                             ],
                                  //                                           ),
                                  //                                         ),
                                  //                                       ],
                                  //                                     ),
                                  //                                   ),
                                  //                                 ],
                                  //                               ),
                                  //                               SizedBox(height: Constants.defaultPadding),
                                  //                               // route_info_chart(route_choice: route_choice, operating: operating, not_operating: not_operating),
                                  //                               ListView.builder(
                                  //                                 shrinkWrap: true,
                                  //                                 physics: NeverScrollableScrollPhysics(),
                                  //                                 itemCount: data.where((element) => element.is_embark).length, // Replace with the actual item count
                                  //                                 itemBuilder: (context, index) {
                                  //                                   return GestureDetector(
                                  //                                       onTap: () {
                                  //                                         if(isHoverJeep){
                                  //                                           setState((){
                                  //                                             isHoverJeep = false;
                                  //                                             for (var i = 0; i < _jeeps.length; i++) {
                                  //                                               _mapController.updateSymbol(_jeeps[i], SymbolOptions(
                                  //                                                 iconOpacity: 1,
                                  //                                               ));
                                  //                                             }
                                  //                                           });
                                  //                                         } else {
                                  //                                           setState((){
                                  //                                             isHoverJeep = true;
                                  //                                             hoveredJeep = index;
                                  //                                             for (var i = 0; i < _jeeps.length; i++) {
                                  //                                               _mapController.updateSymbol(_jeeps[i], SymbolOptions(
                                  //                                                 iconOpacity: i==hoveredJeep?1:0.5,
                                  //                                               ));
                                  //                                             }
                                  //                                           });
                                  //                                         }
                                  //
                                  //                                       },
                                  //                                       child: JeepInfoCard(route_choice: route_choice, data: data, index: index, isHovered: hoveredJeep == index && isHoverJeep,)
                                  //                                   );
                                  //                                 },
                                  //                               ),
                                  //                             ],
                                  //                           ),
                                  //                         ),
                                  //                       ],
                                  //                     ),
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       ],
                                  //     )
                                  //   ],
                                  // )
                              ),
                              if(!Responsive.isMobile(context))
                                SizedBox(width: Constants.defaultPadding),
                              if(!Responsive.isMobile(context))
                                Expanded(
                                  flex: 2,
                                  child: MouseRegion(
                                    onEnter: (event) {
                                      setState((){
                                        isMouseHoveringRouteInfo = true;
                                      });
                                    },
                                    onExit: (event) {
                                      setState((){
                                        isMouseHoveringRouteInfo = false;
                                      });
                                    },
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
                                                          maxLines: 1,
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
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                              )
                            ],
                          );
                        }
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







