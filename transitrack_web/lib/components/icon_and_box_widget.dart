import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../style/constants.dart';

class IconAndBoxWidget extends StatelessWidget {
  Icon icon;
  String text;
  bool toggled;
  IconAndBoxWidget({
    super.key,
    required this.icon,
    required this.text,
    required this.toggled
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      margin: const EdgeInsets.all(Constants.defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: Colors.grey,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          icon,
          SizedBox(width: Constants.defaultPadding),
          Text(text)
        ],
      ),
    );
  }
}