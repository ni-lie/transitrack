import 'package:flutter/cupertino.dart';

import '../widgets/shimmer_widget.dart';

class RouteInfoPanelShimmer extends StatelessWidget {
  const RouteInfoPanelShimmer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerWidget(radius: 30, height: 150),
        SizedBox(height: 20),
        Expanded(
          child: SizedBox(
            child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                itemCount: 10,
                itemBuilder: (context, index){
                  return Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidget(height: 40, width: 300, radius: 30),
                        SizedBox(height: 20),
                        ShimmerWidget(height: 20, width: 150, radius: 30),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            ShimmerWidget(height: 20, width: 225, radius: 30),
                            SizedBox(width: 30,),
                            ShimmerWidget(height: 20, width: 70, radius: 30),
                          ],
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  );
                }),
          ),
        )
      ],
    );
  }
}