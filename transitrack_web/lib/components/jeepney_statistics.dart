import 'package:flutter/cupertino.dart';

import '../models/jeep_model.dart';
import '../style/big_text.dart';
import '../style/small_text.dart';

class JeepneyStatistics extends StatelessWidget {
  const JeepneyStatistics({
    super.key,
    required this.jeepList,
  });

  final List<JeepData> jeepList;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: jeepList.length,
          itemBuilder: (context, index) {
            JeepData jeep = jeepList[index];
            return Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigText(text: "Jeepney ${index+1}", size: 28,),
                  SizedBox(height: 20),
                  SmallText(text: "Ax: ${jeep.acceleration[0]}, Ay: ${jeep.acceleration[1]}, Az: ${jeep.acceleration[2]}", size: 16,),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SmallText(text: "Passengers: ${jeep.passenger_count}", size: 16)
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}