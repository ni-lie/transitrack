import 'package:flutter/cupertino.dart';

class BigText extends StatelessWidget {
  Color? color;
  final String text;
  double size;
  TextOverflow overFlow;
  BigText({Key? key, this.color = const Color(0xFF332d2b),
    required this.text,
    this.size=20,
    this.overFlow = TextOverflow.ellipsis           // Kung lagpas yung text sa screen, gawan ng ellipsis
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
        text,
        maxLines: 1,
        overflow: overFlow,
        style: TextStyle(
            fontFamily: 'Roboto',
            color: color,
            fontSize: size == 0?20:size,
            fontWeight: FontWeight.w600
        )
    );
  }
}
