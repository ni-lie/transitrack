import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../config/route_coordinates.dart';
import '../style/constants.dart';

class SelectJeepInfoCard extends StatelessWidget {
  SelectJeepInfoCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      margin: const EdgeInsets.only(top: Constants.defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: Colors.grey.withOpacity(0.15),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(Constants.defaultPadding)),
      ),
      child: Row(
        children: [
          const SizedBox(
            height: 40,
            width: 40,
            child: Icon(Icons.touch_app_rounded, color: Colors.white38)
          ),
          const SizedBox(width: Constants.defaultPadding),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select a vehicle", maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("for more information", style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )
          ),
        ],
      ),
    );
  }
}