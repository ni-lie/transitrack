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
                                      MapboxMap(
                                        accessToken: Keys.MapBoxKey,
                                        styleString: Keys.MapBoxNight,
                                        zoomGesturesEnabled: !isMouseHoveringRouteInfo && !isMouseHoveringDrawer,
                                        scrollGesturesEnabled: !isMouseHoveringRouteInfo && !isMouseHoveringDrawer,
                                        dragEnabled: !isMouseHoveringRouteInfo && !isMouseHoveringDrawer,
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
                                      Column(
                                        children: [
                                          Expanded(
                                            flex: 6,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                MouseRegion(
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
                                                  child: Header()),
                                              ],
                                            )),
                                          Expanded(
                                            flex: 3,
                                            child: Container(
                                              padding: const EdgeInsets.all(Constants.defaultPadding),
                                              decoration: const BoxDecoration(
                                                color: Constants.secondaryColor,
                                                borderRadius: BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10)),
                                              ),
                                              child: SingleChildScrollView(
                                                physics: isMouseHoveringRouteInfo?AlwaysScrollableScrollPhysics():NeverScrollableScrollPhysics(),
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
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                  // CustomScrollView(
                                  //   physics: isMouseHoveringRouteInfo?AlwaysScrollableScrollPhysics():NeverScrollableScrollPhysics(),
                                  //
                                  //   slivers: [
                                  //     SliverAppBar(
                                  //       elevation: 0,
                                  //       automaticallyImplyLeading: false,
                                  //       toolbarHeight: 70,
                                  //       bottom: PreferredSize(
                                  //         preferredSize: Size.fromHeight(),
                                  //         child: GestureDetector(
                                  //           onTapDown: (event) {
                                  //             setState((){
                                  //               isMouseHoveringRouteInfo = true;
                                  //             });
                                  //           },
                                  //           onTapUp: (event) {
                                  //             setState((){
                                  //               isMouseHoveringRouteInfo = false;
                                  //             });
                                  //           },
                                  //           child: Container(
                                  //             width: double.maxFinite,
                                  //             padding: EdgeInsets.all(Constants.defaultPadding),
                                  //             decoration: const BoxDecoration(
                                  //                 color: Constants.bgColor,
                                  //                 borderRadius: BorderRadius.only(
                                  //                     topLeft: Radius.circular(Constants.defaultPadding),
                                  //                     topRight: Radius.circular(Constants.defaultPadding)
                                  //                 )
                                  //             ),
                                  //             child: Row(
                                  //               children: [
                                  //                 Expanded(
                                  //                   child: Text(
                                  //                     JeepRoutes[route_choice].name,
                                  //                     style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                                  //                     maxLines: 1,
                                  //                     overflow: TextOverflow.ellipsis,
                                  //                   ),
                                  //                 ),
                                  //                 Expanded(
                                  //                   child: Text(
                                  //                     "${passenger_count} passengers",
                                  //                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white54),
                                  //                     textAlign: TextAlign.end,
                                  //                     maxLines: 1,
                                  //                     overflow: TextOverflow.ellipsis,
                                  //                   ),
                                  //                 ),
                                  //               ],
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       ),
                                  //       pinned: true,
                                  //       flexibleSpace: MapboxMap(
                                  //         accessToken: Keys.MapBoxKey,
                                  //         styleString: Keys.MapBoxNight,
                                  //         zoomGesturesEnabled: !isMouseHoveringRouteInfo && !isMouseHoveringDrawer,
                                  //         scrollGesturesEnabled: !isMouseHoveringRouteInfo && !isMouseHoveringDrawer,
                                  //         dragEnabled: !isMouseHoveringRouteInfo && !isMouseHoveringDrawer,
                                  //         tiltGesturesEnabled: false,
                                  //         compassEnabled: false,
                                  //         onMapCreated: (controller) {
                                  //           _onMapCreated(controller);
                                  //         },
                                  //         initialCameraPosition: CameraPosition(
                                  //           target: Keys.MapCenter,
                                  //           zoom: 15.0,
                                  //         ),
                                  //       ),
                                  //     ),
                                  //     SliverToBoxAdapter(
                                  //       child: MouseRegion(
                                  //         onEnter: (event) {
                                  //           setState((){
                                  //             isMouseHoveringRouteInfo = true;
                                  //           });
                                  //         },
                                  //         onExit: (event) {
                                  //           setState((){
                                  //             isMouseHoveringRouteInfo = false;
                                  //           });
                                  //         },
                                  //         child: Container(
                                  //           color: Constants.bgColor,
                                  //           child: SingleChildScrollView(
                                  //             child: Column(
                                  //               children: [
                                  //                 SizedBox(height: Constants.defaultPadding),
                                  //                 route_info_chart(route_choice: route_choice, operating: operating, not_operating: not_operating),
                                  //                 ListView.builder(
                                  //                   shrinkWrap: true,
                                  //                   itemCount: data.where((element) => element.is_embark).length, // Replace with the actual item count
                                  //                   itemBuilder: (context, index) {
                                  //                     return MouseRegion(
                                  //                         onEnter: (event) {
                                  //                           setState((){
                                  //                             isHoverJeep = true;
                                  //                             hoveredJeep = index;
                                  //                             for (var i = 0; i < _jeeps.length; i++) {
                                  //                               _mapController.updateSymbol(_jeeps[i], SymbolOptions(
                                  //                                 iconOpacity: i==hoveredJeep?1:0.5,
                                  //                               ));
                                  //                             }
                                  //                           });
                                  //                         },
                                  //                         onExit: (event) {
                                  //                           setState((){
                                  //                             isHoverJeep = false;
                                  //                             hoveredJeep = index;
                                  //                             for (var i = 0; i < _jeeps.length; i++) {
                                  //                               _jeeps.forEach((element) {
                                  //                                 _mapController.updateSymbol(element, const SymbolOptions(
                                  //                                   iconOpacity: 1,
                                  //                                 ));
                                  //                               });
                                  //                             }
                                  //                           });
                                  //                         },
                                  //                         child: JeepInfoCard(route_choice: route_choice, data: data, index: index, isHovered: hoveredJeep == index && isHoverJeep,)
                                  //                     );
                                  //                   },
                                  //                 ),
                                  //               ],
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       ),
                                  //
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







