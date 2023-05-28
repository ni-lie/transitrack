import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../style/constants.dart';

class Legends extends StatelessWidget {
  const Legends({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.all(Constants.defaultPadding),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Occupancy", style: TextStyle(fontSize: 16),),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                          height: 10,
                          width: 10,
                          color: Colors.lightGreenAccent[400]
                      ),
                      const SizedBox(width: Constants.defaultPadding/2),
                      const Text("Low")
                    ]
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                          height: 10,
                          width: 10,
                          color: Colors.blue[900]
                      ),
                      const SizedBox(width: Constants.defaultPadding/2),
                      const Text("High")
                    ]
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                          height: 10,
                          width: 10,
                          color: Colors.red
                      ),
                      const SizedBox(width: Constants.defaultPadding/2),
                      const Text("Full")
                    ]
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


