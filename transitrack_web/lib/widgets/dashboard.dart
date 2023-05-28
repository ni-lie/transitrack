import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transitrack_web/widgets/shimmer_desktop_route_info.dart';
import 'package:transitrack_web/widgets/shimmer_widget.dart';
import '../MenuController.dart';
import '../components/firestore/download_heatmap_csv.dart';
import '../components/firestore/download_historical_jeep_csv.dart';
import '../components/header.dart';
import '../components/jeep_info_card.dart';
import '../components/jeep_info_card_detailed.dart';
import '../components/route_info_chart.dart';
import '../components/route_info_panel_shimmer_v2.dart';
import '../components/select_jeep_info.dart';
import '../components/sidemenu.dart';
import '../config/keys.dart';
import '../config/responsive.dart';
import '../config/route_coordinates.dart';
import '../config/size_config.dart';
import '../database_manager.dart';
import '../models/heatmap_model.dart';
import '../models/jeep_model.dart';
import '../style/constants.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late MapboxMapController _mapController;
  late StreamSubscription<List<JeepData>> jeepListener;

  double _opacityHeatmap = 0.1;
  double _radiusHeatMap = 10;

  int route_choice = -1;
  List<JeepEntity> _jeeps = [];
  List<Line> _lines = [];
  List<HeatMapEntity> _heatmapRideCircles = [];
  List<HeatMapEntity> _heatmapDropCircles = [];
  bool isMouseHoveringRouteInfo = false;
  bool isMouseHoveringDrawer = false;

  bool isHoverJeep = false;
  int hoveredJeep = -1;
  bool _isLoaded = false;
  bool showPickUps = false;
  bool showDropOffs = false;
  bool _tappedCircle = false;

  bool _showHeatMapTab = false;
  bool _showJeepHistoryTab = false;
  bool _isListeningJeep = false;
  bool _selectSettingsHeatMap = false;

  
  void _setRoute(int choice){
    setState(() {
      route_choice = choice;
    });
  }

  void _addSymbols(List<JeepData> Jeepneys) {
    setState((){
      isHoverJeep = false;
    });
    for (var Jeepney in Jeepneys) {
      // double angleRadians = atan2(Jeepney.acceleration[1], Jeepney.acceleration[0]);
      // double angleDegrees = angleRadians * (180 / pi);
      int half = (Jeepney.slots_remaining+Jeepney.passenger_count)~/2;
      final jeepEntity = SymbolOptions(
          geometry: LatLng(Jeepney.location.latitude, Jeepney.location.longitude),
          iconSize: 0.1,
          iconImage: JeepRoutes[route_choice].image,
          textSize: 20,
          textField: "■",
          textColor: Jeepney.passenger_count < half?"#00FF00":(Jeepney.slots_remaining == 0?"#FF0000":"#0000FF"),
          textRotate: Jeepney.gyroscope[0]-90,
          iconRotate: Jeepney.gyroscope[0],
          iconOpacity: Jeepney.is_active?(isHoverJeep?(pressedJeep.jeep==Jeepney?1:0.4):1):0,
          textOpacity: Jeepney.is_active?(isHoverJeep?(pressedJeep.jeep==Jeepney?1:0.4):1):0,
      );
      _mapController.addSymbol(jeepEntity).then((jeepSymbol) {
        _jeeps.add(JeepEntity(jeep: Jeepney, data: jeepSymbol));
      });
    }
  }

  void _addCirclesDrop(List<JeepData> Jeepneys) {
    for (var element in Jeepneys) {
      _mapController.addCircle(CircleOptions(
          geometry: LatLng(element.location.latitude, element.location.longitude),
          circleRadius: showDropOffs?_radiusHeatMap:0,
          circleColor: '#00FF00',
          circleOpacity: _opacityHeatmap
      )
      ).then((heatmap) {
        _heatmapDropCircles.add(HeatMapEntity(heatmap: element, data: heatmap));
      });
    }
  }

  void _addCirclesRide(List<JeepData> Jeepneys) {
    for (var element in Jeepneys) {
      _mapController.addCircle(CircleOptions(
          geometry: LatLng(element.location.latitude, element.location.longitude),
          circleRadius: showPickUps?_radiusHeatMap:0,
          circleColor: '#FF0000',
          circleOpacity: _opacityHeatmap
      )
      ).then((heatmap) {
        _heatmapRideCircles.add(HeatMapEntity(heatmap: element, data: heatmap));
      });
    }
  }

  void _updateSymbols(List<JeepData> Jeepneys) {
    List<String> device_ids_new = Jeepneys.map((jeepData) => jeepData.device_id).toList();
    List<JeepEntity> elementsNotInList2 = _jeeps.where((element1) => !device_ids_new.contains(element1.jeep.device_id)).toList();

    for (var element in elementsNotInList2) {
      if(pressedJeep == element){
        isHoverJeep = false;
      }
      _mapController.removeSymbol(element.data);
    }

    for (var Jeepney in Jeepneys) {
      if(isHoverJeep){
        if(pressedJeep.jeep.device_id == Jeepney.device_id){
          pressedJeep.jeep = Jeepney;
        }
      }
      // double angleRadians = atan2(Jeepney.acceleration[1], Jeepney.acceleration[0]);
      // double angleDegrees = angleRadians * (180 / pi);
      if(_jeeps.any((element) => element.jeep.device_id == Jeepney.device_id)){
        var symbolToUpdate = _jeeps.firstWhere((symbol) => symbol.jeep.device_id == Jeepney.device_id);
        if(isHoverJeep && pressedJeep.jeep.device_id == Jeepney.device_id){
          pressedJeep.jeep.location = Jeepney.location;
          if(!pressedJeep.jeep.is_active){
            isHoverJeep = false;
          }
        }
        int half = (Jeepney.slots_remaining+Jeepney.passenger_count)~/2;
        _mapController.updateSymbol(symbolToUpdate.data, SymbolOptions(
            geometry: LatLng(Jeepney.location.latitude, Jeepney.location.longitude),
            iconRotate: Jeepney.gyroscope[0],
            iconOpacity: Jeepney.is_active?(isHoverJeep?(pressedJeep.jeep==Jeepney?1:0.4):1):0,
            textColor: Jeepney.passenger_count < half?"#00FF00":(Jeepney.slots_remaining == 0?"#FF0000":"#0000FF"),
            textOpacity: Jeepney.is_active?(isHoverJeep?(pressedJeep.jeep==Jeepney?1:0.4):1):0,
            textRotate: Jeepney.gyroscope[0]-90,
        ));

      } else {
        int half = (Jeepney.slots_remaining+Jeepney.passenger_count)~/2;
        final jeepEntity = SymbolOptions(
          geometry: LatLng(Jeepney.location.latitude, Jeepney.location.longitude),
          iconSize: 0.1,
          iconImage: JeepRoutes[route_choice].image,
          iconRotate: Jeepney.gyroscope[0],
          textColor: Jeepney.passenger_count < half?"#00FF00":(Jeepney.slots_remaining == 0?"#FF0000":"#0000FF"),
          textRotate: Jeepney.gyroscope[0]-90,
        );
        _mapController.addSymbol(jeepEntity).then((jeepSymbol) {
          _jeeps.add(JeepEntity(jeep: Jeepney, data: jeepSymbol));
        });
      }

    }
  }

  void _updateRoutes(){
    for (var element in _jeeps) {_mapController.removeSymbol(element.data);}
    _jeeps.clear();

    for (var line in _lines) {
      _mapController.removeLine(line);
    }
    _lines.clear();

    if(route_choice != -1){
      _mapController.addLine(Routes.RouteLines[route_choice]).then((line) {
        _lines.add(line);
      });
    }
  }


  Future<void> _subscribeToCoordinates() async {
    try{
      if(_showHeatMapTab){
        _subscribeHeatMap();
      }

      if(_showJeepHistoryTab){
        for (var element in _jeeps) {
          _mapController.removeSymbol(element.data);
        }
        _jeeps.clear();
        List<JeepData> test = await FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(route_choice, Timestamp.fromDate(selectedDateTimeAnalysis));
        _addSymbols(test);
      } else {
        List<JeepData> test = await FireStoreDataBase().loadJeepsByRouteId(route_choice);
        _addSymbols(test);

        if(route_choice != -1){
          jeepListener = FireStoreDataBase().fetchJeepData(route_choice).listen((event) async {
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
        }
        
        _isListeningJeep = true;
        setState(() {
          _isLoaded = true;
        });
      }
    }catch(e){
      print(e);
    }
  }

  Future<void> _subscribeToHeatMapDrop() async {
    for (var heatmap in _heatmapDropCircles) {
      _mapController.removeCircle(heatmap.data);
    }
    _heatmapDropCircles.clear();

    List<JeepData> heatmapDrop = await FireStoreDataBase().fetchHeatMapDrop(route_choice, Timestamp.fromDate(_selectedDateStartHeatMap), Timestamp.fromDate(_selectedDateEndHeatMap));
    _addCirclesDrop(heatmapDrop);
  }

  Future<void> _subscribeToHeatMapRide() async {
    for (var heatmap in _heatmapRideCircles) {
      _mapController.removeCircle(heatmap.data);
    }
    _heatmapRideCircles.clear();

    List<JeepData> heatmapRide = await FireStoreDataBase().fetchHeatMapRide(route_choice, Timestamp.fromDate(_selectedDateStartHeatMap), Timestamp.fromDate(_selectedDateEndHeatMap));
    _addCirclesRide(heatmapRide);
  }

  bool _isShowingCardRide = false;

  void _onCircleTapped(Circle circle){

    setState((){
      _isShowingCardRide = !_isShowingCardRide;
      _tappedCircle = !_tappedCircle;
    });

    if(_tappedCircle){
      if(circle.options.circleColor == '#FF0000'){
        pressedCircle = _heatmapRideCircles.firstWhere((element) => element.data == circle);
      } else {
        pressedCircle = _heatmapDropCircles.firstWhere((element) => element.data == circle);
      }
      _mapController.updateCircle(pressedCircle.data, CircleOptions(circleStrokeColor: "#FFFFFF", circleStrokeWidth: 3));
    } else {
      _mapController.updateCircle(pressedCircle.data, CircleOptions(circleStrokeWidth: 0));
    }

  }

  late JeepEntity pressedJeep;
  late HeatMapEntity pressedCircle;

  void _onSymbolTapped(Symbol jeep){
    if(jeep.options.iconSize != 0.7){
      if(isHoverJeep && pressedJeep.data != jeep){
        setState((){
          isHoverJeep = true;
        });
      } else {
        setState((){
          isHoverJeep = !isHoverJeep;
        });
      }

      pressedJeep = _jeeps.firstWhere((element) => element.data == jeep);


      if(isHoverJeep){
        for (var element in _jeeps) {
          if (element.jeep.device_id == pressedJeep.jeep.device_id){
            _mapController.updateSymbol(element.data, const SymbolOptions(
                iconSize: 0.13,
                iconOpacity: 1,
                textOpacity: 1,
            ));
          } else {
            _mapController.updateSymbol(element.data, SymbolOptions(
                iconSize: 0.1,
                iconOpacity: element.jeep.is_active?0.4:0,
                textOpacity: element.jeep.is_active?0.4:0,
            ));
          }
        }
      } else {
        for (var element in _jeeps) {
          _mapController.updateSymbol(element.data, SymbolOptions(
              iconSize: 0.1,
              iconOpacity: element.jeep.is_active?1:0,
              textOpacity: element.jeep.is_active?1:0,
          ));
        }
      }
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;

    _mapController.onCircleTapped.add(_onCircleTapped);
    _mapController.onSymbolTapped.add(_onSymbolTapped);

    setState((){
      _isLoaded = true;
    });
  }

  DateTime _selectedDateStartHeatMap = DateTime(2023, 5, 1, 0, 0);
  DateTime _selectedDateEndHeatMap = DateTime.now();

  void _stopListenJeep(){
    if(_isListeningJeep){
      jeepListener.cancel();
      _isListeningJeep = false;
    }
    for (var element in _jeeps) {
      _mapController.removeSymbol(element.data);
    }
    _jeeps.clear();
  }

  void switchRoute(int routeChoice) {
    _setRoute(routeChoice);
    _stopListenJeep();
    _subscribeToCoordinates();
    _updateRoutes();
  }

  Future<void> _subscribeHeatMap() async {
    setState((){
      _tappedCircle = false;
    });
    _subscribeToHeatMapRide();
    _subscribeToHeatMapDrop();
  }

  Future<void> _selectDateStartHeatMap(BuildContext context) async {
    isMouseHoveringRouteInfo = true;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateStartHeatMap,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateStartHeatMap) {
      setState(() {
        _selectedDateStartHeatMap = picked;
      });
      _subscribeHeatMap();
    }
    isMouseHoveringRouteInfo = false;
  }

  Future<void> _selectDateEndHeatMap(BuildContext context) async {
    isMouseHoveringRouteInfo = true;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateEndHeatMap,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateEndHeatMap) {
      setState(() {
        _selectedDateEndHeatMap = picked;
      });
      _subscribeHeatMap();
    }
    isMouseHoveringRouteInfo = false;
  }

  DateTime selectedDateTimeAnalysis = DateTime.now();

  Future<void> _selectDateTime(BuildContext context) async {
    isMouseHoveringRouteInfo = true;
    final DateTime? pickedDateTime = await showDatePicker(
      context: context,
      initialDate: selectedDateTimeAnalysis,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (pickedDateTime != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTimeAnalysis),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTimeAnalysis = DateTime(
            pickedDateTime.year,
            pickedDateTime.month,
            pickedDateTime.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
    for (var element in _jeeps) {
      _mapController.removeSymbol(element.data);
    }
    _jeeps.clear();
    List<JeepData> test = await FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(route_choice, Timestamp.fromDate(selectedDateTimeAnalysis));
    _addSymbols(test);
    isMouseHoveringRouteInfo = false;
  }

  Future<void> _addSeconds(int seconds, bool isAdd) async {
    if (selectedDateTimeAnalysis != null) {
      if(isAdd){
        setState(() {
          selectedDateTimeAnalysis = selectedDateTimeAnalysis.add(Duration(seconds: seconds));
        });
      } else {
        setState(() {
          selectedDateTimeAnalysis = selectedDateTimeAnalysis.subtract(Duration(seconds: seconds));
        });
      }
    }

    List<JeepData> test = await FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(route_choice, Timestamp.fromDate(selectedDateTimeAnalysis));
    _updateSymbols(test);
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
                        'assets/logo.png',
                        scale: 0.9
                    ),
                ),
                DrawerListTile(
                    Route: JeepRoutes[0],
                    icon: Image.asset(JeepSide[0]),
                    isSelected: route_choice == 0,
                    press: (){
                      if(route_choice == 0){
                        switchRoute(-1);
                      } else {
                        setState(() {
                          _isLoaded = false;
                        });
                        switchRoute(0);
                      }
                    }),
                DrawerListTile(
                    Route: JeepRoutes[1],
                    icon: Image.asset(JeepSide[1]),
                    isSelected: route_choice == 1,
                    press: (){
                      if(route_choice == 1){
                        switchRoute(-1);
                      } else {
                        setState(() {
                          _isLoaded = false;
                        });
                        switchRoute(1);
                      }
                    }),
                DrawerListTile(
                    Route: JeepRoutes[2],
                    icon: Image.asset(JeepSide[2]),
                    isSelected: route_choice == 2,
                    press: (){
                      if(route_choice == 2){
                        switchRoute(-1);
                      } else {
                        setState(() {
                          _isLoaded = false;
                        });
                        switchRoute(2);
                      }
                    }),
                DrawerListTile(
                    Route: JeepRoutes[3],
                    icon: Image.asset(JeepSide[3]),
                    isSelected: route_choice == 3,
                    press: (){
                      if(route_choice == 3){
                        switchRoute(-1);
                      } else {
                        setState(() {
                          _isLoaded = false;
                        });
                        switchRoute(3);
                      }
                    }),
                DrawerListTile(
                    Route: JeepRoutes[4],
                    icon: Image.asset(JeepSide[4]),
                    isSelected: route_choice == 4,
                    press: (){
                      if(route_choice == 4){
                        switchRoute(-1);
                      } else {
                        setState(() {
                          _isLoaded = false;
                        });
                        switchRoute(4);
                      }
                    }),
                const SizedBox(height: Constants.defaultPadding),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                    child: const Divider()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: GestureDetector(
                        onTap: (){
                          setState(() {
                            _showHeatMapTab = !_showHeatMapTab;
                          });
                          if(_showHeatMapTab){
                            _subscribeHeatMap();
                          } else {
                            for (var heatmap in _heatmapRideCircles) {
                              _mapController.removeCircle(heatmap.data);
                            }
                            _heatmapRideCircles.clear();

                            for (var heatmap in _heatmapDropCircles) {
                              _mapController.removeCircle(heatmap.data);
                            }
                            _heatmapDropCircles.clear();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(Constants.defaultPadding),
                          margin: const EdgeInsets.all(Constants.defaultPadding),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2,
                              color: _showHeatMapTab?Colors.lightBlue:Colors.grey,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.data_usage_outlined, color: _showHeatMapTab?Colors.lightBlue:Colors.white70),
                                  const SizedBox(width: Constants.defaultPadding),
                                  Text('Heatmaps', style: TextStyle(color: _showHeatMapTab?Colors.lightBlue:Colors.white70)),
                                  const Spacer(),
                                  if(_showHeatMapTab)
                                    DownloadHeatMapCSV(route_choice: route_choice, selectedDateStart: _selectedDateStartHeatMap, selectedDateEnd: _selectedDateEndHeatMap),
                                ],
                              ),
                              if(_showHeatMapTab)
                                Column(
                                  children: [
                                    const SizedBox(height: Constants.defaultPadding/2),
                                    const Divider(),
                                    const SizedBox(height: Constants.defaultPadding/2),
                                    Row(
                                      children:
                                      [
                                        Expanded(
                                          flex: 3,
                                          child: GestureDetector(
                                            onTap: () => _selectDateStartHeatMap(context),
                                            child: Container(
                                              padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                              decoration: const BoxDecoration(
                                                color: Constants.primaryColor,
                                                borderRadius: BorderRadius.all(Radius.circular(15)),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Start',
                                                    style: TextStyle(fontSize: 16),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  Text(
                                                    _selectedDateStartHeatMap.toString().substring(0, 10),
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: Constants.defaultPadding),
                                        Expanded(
                                          flex: 3,
                                          child: GestureDetector(
                                            onTap: () => _selectDateEndHeatMap(context),
                                            child: Container(
                                              padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                              decoration: const BoxDecoration(
                                                color: Constants.primaryColor,
                                                borderRadius: BorderRadius.all(Radius.circular(15)),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'End',
                                                    style: TextStyle(fontSize: 16),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  Text(
                                                    _selectedDateEndHeatMap.toString().substring(0, 10),
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: Constants.defaultPadding),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Spacer(flex: 2),
                                        Expanded(
                                          flex: 5,
                                          child: GestureDetector(
                                            onTap: (){
                                              setState((){
                                                showPickUps = !showPickUps;
                                                for (var element in _heatmapRideCircles) {
                                                  _mapController.updateCircle(element.data, CircleOptions(
                                                    circleRadius: showPickUps?_radiusHeatMap:0,
                                                  ));
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                              decoration: BoxDecoration(
                                                color: showPickUps?Colors.red.withOpacity(0.3):null,
                                                border: Border.all(
                                                  width: 2,
                                                  color: showPickUps?Colors.red:Colors.white38,
                                                ),
                                                borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                              ),
                                              child: Text("Pick Ups", style: TextStyle(
                                                color: showPickUps?Colors.white:Colors.white38,
                                              ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Expanded(
                                          flex:5,
                                          child: GestureDetector(
                                            onTap: (){
                                              setState((){
                                                showDropOffs = !showDropOffs;
                                                for (var element in _heatmapDropCircles) {
                                                  _mapController.updateCircle(element.data, CircleOptions(
                                                    circleRadius: showDropOffs?_radiusHeatMap:0,
                                                  ));
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                              decoration: BoxDecoration(
                                                color: showDropOffs?Colors.lightGreen.withOpacity(0.3):null,
                                                border: Border.all(
                                                  width: 2,
                                                  color: showDropOffs?Colors.lightGreen:Colors.white38,
                                                ),
                                                borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                              ),
                                              child: Text("Drop Offs", style: TextStyle(
                                                  color: showDropOffs?Colors.white:Colors.white38
                                              ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                            ],
                          ),
                        ))
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            _showJeepHistoryTab = !_showJeepHistoryTab;
                          });
                          if(_showJeepHistoryTab){
                            _stopListenJeep();
                            List<JeepData> test = await FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(route_choice, Timestamp.fromDate(selectedDateTimeAnalysis));
                            _addSymbols(test);
                          } else {
                            for (var element in _jeeps) {
                              _mapController.removeSymbol(element.data);
                            }
                            _jeeps.clear();
                            _subscribeToCoordinates();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(Constants.defaultPadding),
                          margin:  const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2,
                              color: _showJeepHistoryTab?Colors.lightBlue:Colors.grey,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Icon(Icons.directions_bus, color: _showJeepHistoryTab?Colors.lightBlue:Colors.white70),
                                          const SizedBox(width: Constants.defaultPadding),
                                          Text('Historical Data', style: TextStyle(color: _showJeepHistoryTab?Colors.lightBlue:Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis,)
                                        ]
                                    ),
                                  ),
                                  if(_showJeepHistoryTab)
                                    DownloadHistoricalJeepCSV(route_choice: route_choice, selectedDateTime: selectedDateTimeAnalysis),
                                ],
                              ),
                              if(_showJeepHistoryTab)
                                Container(
                                  child: Column(
                                    children: [
                                      const SizedBox(height: Constants.defaultPadding/2),
                                      const Divider(),
                                      const SizedBox(height: Constants.defaultPadding/2),
                                      Row(
                                        children:
                                        [
                                          Expanded(
                                            flex: 3,
                                            child: GestureDetector(
                                              onTap: () => _selectDateTime(context),
                                              child: Container(
                                                padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                decoration: const BoxDecoration(
                                                  color: Constants.primaryColor,
                                                  borderRadius: BorderRadius.all(Radius.circular(15)),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Set Time',
                                                      style: TextStyle(fontSize: 16),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                    Text(
                                                      DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDateTimeAnalysis).toString(),
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: Constants.defaultPadding),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: GestureDetector(
                                              onTap: (){
                                                _addSeconds(30, false);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(Constants.defaultPadding/4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    width: 2,
                                                    color: Colors.lightBlue,
                                                  ),
                                                  borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                ),
                                                child: const Text("-30s", style: TextStyle(
                                                  color:Colors.lightBlue,
                                                ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Expanded(
                                            flex:5,
                                            child: GestureDetector(
                                              onTap: (){
                                                _addSeconds(5, false);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(Constants.defaultPadding/4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    width: 2,
                                                    color: Colors.lightBlue,
                                                  ),
                                                  borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                ),
                                                child: const Text("-5s", style: TextStyle(
                                                  color: Colors.lightBlue,
                                                ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Expanded(
                                            flex:5,
                                            child: GestureDetector(
                                              onTap: (){
                                                _addSeconds(5, true);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(Constants.defaultPadding/4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    width: 2,
                                                    color: Colors.lightBlue,
                                                  ),
                                                  borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                ),
                                                child: const Text("+5s", style: TextStyle(
                                                  color: Colors.lightBlue,
                                                ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Expanded(
                                            flex: 5,
                                            child: GestureDetector(
                                              onTap: (){
                                                _addSeconds(30, true);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(Constants.defaultPadding/4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    width: 2,
                                                    color: Colors.lightBlue,
                                                  ),
                                                  borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                ),
                                                child: const Text("+30s", style: TextStyle(
                                                  color: Colors.lightBlue,
                                                ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        )))
                  ],
                ),
                const SizedBox(height: Constants.defaultPadding),
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
              doubleClickZoomEnabled: false,
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
                          children: [
                            DrawerHeader(
                                child: Image.asset(
                                    'assets/logo.png',
                                    scale: 0.9
                                ),
                            ),
                            DrawerListTile(
                                Route: JeepRoutes[0],
                                icon: Image.asset(JeepSide[0]),
                                isSelected: route_choice == 0,
                                press: (){
                                  if(route_choice == 0){
                                    switchRoute(-1);
                                  } else {
                                    setState(() {
                                      _isLoaded = false;
                                    });
                                    switchRoute(0);
                                  }
                                }),
                            DrawerListTile(
                                Route: JeepRoutes[1],
                                icon: Image.asset(JeepSide[1]),
                                isSelected: route_choice == 1,
                                press: (){
                                  if(route_choice == 1){
                                    switchRoute(-1);
                                  } else {
                                    setState(() {
                                      _isLoaded = false;
                                    });
                                    switchRoute(1);
                                  }
                                }),
                            DrawerListTile(
                                Route: JeepRoutes[2],
                                icon: Image.asset(JeepSide[2]),
                                isSelected: route_choice == 2,
                                press: (){
                                  if(route_choice == 2){
                                    switchRoute(-1);
                                  } else {
                                    setState(() {
                                      _isLoaded = false;
                                    });
                                    switchRoute(2);
                                  }
                                }),
                            DrawerListTile(
                                Route: JeepRoutes[3],
                                icon: Image.asset(JeepSide[3]),
                                isSelected: route_choice == 3,
                                press: (){
                                  if(route_choice == 3){
                                    switchRoute(-1);
                                  } else {
                                    setState(() {
                                      _isLoaded = false;
                                    });
                                    switchRoute(3);
                                  }
                                }),
                            DrawerListTile(
                                Route: JeepRoutes[4],
                                icon: Image.asset(JeepSide[4]),
                                isSelected: route_choice == 4,
                                press: (){
                                  if(route_choice == 4){
                                    switchRoute(-1);
                                  } else {
                                    setState(() {
                                      _isLoaded = false;
                                    });
                                    switchRoute(4);
                                  }
                                }),
                            const SizedBox(height: Constants.defaultPadding),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                              child: const Divider()),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(child: GestureDetector(
                                    onTap: (){
                                      setState(() {
                                        _showHeatMapTab = !_showHeatMapTab;
                                      });
                                      if(_showHeatMapTab){
                                        _subscribeHeatMap();
                                      } else {
                                        for (var heatmap in _heatmapRideCircles) {
                                          _mapController.removeCircle(heatmap.data);
                                        }
                                        _heatmapRideCircles.clear();

                                        for (var heatmap in _heatmapDropCircles) {
                                          _mapController.removeCircle(heatmap.data);
                                        }
                                        _heatmapDropCircles.clear();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(Constants.defaultPadding),
                                      margin: const EdgeInsets.all(Constants.defaultPadding),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 2,
                                          color: _showHeatMapTab?Colors.lightBlue:Colors.grey,
                                        ),
                                        borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Icon(Icons.data_usage_outlined, color: _showHeatMapTab?Colors.lightBlue:Colors.white70),
                                              const SizedBox(width: Constants.defaultPadding),
                                              Expanded(child: Text('Heatmaps', style: TextStyle(color: _showHeatMapTab?Colors.lightBlue:Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                              const Spacer(),

                                              if(_showHeatMapTab)
                                                Row(
                                                  children: [
                                                    GestureDetector(
                                                        onTap: (){
                                                          setState(
                                                                  (){
                                                                _selectSettingsHeatMap = !_selectSettingsHeatMap;
                                                              }
                                                          );
                                                        },
                                                        child: Icon(Icons.settings, size: 20, color: _selectSettingsHeatMap?Colors.lightBlue:Colors.white38)),
                                                    SizedBox(width: Constants.defaultPadding),
                                                    DownloadHeatMapCSV(route_choice: route_choice, selectedDateStart: _selectedDateStartHeatMap, selectedDateEnd: _selectedDateEndHeatMap),

                                                  ],
                                                ),
                                            ],
                                          ),
                                          if(_showHeatMapTab)
                                            Column(
                                              children: [
                                                const SizedBox(height: Constants.defaultPadding/2),
                                                const Divider(),

                                                if(_selectSettingsHeatMap)
                                                Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                              padding: const EdgeInsets.only(top: Constants.defaultPadding/2),
                                                              child: const Text("Heatmap Radius", maxLines: 1, overflow: TextOverflow.ellipsis)
                                                          ),
                                                        ),
                                                        
                                                        Row(
                                                          children: [
                                                            Text("$_radiusHeatMap"),
                                                            const SizedBox(width: Constants.defaultPadding),
                                                            Column(
                                                              children: [
                                                                GestureDetector(
                                                                  onTap: (){
                                                                    setState(
                                                                      (){
                                                                        _radiusHeatMap += 2;
                                                                      }
                                                                    );

                                                                    if(showPickUps){
                                                                      for (var element in _heatmapRideCircles) {
                                                                        _mapController.updateCircle(element.data, CircleOptions(circleRadius: _radiusHeatMap));
                                                                      }
                                                                    }

                                                                    if(showDropOffs){
                                                                      for (var element in _heatmapDropCircles) {
                                                                        _mapController.updateCircle(element.data, CircleOptions(circleRadius: _radiusHeatMap));
                                                                      }
                                                                    }

                                                                  },
                                                                  child: const Icon(Icons.arrow_drop_up, color: Colors.lightBlue)),
                                                                GestureDetector(
                                                                  onTap: (){
                                                                    if(_radiusHeatMap-2 > 0)
                                                                    {
                                                                      setState(
                                                                              (){
                                                                            _radiusHeatMap -= 2;
                                                                          }
                                                                      );
                                                                      if(showPickUps){
                                                                        for (var element in _heatmapRideCircles) {
                                                                          _mapController.updateCircle(element.data, CircleOptions(circleRadius: _radiusHeatMap));
                                                                        }
                                                                      }

                                                                      if(showDropOffs){
                                                                        for (var element in _heatmapDropCircles) {
                                                                          _mapController.updateCircle(element.data, CircleOptions(circleRadius: _radiusHeatMap));
                                                                        }
                                                                      }
                                                                    }
                                                                  },
                                                                  child: const Icon(Icons.arrow_drop_down, color: Colors.lightBlue))
                                                              ]
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                              padding: const EdgeInsets.symmetric(vertical: Constants.defaultPadding/2),
                                                              child: const Text("Heatmap Intensity", maxLines: 1, overflow: TextOverflow.ellipsis)
                                                          ),
                                                        ),

                                                        Row(
                                                          children: [
                                                            Text("${_opacityHeatmap.toStringAsFixed(2)}"),
                                                            const SizedBox(width: Constants.defaultPadding),
                                                            Column(
                                                                children: [
                                                                  GestureDetector(
                                                                      onTap: (){
                                                                        if(_opacityHeatmap+0.02 < 1)
                                                                          {
                                                                            setState(
                                                                                    (){
                                                                                  _opacityHeatmap += 0.02;
                                                                                }
                                                                            );

                                                                            if(showPickUps){
                                                                              for (var element in _heatmapRideCircles) {
                                                                                _mapController.updateCircle(element.data, CircleOptions(circleOpacity: _opacityHeatmap));
                                                                              }
                                                                            }

                                                                            if(showDropOffs){
                                                                              for (var element in _heatmapDropCircles) {
                                                                                _mapController.updateCircle(element.data, CircleOptions(circleOpacity: _opacityHeatmap));
                                                                              }
                                                                            }
                                                                          }
                                                                      },
                                                                      child: const Icon(Icons.arrow_drop_up, color: Colors.lightBlue)),
                                                                  GestureDetector(
                                                                      onTap: (){
                                                                        if(_opacityHeatmap-0.02 > 0)
                                                                        {
                                                                          setState(
                                                                            (){
                                                                                _opacityHeatmap -= 0.02;
                                                                              }
                                                                          );
                                                                          if(showPickUps){
                                                                            for (var element in _heatmapRideCircles) {
                                                                              _mapController.updateCircle(element.data, CircleOptions(circleOpacity: _opacityHeatmap));
                                                                            }
                                                                          }

                                                                          if(showDropOffs){
                                                                            for (var element in _heatmapDropCircles) {
                                                                              _mapController.updateCircle(element.data, CircleOptions(circleOpacity: _opacityHeatmap));
                                                                            }
                                                                          }
                                                                        }
                                                                      },
                                                                      child: const Icon(Icons.arrow_drop_down, color: Colors.lightBlue))
                                                                ]
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const Divider(),
                                                  ],
                                                ),
                                                const SizedBox(height: Constants.defaultPadding/2),
                                                Row(
                                                  children:
                                                  [
                                                    Expanded(
                                                      flex: 3,
                                                      child: GestureDetector(
                                                        onTap: () => _selectDateStartHeatMap(context),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                          decoration: const BoxDecoration(
                                                            color: Constants.primaryColor,
                                                            borderRadius: BorderRadius.all(Radius.circular(15)),
                                                          ),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Text(
                                                                'Start',
                                                                style: TextStyle(fontSize: 16),
                                                                overflow: TextOverflow.ellipsis,
                                                                maxLines: 1,
                                                              ),
                                                              Text(
                                                                _selectedDateStartHeatMap.toString().substring(0, 10),
                                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                                overflow: TextOverflow.ellipsis,
                                                                maxLines: 1,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: Constants.defaultPadding),
                                                    Expanded(
                                                      flex: 3,
                                                      child: GestureDetector(
                                                        onTap: () => _selectDateEndHeatMap(context),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                          decoration: const BoxDecoration(
                                                            color: Constants.primaryColor,
                                                            borderRadius: BorderRadius.all(Radius.circular(15)),
                                                          ),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Text(
                                                                'End',
                                                                style: TextStyle(fontSize: 16),
                                                                overflow: TextOverflow.ellipsis,
                                                                maxLines: 1,
                                                              ),
                                                              Text(
                                                                _selectedDateEndHeatMap.toString().substring(0, 10),
                                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                                overflow: TextOverflow.ellipsis,
                                                                maxLines: 1,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: Constants.defaultPadding),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    const Spacer(flex: 2),
                                                    Expanded(
                                                      flex: 5,
                                                      child: GestureDetector(
                                                        onTap: (){
                                                          setState((){
                                                            showPickUps = !showPickUps;
                                                            for (var element in _heatmapRideCircles) {
                                                              _mapController.updateCircle(element.data, CircleOptions(
                                                                circleRadius: showPickUps?_radiusHeatMap:0,
                                                              ));
                                                            }
                                                          });
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                          decoration: BoxDecoration(
                                                            color: showPickUps?Colors.red.withOpacity(0.3):null,
                                                            border: Border.all(
                                                              width: 2,
                                                              color: showPickUps?Colors.red:Colors.white38,
                                                            ),
                                                            borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                          ),
                                                          child: Text("Pick Ups", style: TextStyle(
                                                            color: showPickUps?Colors.white:Colors.white38,
                                                          ),
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 1,
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Expanded(
                                                      flex:5,
                                                      child: GestureDetector(
                                                        onTap: (){
                                                          setState((){
                                                            showDropOffs = !showDropOffs;
                                                            for (var element in _heatmapDropCircles) {
                                                              _mapController.updateCircle(element.data, CircleOptions(
                                                                circleRadius: showDropOffs?_radiusHeatMap:0,
                                                              ));
                                                            }
                                                          });
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                          decoration: BoxDecoration(
                                                            color: showDropOffs?Colors.lightGreen.withOpacity(0.3):null,
                                                            border: Border.all(
                                                              width: 2,
                                                              color: showDropOffs?Colors.lightGreen:Colors.white38,
                                                            ),
                                                            borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                          ),
                                                          child: Text("Drop Offs", style: TextStyle(
                                                              color: showDropOffs?Colors.white:Colors.white38
                                                          ),
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 1,
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                        ],
                                      ),
                                    ))
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(child: GestureDetector(
                                    onTap: () async {
                                      setState(() {
                                        _showJeepHistoryTab = !_showJeepHistoryTab;
                                      });
                                      if(_showJeepHistoryTab){
                                        _stopListenJeep();
                                        List<JeepData> test = await FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(route_choice, Timestamp.fromDate(selectedDateTimeAnalysis));
                                        _addSymbols(test);
                                      } else {
                                        for (var element in _jeeps) {
                                          _mapController.removeSymbol(element.data);
                                        }
                                        _jeeps.clear();
                                        _subscribeToCoordinates();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(Constants.defaultPadding),
                                      margin:  const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 2,
                                          color: _showJeepHistoryTab?Colors.lightBlue:Colors.grey,
                                        ),
                                        borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      Icon(Icons.directions_bus, color: _showJeepHistoryTab?Colors.lightBlue:Colors.white70),
                                                      const SizedBox(width: Constants.defaultPadding),
                                                      Text('Historical Data', style: TextStyle(color: _showJeepHistoryTab?Colors.lightBlue:Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis,)
                                                  ]
                                                ),
                                              ),

                                              if(_showJeepHistoryTab)
                                                DownloadHistoricalJeepCSV(route_choice: route_choice, selectedDateTime: selectedDateTimeAnalysis),
                                            ],
                                          ),
                                          if(_showJeepHistoryTab)
                                            Container(
                                              child: Column(
                                                children: [
                                                  const SizedBox(height: Constants.defaultPadding/2),
                                                  const Divider(),
                                                  const SizedBox(height: Constants.defaultPadding/2),
                                                  Row(
                                                    children:
                                                    [
                                                      Expanded(
                                                        flex: 3,
                                                        child: GestureDetector(
                                                          onTap: () => _selectDateTime(context),
                                                          child: Container(
                                                            padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                            decoration: const BoxDecoration(
                                                              color: Constants.primaryColor,
                                                              borderRadius: BorderRadius.all(Radius.circular(15)),
                                                            ),
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                const Text(
                                                                  'Set Time',
                                                                  style: TextStyle(fontSize: 16),
                                                                  overflow: TextOverflow.ellipsis,
                                                                  maxLines: 1,
                                                                ),
                                                                Text(
                                                                  DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDateTimeAnalysis).toString(),
                                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                                  overflow: TextOverflow.ellipsis,
                                                                  maxLines: 1,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: Constants.defaultPadding),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Expanded(
                                                        flex: 5,
                                                        child: GestureDetector(
                                                          onTap: (){
                                                            _addSeconds(30, false);
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(
                                                                width: 2,
                                                                color: Colors.lightBlue,
                                                              ),
                                                              borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                            ),
                                                            child: const Text("-30s", style: TextStyle(
                                                              color:Colors.lightBlue,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 1,
                                                            textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Expanded(
                                                        flex:5,
                                                        child: GestureDetector(
                                                          onTap: (){
                                                            _addSeconds(5, false);
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(
                                                                width: 2,
                                                                color: Colors.lightBlue,
                                                              ),
                                                              borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                            ),
                                                            child: const Text("-5s", style: TextStyle(
                                                              color: Colors.lightBlue,
                                                            ),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Expanded(
                                                        flex:5,
                                                        child: GestureDetector(
                                                          onTap: (){
                                                            _addSeconds(5, true);
                                                          },
                                                          child: Container(
                                                              padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                              decoration: BoxDecoration(
                                                                border: Border.all(
                                                                  width: 2,
                                                                  color: Colors.lightBlue,
                                                                ),
                                                                borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                              ),
                                                              child: const Text("+5s", style: TextStyle(
                                                                color: Colors.lightBlue,
                                                              ),
                                                                overflow: TextOverflow.ellipsis,
                                                                maxLines: 1,
                                                                textAlign: TextAlign.center,
                                                              ),
                                                          ),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Expanded(
                                                        flex: 5,
                                                        child: GestureDetector(
                                                          onTap: (){
                                                            _addSeconds(30, true);
                                                          },
                                                          child: Container(
                                                              padding: const EdgeInsets.all(Constants.defaultPadding/2),
                                                              decoration: BoxDecoration(
                                                                border: Border.all(
                                                                  width: 2,
                                                                  color: Colors.lightBlue,
                                                                ),
                                                                borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
                                                              ),
                                                              child: const Text("+30s", style: TextStyle(
                                                                color: Colors.lightBlue,
                                                              ),
                                                                overflow: TextOverflow.ellipsis,
                                                                maxLines: 1,
                                                                textAlign: TextAlign.center,
                                                              ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    )))
                              ],
                            ),
                            const SizedBox(height: Constants.defaultPadding),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: SizeConfig.screenHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 6,
                                child: !Responsive.isMobile(context)
                                ?MouseRegion(
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
                                    child: const Header())
                                :Stack(
                                  children: [
                                    Column(
                                      children: [
                                      Expanded(child: MapboxMap(
                                            accessToken: Keys.MapBoxKey,
                                            styleString: Keys.MapBoxNight,
                                            zoomGesturesEnabled: !(context.read<MenuControllers>().scaffoldKey.currentState?.isDrawerOpen ?? true),
                                            scrollGesturesEnabled: !(context.read<MenuControllers>().scaffoldKey.currentState?.isDrawerOpen ?? true),
                                            doubleClickZoomEnabled: false,
                                            dragEnabled: !(context.read<MenuControllers>().scaffoldKey.currentState?.isDrawerOpen ?? true),
                                            minMaxZoomPreference: const MinMaxZoomPreference(12, 19),
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
                                          )),
                                      Container(
                                        height: 220,
                                        decoration: const BoxDecoration(
                                          color: Constants.secondaryColor,
                                        ),
                                        child: route_choice == -1? Container(
                                            child: Stack(
                                              children: [
                                                Column(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets.all(Constants.defaultPadding),
                                                            child: const Column(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      "Select a route",
                                                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                    Text(
                                                                      "press the menu icon at the top left\npart of the screen!",
                                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ]
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Positioned(
                                                  bottom: -50,
                                                  right: -40,
                                                  child: Transform.rotate(
                                                    angle: -15 * 3.1415926535 / 180, // Rotate 45 degrees counter-clockwise (NW direction)
                                                    child: const Icon(Icons.touch_app_rounded, color: Colors.white12, size: 270)
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ):(_showJeepHistoryTab
                                        ?FutureBuilder(
                                            future: FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(route_choice, Timestamp.fromDate(selectedDateTimeAnalysis)),
                                            builder: (context, snapshot){
                                              if(!snapshot.hasData || snapshot.hasError){
                                                return const RouteInfoShimmerV2();
                                              }
                                              var data = snapshot.data!;
                                              double operating = data.where((jeep) => jeep.is_active).length.toDouble();
                                              double not_operating = data.where((jeep) => !jeep.is_active).length.toDouble();
                                              int passenger_count = data.fold(0, (int previousValue, JeepData jeepney) {
                                                if(jeepney.is_active){
                                                  return previousValue + jeepney.passenger_count;
                                                }
                                                else {
                                                  return previousValue;
                                                }
                                              });
                                              int capacity_count = data.fold(0, (int previousValue, JeepData jeepney) {
                                                if(jeepney.is_active){
                                                  return previousValue + jeepney.passenger_count + jeepney.slots_remaining;
                                                } else {
                                                  return previousValue;
                                                }
                                              });
                                              String passengers = "passengers";
                                              if(passenger_count == 1){
                                                passengers = "passenger";
                                              }
                                              return Container(
                                                padding: EdgeInsets.all(Constants.defaultPadding),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: SingleChildScrollView(
                                                        physics: const AlwaysScrollableScrollPhysics(),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      RichText(
                                                                        textAlign: TextAlign.left,
                                                                        text: TextSpan(
                                                                          children: [
                                                                            TextSpan(
                                                                              text: JeepRoutes[route_choice].name,
                                                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
                                                                            ),
                                                                            TextSpan(
                                                                              text: "\n$passenger_count total $passengers",
                                                                              style: Theme.of(context).textTheme.headline4?.copyWith(
                                                                                color: Colors.white54,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontSize: 14,
                                                                              ),
                                                                            ),
                                                                            TextSpan(
                                                                              text: "\n$capacity_count total capacity",
                                                                              style: Theme.of(context).textTheme.headline4?.copyWith(
                                                                                color: Colors.white54,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontSize: 14,
                                                                              ),
                                                                            ),
                                                                            TextSpan(
                                                                              text: "\n${((passenger_count/capacity_count) * 100).toStringAsFixed(0)}% capacity utilization",
                                                                              style: Theme.of(context).textTheme.headline4?.copyWith(
                                                                                color: Colors.white54,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontSize: 14,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      RichText(
                                                                        textAlign: TextAlign.right,
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
                                                                              text: "/${operating + not_operating} jeepneys",
                                                                              style: Theme.of(context).textTheme.headline4?.copyWith(
                                                                                  color: Colors.white,
                                                                                  fontWeight: FontWeight.w800,
                                                                                  fontSize: 14,
                                                                                  height: 0.5
                                                                              ),
                                                                            ),
                                                                            TextSpan(
                                                                              text: '\noperating',
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
                                                            const SizedBox(height: Constants.defaultPadding),
                                                            const Divider(),
                                                            isHoverJeep?JeepInfoCardDetailed(route_choice: route_choice, data: pressedJeep.jeep, isHeatMap: false):SelectJeepInfoCard(isHeatMap: false),
                                                            _showHeatMapTab?(_tappedCircle?JeepInfoCardDetailed(route_choice: route_choice, data: pressedCircle.heatmap, isHeatMap: true):SelectJeepInfoCard(isHeatMap: true)):SizedBox()
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
                                            stream: FireStoreDataBase().fetchJeepData(route_choice),
                                            builder: (context, snapshot) {
                                              if(!snapshot.hasData || snapshot.hasError){
                                                return const RouteInfoShimmerV2();
                                              }
                                              var data = snapshot.data!;
                                              double operating = data.where((jeep) => jeep.is_active).length.toDouble();
                                              double not_operating = data.where((jeep) => !jeep.is_active).length.toDouble();
                                              return Container(
                                                padding: const EdgeInsets.all(Constants.defaultPadding),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: SingleChildScrollView(
                                                        physics: const AlwaysScrollableScrollPhysics(),
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
                                                                          Row(
                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Text(
                                                                                JeepRoutes[route_choice].name,
                                                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                                                                maxLines: 1,
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      RichText(
                                                                        textAlign: TextAlign.right,
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
                                                                              text: "/${operating + not_operating} jeepneys",
                                                                              style: Theme.of(context).textTheme.headline4?.copyWith(
                                                                                  color: Colors.white,
                                                                                  fontWeight: FontWeight.w800,
                                                                                  fontSize: 14,
                                                                                  height: 0.5
                                                                              ),
                                                                            ),
                                                                            TextSpan(
                                                                              text: '\noperating',
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
                                                            const SizedBox(height: Constants.defaultPadding),
                                                            const Divider(),
                                                            isHoverJeep?JeepInfoCard(route_choice: route_choice, data: pressedJeep.jeep):const SelectJeepInfoCard(isHeatMap: false),
                                                            _showHeatMapTab?(_tappedCircle?JeepInfoCardDetailed(route_choice: route_choice, data: pressedCircle.heatmap, isHeatMap: true):const SelectJeepInfoCard(isHeatMap: true)):SizedBox()
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                        )
                                        )
                                      )
                                    ]),
                                    const Header(),
                                    if(!_isLoaded && !_showJeepHistoryTab)
                                      const Positioned(
                                          top: Constants.defaultPadding,
                                          right: Constants.defaultPadding,
                                          child: CircularProgressIndicator()
                                      ),
                                  ]
                                ),
                            ),
                            if(!Responsive.isMobile(context))
                              const SizedBox(width: Constants.defaultPadding),
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
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: Container(
                                        margin: const EdgeInsets.all(Constants.defaultPadding),
                                        decoration: const BoxDecoration(
                                          color: Constants.secondaryColor,
                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                        ),
                                        child: route_choice==-1?Container(
                                          padding: const EdgeInsets.all(Constants.defaultPadding),
                                          decoration: const BoxDecoration(
                                            color: Constants.secondaryColor,
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          child: const Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Select a route",
                                                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: Constants.defaultPadding),
                                              SizedBox(
                                                height:200,
                                                child: Center(child: CircleAvatar(
                                                radius: 90,
                                                  backgroundColor: Colors.white38,
                                                  child: CircleAvatar(
                                                        radius: 70,
                                                      backgroundColor: Constants.secondaryColor,
                                                      child: Icon(Icons.touch_app_rounded, color: Colors.white38, size: 50)
                                                  ),
                                                )),
                                              ),
                                              SizedBox(height: Constants.defaultPadding),
                                            ],
                                          ),
                                        ):(_showJeepHistoryTab
                                          ?FutureBuilder(
                                          future: FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(route_choice, Timestamp.fromDate(selectedDateTimeAnalysis)),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData || snapshot.hasError) {
                                              return const ShimmerDesktopRouteInfo();
                                            }
                                            var data = snapshot.data!;
                                            double operating = data.where((jeep) => jeep.is_active).length.toDouble();
                                            double not_operating = data.where((jeep) => !jeep.is_active).length.toDouble();
                                            int passenger_count = data.fold(0, (int previousValue, JeepData jeepney) {
                                              if(jeepney.is_active){
                                                return previousValue + jeepney.passenger_count;
                                              }
                                              else {
                                                return previousValue;
                                              }
                                            });
                                            int capacity_count = data.fold(0, (int previousValue, JeepData jeepney) {
                                              if(jeepney.is_active){
                                                return previousValue + jeepney.passenger_count + jeepney.slots_remaining;
                                              } else {
                                                return previousValue;
                                              }
                                            });
                                            return Container(
                                              decoration: const BoxDecoration(
                                                color: Constants.secondaryColor,
                                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: SingleChildScrollView(
                                                      physics: isMouseHoveringRouteInfo?const AlwaysScrollableScrollPhysics():const NeverScrollableScrollPhysics(),
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
                                                            ],
                                                          ),
                                                          const SizedBox(height: Constants.defaultPadding),
                                                          route_info_chart(route_choice: route_choice, operating: operating, not_operating: not_operating),
                                                          SizedBox(height: Constants.defaultPadding, child: Text(
                                                            "${passenger_count} total passengers",
                                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            textAlign: TextAlign.right,
                                                          )),
                                                          SizedBox(height: Constants.defaultPadding, child: Text(
                                                            "${capacity_count} total capacity",
                                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            textAlign: TextAlign.right,
                                                          )),
                                                          SizedBox(height: Constants.defaultPadding, child: Text(
                                                            "${((passenger_count/capacity_count) * 100).toStringAsFixed(0)}% capacity utilization",
                                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            textAlign: TextAlign.right,
                                                          )),
                                                          const Divider(),
                                                          isHoverJeep?JeepInfoCardDetailed(route_choice: route_choice, data: pressedJeep.jeep, isHeatMap: false):SelectJeepInfoCard(isHeatMap: false),
                                                          _showHeatMapTab?(_tappedCircle?JeepInfoCardDetailed(route_choice: route_choice, data: pressedCircle.heatmap, isHeatMap: true):SelectJeepInfoCard(isHeatMap: true)):SizedBox()
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
                                            stream: FireStoreDataBase().fetchJeepData(route_choice),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData || snapshot.hasError) {
                                                return const ShimmerDesktopRouteInfo();
                                              }
                                              var data = snapshot.data!;
                                              double operating = data.where((jeep) => jeep.is_active).length.toDouble();
                                              double not_operating = data.where((jeep) => !jeep.is_active).length.toDouble();
                                              return Container(
                                                decoration: const BoxDecoration(
                                                  color: Constants.secondaryColor,
                                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: SingleChildScrollView(
                                                        physics: isMouseHoveringRouteInfo?const AlwaysScrollableScrollPhysics():const NeverScrollableScrollPhysics(),
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
                                                              ],
                                                            ),
                                                            const SizedBox(height: Constants.defaultPadding),
                                                            route_info_chart(route_choice: route_choice, operating: operating, not_operating: not_operating),
                                                            const SizedBox(height: Constants.defaultPadding),
                                                            const Divider(),
                                                            isHoverJeep?JeepInfoCard(route_choice: route_choice, data: pressedJeep.jeep):SelectJeepInfoCard(isHeatMap: false),
                                                            _showHeatMapTab?(_tappedCircle?JeepInfoCardDetailed(route_choice: route_choice, data: pressedCircle.heatmap, isHeatMap: true):SelectJeepInfoCard(isHeatMap: true)):SizedBox()
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                        )
                                        )
                                      )
                                    ),
                                  ),
                              )
                          ],
                        )
                      ),
                      if(!_isLoaded && !Responsive.isMobile(context) && !_showJeepHistoryTab)
                        const Positioned(
                            top: Constants.defaultPadding,
                            left: Constants.defaultPadding,
                            child: CircularProgressIndicator()
                        ),
                    ],
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




















