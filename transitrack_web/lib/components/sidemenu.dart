import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config/size_config.dart';
import '../style/colors.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      child: Container(
        width: double.infinity,
        height: SizeConfig.screenHeight,
        color: AppColors.secondaryBg,
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
                      child: Icon(Icons.bus_alert_rounded)
                  ),
                ),
                IconButton(
                  onPressed: (){
                  },
                  icon: Icon(
                      Icons.directions_bus,
                      color: Colors.yellow[700]
                  ),
                  iconSize: 30,
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                ),
                IconButton(
                  onPressed: (){
                  },
                  icon: Icon(
                      Icons.directions_bus,
                      color: Colors.yellow[900]
                  ),
                  iconSize: 30,
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                ),
                IconButton(
                  onPressed: (){
                  },
                  icon: Icon(
                      Icons.directions_bus,
                      color: Colors.red[800]
                  ),
                  iconSize: 30,
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                ),
                IconButton(
                  onPressed: (){
                  },
                  icon: Icon(
                      Icons.directions_bus,
                      color: Colors.green[700]
                  ),
                  iconSize: 30,
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                ),
                IconButton(
                  onPressed: (){
                  },
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
    );
  }
}
