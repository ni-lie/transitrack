import 'package:flutter/cupertino.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/models/jeep_model.dart';

import 'config/route_coordinates.dart';

class MapboxWeb extends StatefulWidget {
  int route;
  List<JeepData> positions;
  MapboxWeb({
    super.key, required this.route, required this.positions
  });

  @override
  State<MapboxWeb> createState() => _MapboxWebState();
}

class _MapboxWebState extends State<MapboxWeb> {
  late MapboxMapController _mapController;

  void _addRoute() {
    switch (widget.route) {
      case 0: // ikot
        _mapController.addLine(LineOptions(
          geometry: Routes.ikot,
          lineColor: '#FFC107',
          lineWidth: 5,
        ));
        break;
      case 1: // toki
        _mapController.addLine(LineOptions(
          geometry: Routes.toki,
          lineColor: '#F57F17',
          lineWidth: 5,
        ));
        break;
      case 2: // katip
        break;
      case 3: // philcoa
        break;
      case 4: // sm
        break;
    }
  }

  void _addJeeps(){
    for (var i = 0; i < widget.positions.length; i++){
      LatLng? test = LatLng(widget.positions[i].location.latitude, widget.positions[i].location.longitude);
      _mapController.addCircle(CircleOptions(
          geometry: test,
          circleColor: widget.route==0?'#FFC107':'#F57F17',
          circleRadius: 15
      ));
    }
  }

  void _onMapCreated(MapboxMapController controller){
    _mapController = controller;
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
    return Container(
        child: MapboxMap(
          accessToken: 'pk.eyJ1IjoiemVkZWMiLCJhIjoiY2xoZzdidjc1MDIxMDNsbnpocmloZXczeSJ9.qsTTfBC6ZB9ncP2rvbCnIw',
          onMapCreated: _onMapCreated,
          styleString: 'mapbox://styles/zedec/clhg7iztv00gq01rh5efqhzz5',
          onStyleLoadedCallback: (){
            _addRoute();
            _addJeeps();
          },
          initialCameraPosition: const CameraPosition(
            target: LatLng(14.653836, 121.068427),
            zoom: 15
          ),
        )
    );
  }
}

