import 'package:flutter/cupertino.dart';

import '../models/jeep_model.dart';
import '../style/constants.dart';
import '../style/small_text.dart';

class RouteStatistics extends StatelessWidget {
  const RouteStatistics({
    super.key,
    required this.jeepList,
  });

  final List<JeepData> jeepList;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  color: Constants.white,
                  boxShadow: const [BoxShadow(color: Constants.iconGray,
                      blurRadius: 15.0,
                      offset:  Offset(10.0, 15.0)
                  )]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    child: SmallText(
                      text: "Jeepneys Operating: ${jeepList.length}",
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: SmallText(
                      text: "Commuters on board: ${jeepList.fold(0, (int previousValue, JeepData jeepney) => previousValue + jeepney.passenger_count)}",
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}