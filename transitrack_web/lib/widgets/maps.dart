import 'dart:html';
import 'package:flutter/material.dart';
import 'package:google_maps/google_maps.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;

import '../config/route_coordinates.dart';
import '../models/jeep_model.dart';

class GoogleMap extends StatefulWidget {
  int route;
  List<JeepData> jeepList;
  GoogleMap({Key? key, required this.route, required this.jeepList}) : super(key: key);

  @override
  State<GoogleMap> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  @override
  Widget build(BuildContext context) {
    String htmlId = "7";

    ui.platformViewRegistry.registerViewFactory(htmlId, (int viewId) {
      final myLatlng = LatLng(14.653836, 121.068427);

      final mapOptions = MapOptions()
        ..zoom = 16
        ..center = myLatlng
        ..clickableIcons = false
        ..streetViewControl = false
      ;

      final elem = DivElement()
        ..id = htmlId
        ..style.width = "100%"
        ..style.height = "100%"
        ..style.border = 'none';

      final map = GMap(elem, mapOptions);

      for (var i = 0; i < widget.jeepList.length; i++) {
        Marker(MarkerOptions()
          ..position = LatLng(widget.jeepList[i].location.latitude,
              widget.jeepList[i].location.longitude)
          ..map = map
          ..clickable = true
          ..title = "Jeepney $i"
        );
      }

      switch (widget.route) {
        case 0: // ikot
          Polygon(PolygonOptions()
            ..paths = Routes.ikot
            ..visible = true
            ..map = map
            ..fillOpacity = 0.0
            ..strokeWeight = 4
            ..strokeColor = '#757A00'
          );
          Polygon(PolygonOptions()
            ..paths = Routes.ikot
            ..visible = true
            ..map = map
            ..fillOpacity = 0.0
            ..strokeColor = '#F3FF00'
          );
          break;
        case 1: // toki
          Polygon(PolygonOptions()
            ..paths = Routes.toki
            ..visible = true
            ..map = map
            ..fillOpacity = 0.0
            ..strokeColor = '#F57F17'
          );
          break;
        case 2: // katip
          break;
        case 3: // philcoa
          break;
        case 4: // sm
          break;
      }
      return elem;
    });

    return HtmlElementView(viewType: htmlId);
  }
}

