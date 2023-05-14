import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../config/route_coordinates.dart';
import '../style/constants.dart';

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    super.key, required this.Route, required this.icon, required this.press, required this.isSelected,
  });

  final JeepRoute Route;
  final Image icon;
  final ui.VoidCallback? press;
  final bool isSelected;

  String formatTime(List<int> timeList) {
    int startHour = timeList[0];
    int endHour = timeList[1];

    String startSuffix = (startHour >= 12) ? 'PM' : 'AM';
    String endSuffix = (endHour >= 12) ? 'PM' : 'AM';

    if (startHour > 12) {
      startHour -= 12;
    } else if (startHour == 0) {
      startHour = 12;
    }

    if (endHour > 12) {
      endHour -= 12;
    } else if (endHour == 0) {
      endHour = 12;
    }

    return '$startHour $startSuffix - $endHour $endSuffix';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 0.0,
      contentPadding: EdgeInsets.only(left: Constants.defaultPadding),
      trailing: icon,
      title: Text(Route.name, style: const TextStyle(color: Colors.white54), overflow: TextOverflow.ellipsis, maxLines: 1,),
      subtitle: Text(formatTime(Route.OpHours), style: const TextStyle(color: Colors.white30), overflow: TextOverflow.ellipsis, maxLines: 1,),
      selected: isSelected,
      selectedTileColor: Colors.white10
      // selectedTileColor: Colors.blue,
    );
  }
}