import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../MenuController.dart';
import '../config/responsive.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if(!Responsive.isDesktop(context))
        IconButton(onPressed: context.read<MenuControllers>().controlMenu, icon: Icon(Icons.menu, size: 50,)),
        if (Responsive.isMobile(context)) Spacer(flex: Responsive.isDesktop(context) ? 2:1)
      ],
    );
  }
}
