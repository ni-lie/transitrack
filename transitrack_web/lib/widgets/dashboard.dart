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

  int route_choice = 0;
  List<JeepEntity> _jeeps = [];
  List<Line> _lines = [];
  List<HeatMapEntity> _heatmapRideCircles = [];
  List<HeatMapEntity> _heatmapDropCircles = [];
  bool isMouseHoveringRouteInfo = false;
  bool isMouseHoveringDrawer = false;

  Symbol? heatMapSymbol;

  bool isHoverJeep = false;
  int hoveredJeep = -1;
  bool _isLoaded = false;
  bool showPickUps = false;
  bool showDropOffs = false;

  bool _showHeatMapTab = false;
  bool _showJeepHistoryTab = false;
  bool _isListeningJeep = false;
  
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
      _mapController.addSymbol(jeepEntity).then((jeepSymbol) {
        _jeeps.add(JeepEntity(jeep: Jeepney, data: jeepSymbol));
      });
    }
  }

  void _addCirclesDrop(List<JeepData> Jeepneys) {
    for (var element in Jeepneys) {
      _mapController.addCircle(CircleOptions(
          geometry: LatLng(element.location.latitude, element.location.longitude),
          circleRadius: showDropOffs?10:0,
          circleColor: '#00FF00',
          circleOpacity: 0.5
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
          circleRadius: showPickUps?10:0,
          circleColor: '#FF0000',
          circleOpacity: 0.5
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
      double angleRadians = atan2(Jeepney.acceleration[1], Jeepney.acceleration[0]);
      double angleDegrees = angleRadians * (180 / pi);
      if(_jeeps.any((element) => element.jeep.device_id == Jeepney.device_id)){
        var symbolToUpdate = _jeeps.firstWhere((symbol) => symbol.jeep.device_id == Jeepney.device_id);
        if(isHoverJeep && pressedJeep.jeep.device_id == Jeepney.device_id){
          pressedJeep.jeep.location = Jeepney.location;
          if(!pressedJeep.jeep.is_active){
            isHoverJeep = false;
          }
        }
        _mapController.updateSymbol(symbolToUpdate.data, SymbolOptions(
            geometry: LatLng(Jeepney.location.latitude, Jeepney.location.longitude),
            iconRotate: 90 - angleDegrees,
            iconOpacity: Jeepney.is_active?1:0
        ));

      } else {
        final jeepEntity = SymbolOptions(
          geometry: LatLng(Jeepney.location.latitude, Jeepney.location.longitude),
          iconSize: 0.1,
          iconImage: JeepRoutes[route_choice].image,
          textField: Jeepney.device_id,
          textOpacity: 0,
          iconRotate: 90 - angleDegrees,
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

    _mapController.addLine(Routes.RouteLines[route_choice]).then((line) {
      _lines.add(line);
    });

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
  LatLng? _clickedLatLng;

  void _onCircleTapped(Circle circle){
    HeatMapEntity heatmap;
    if(circle.options.circleColor == '#FF0000'){
      heatmap = _heatmapRideCircles.firstWhere((element) => element.data == circle);
    } else {
      heatmap = _heatmapDropCircles.firstWhere((element) => element.data == circle);
    }

    setState((){
      _isShowingCardRide = !_isShowingCardRide;
      _clickedLatLng = heatmap.data.options.geometry as LatLng;
    });

    if(_isShowingCardRide){
      _mapController.addSymbol(SymbolOptions(
        geometry: _clickedLatLng,
        textField: (circle.options.circleColor == '#FF0000')?'${heatmap.heatmap.passenger_count} Passengers Picked Up':'${heatmap.heatmap.passenger_count} Passengers Dropped off',
        iconImage: 'assets/heatmapBanner.png',
        iconSize: 0.7,
        textHaloWidth: circle.options.circleColor == '#FF0000'?1:-1,
        textOffset: const Offset(0, -3),
        iconOffset: const Offset(0, -69),
        textColor: '#FFFFFF',
        textMaxWidth: 10,
      )).then((value) => heatMapSymbol = value);
    } else {
      _mapController.removeSymbol(heatMapSymbol!);
      heatMapSymbol = null;
    }
  }

  late JeepEntity pressedJeep;

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
                iconOpacity: 1
            ));
          } else {
            _mapController.updateSymbol(element.data, const SymbolOptions(
                iconSize: 0.1,
                iconOpacity: 0.4
            ));
          }
        }
      } else {
        for (var element in _jeeps) {
          if (element.jeep.device_id == pressedJeep.jeep.device_id){
            _mapController.updateSymbol(element.data, const SymbolOptions(
                iconSize: 0.1,
                iconOpacity: 1
            ));
          } else {
            _mapController.updateSymbol(element.data, const SymbolOptions(
                iconOpacity: 1,
                iconSize: 0.1
            ));
          }
        }
      }
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    _mapController.onCircleTapped.add(_onCircleTapped);
    _mapController.onSymbolTapped.add(_onSymbolTapped);
    Future.delayed(const Duration(seconds: 3), () async {
      _updateRoutes();
      await _subscribeToCoordinates();
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

  void _stopListenHeatMap(){
    if(heatMapSymbol != null){
      _isShowingCardRide = false;
      _mapController.removeSymbol(heatMapSymbol!);
      heatMapSymbol = null;
    }

    for (var element in _heatmapDropCircles) {_mapController.removeCircle(element.data);}
    for (var element in _heatmapRideCircles) {_mapController.removeCircle(element.data);}
  }

  Future<void> _subscribeHeatMap() async {
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
      _stopListenHeatMap();
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
      _stopListenHeatMap();
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
                    press: route_choice != 0? (){
                      setState(() {
                        _isLoaded = false;
                      });
                      _setRoute(0);
                      _stopListenHeatMap();
                      _stopListenJeep();
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
                      _stopListenHeatMap();
                      _stopListenJeep();
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
                      _stopListenHeatMap();
                      _stopListenJeep();
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
                      _stopListenHeatMap();
                      _stopListenJeep();
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
                      _stopListenHeatMap();
                      _stopListenJeep();
                      _subscribeToCoordinates();
                      _updateRoutes();
                    } : null),
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
                            _stopListenHeatMap();
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
                                                if(heatMapSymbol != null && heatMapSymbol?.options.textHaloWidth == 1.0){
                                                  if(showPickUps){
                                                    _mapController.updateSymbol(heatMapSymbol!, const SymbolOptions(
                                                      iconOpacity: 1,
                                                      textOpacity: 1,
                                                    ));
                                                  } else {
                                                    _mapController.updateSymbol(heatMapSymbol!, const SymbolOptions(
                                                        iconOpacity: 0,
                                                        textOpacity: 0
                                                    ));
                                                  }
                                                }
                                                for (var element in _heatmapRideCircles) {
                                                  _mapController.updateCircle(element.data, CircleOptions(
                                                    circleRadius: showPickUps?10:0,
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
                                                if(heatMapSymbol != null && heatMapSymbol?.options.textHaloWidth == -1.0){
                                                  if(showDropOffs){
                                                    _mapController.updateSymbol(heatMapSymbol!, const SymbolOptions(
                                                      iconOpacity: 1,
                                                      textOpacity: 1,
                                                    ));
                                                  } else {
                                                    _mapController.updateSymbol(heatMapSymbol!, const SymbolOptions(
                                                        iconOpacity: 0,
                                                        textOpacity: 0
                                                    ));
                                                  }
                                                }
                                                for (var element in _heatmapDropCircles) {
                                                  _mapController.updateCircle(element.data, CircleOptions(
                                                    circleRadius: showDropOffs?10:0,
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
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  Icon(Icons.directions_bus, color: _showJeepHistoryTab?Colors.lightBlue:Colors.white70),
                                  const SizedBox(width: Constants.defaultPadding),
                                  Expanded(child: Text('Jeep Analysis', style: TextStyle(color: _showJeepHistoryTab?Colors.lightBlue:Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis,)),
                                  const SizedBox(width: Constants.defaultPadding),
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
                                press: route_choice != 0? (){
                                  setState(() {
                                    _isLoaded = false;
                                  });
                                  _setRoute(0);
                                  _stopListenHeatMap();
                                  _stopListenJeep();
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
                                  _stopListenHeatMap();
                                  _stopListenJeep();
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
                                  _stopListenHeatMap();
                                  _stopListenJeep();
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
                                  _stopListenHeatMap();
                                  _stopListenJeep();
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
                                  _stopListenHeatMap();
                                  _stopListenJeep();
                                  _subscribeToCoordinates();
                                  _updateRoutes();
                                } : null),
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
                                        _stopListenHeatMap();
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
                                                            if(heatMapSymbol != null && heatMapSymbol?.options.textHaloWidth == 1.0){
                                                              if(showPickUps){
                                                                _mapController.updateSymbol(heatMapSymbol!, const SymbolOptions(
                                                                  iconOpacity: 1,
                                                                  textOpacity: 1,
                                                                ));
                                                              } else {
                                                                _mapController.updateSymbol(heatMapSymbol!, const SymbolOptions(
                                                                    iconOpacity: 0,
                                                                    textOpacity: 0
                                                                ));
                                                              }
                                                            }
                                                            for (var element in _heatmapRideCircles) {
                                                              _mapController.updateCircle(element.data, CircleOptions(
                                                                circleRadius: showPickUps?10:0,
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
                                                            if(heatMapSymbol != null && heatMapSymbol?.options.textHaloWidth == -1.0){
                                                              if(showDropOffs){
                                                                _mapController.updateSymbol(heatMapSymbol!, const SymbolOptions(
                                                                  iconOpacity: 1,
                                                                  textOpacity: 1,
                                                                ));
                                                              } else {
                                                                _mapController.updateSymbol(heatMapSymbol!, const SymbolOptions(
                                                                    iconOpacity: 0,
                                                                    textOpacity: 0
                                                                ));
                                                              }
                                                            }
                                                            for (var element in _heatmapDropCircles) {
                                                              _mapController.updateCircle(element.data, CircleOptions(
                                                                circleRadius: showDropOffs?10:0,
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
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Icon(Icons.directions_bus, color: _showJeepHistoryTab?Colors.lightBlue:Colors.white70),
                                              const SizedBox(width: Constants.defaultPadding),
                                              Expanded(child: Text('Jeep Analysis', style: TextStyle(color: _showJeepHistoryTab?Colors.lightBlue:Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis,)),
                                              Spacer(),
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
                                            onMapClick: (Point<double> point, LatLng coordinates) {
                                              setState(() {
                                                _isShowingCardRide = false;
                                              });
                                            },
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
                                        padding: const EdgeInsets.all(Constants.defaultPadding),
                                        height: 220,
                                        decoration: const BoxDecoration(
                                          color: Constants.secondaryColor,
                                        ),
                                        child: _showJeepHistoryTab
                                        ?FutureBuilder(
                                            future: FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(route_choice, Timestamp.fromDate(selectedDateTimeAnalysis)),
                                            builder: (context, snapshot){
                                              if(!snapshot.hasData || snapshot.hasError){
                                                return const RouteInfoShimmerV2();
                                              }
                                              var data = snapshot.data!;
                                              double operating = data.where((jeep) => jeep.is_active).length.toDouble();
                                              double not_operating = data.where((jeep) => !jeep.is_active).length.toDouble();
                                              double passenger_count = data.fold(0, (int previousValue, JeepData jeepney) => previousValue + jeepney.passenger_count).toDouble();
                                              return Row(
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
                                                                        "${passenger_count} total passengers",
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
                                                        const SizedBox(height: Constants.defaultPadding),
                                                        const Divider(),
                                                        isHoverJeep?JeepInfoCard(route_choice: route_choice, data: pressedJeep.jeep):SelectJeepInfoCard()
                                                      ],
                                                    ),
                                                  ),
                                                ],
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
                                              double passenger_count = data.fold(0, (int previousValue, JeepData jeepney) => previousValue + jeepney.passenger_count).toDouble();
                                              return Row(
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
                                                                      Text(
                                                                        "${passenger_count} total passengers",
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
                                                        const SizedBox(height: Constants.defaultPadding),
                                                        const Divider(),
                                                        isHoverJeep?JeepInfoCard(route_choice: route_choice, data: pressedJeep.jeep):SelectJeepInfoCard()
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }
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
                                        child: _showJeepHistoryTab
                                          ?FutureBuilder(
                                          future: FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(route_choice, Timestamp.fromDate(selectedDateTimeAnalysis)),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData || snapshot.hasError) {
                                              return const ShimmerDesktopRouteInfo();
                                            }
                                            var data = snapshot.data!;
                                            double operating = data.where((jeep) => jeep.is_active).length.toDouble();
                                            double not_operating = data.where((jeep) => !jeep.is_active).length.toDouble();
                                            double passenger_count = data.fold(0, (int previousValue, JeepData jeepney) => previousValue + jeepney.passenger_count).toDouble();
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
                                                              Expanded(
                                                                child: Text(
                                                                  "${passenger_count} total passengers",
                                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white54),
                                                                  textAlign: TextAlign.end,
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: Constants.defaultPadding),
                                                          route_info_chart(route_choice: route_choice, operating: operating, not_operating: not_operating),
                                                          const SizedBox(height: Constants.defaultPadding),
                                                          const Divider(),
                                                          isHoverJeep?JeepInfoCard(route_choice: route_choice, data: pressedJeep.jeep):SelectJeepInfoCard()
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
                                              double passenger_count = data.fold(0, (int previousValue, JeepData jeepney) => previousValue + jeepney.passenger_count).toDouble();
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
                                                                Expanded(
                                                                  child: Text(
                                                                    "${passenger_count} total passengers",
                                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white54),
                                                                    textAlign: TextAlign.end,
                                                                    maxLines: 2,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: Constants.defaultPadding),
                                                            route_info_chart(route_choice: route_choice, operating: operating, not_operating: not_operating),
                                                            const SizedBox(height: Constants.defaultPadding),
                                                            const Divider(),
                                                            isHoverJeep?JeepInfoCard(route_choice: route_choice, data: pressedJeep.jeep):SelectJeepInfoCard()
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                        ),
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




















