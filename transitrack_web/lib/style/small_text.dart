import 'package:flutter/cupertino.dart';

class SmallText extends StatelessWidget {
  Color? color;
  final String text;
  double size;
  double height;
  bool? isOneLine;
  SmallText({Key? key, this.color = const Color(0xFF332d2b),
    this.isOneLine = false,
    required this.text,
    this.size=12,
    this.height=1.2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
        overflow: TextOverflow.ellipsis,
        maxLines: isOneLine!?1:99999999,
        text,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: color,
          fontSize: size,
          height: height,
        )
    );
  }
}
