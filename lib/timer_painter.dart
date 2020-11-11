import 'package:flutter/material.dart';
import 'dart:math';

class TimerPainter extends CustomPainter {

  TimerPainter(this.lineNumber, this.longestLineIndex, this.activated);

  final int lineNumber;
  ///短线数量
  final int longestLineIndex;
  ///当前最长中线的位置
  final bool activated;
  final double longLength = 20;
  ///长线长度
  final double shortLength = 8;
  ///短线长度
  final int coloredCount = 28;
  double get halfColoredCount => coloredCount / 2;
  double get deltaLength => longLength - shortLength;

  List<double> coloredLineLengthList = <double>[];
  ///通过曲线[Curves.easeInOut]来得出彩色短线的长度，这样绘制出来后会呈现一个曲线的样子，目前这个曲线不算很好看
  void _initList() {
    if (coloredLineLengthList.isEmpty) {
      for (int i = 1; i <= halfColoredCount; i++) {
        final double t = i / halfColoredCount;
        final double res = Curves.easeInOut.transformInternal(t) * deltaLength;
        coloredLineLengthList.add(double.parse(res.toStringAsFixed(2)));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _initList();
    Paint paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    Paint paint2 = Paint()
      ..color = Colors.deepOrangeAccent
      ..strokeWidth = 1;

    final double centerHeight = size.height / 2;
    ///每一次旋转的度
    double radians = 2 * pi / lineNumber;

    void fixedRotate(double radians) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(radians);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    void drawLine(int index){
      if (activated && index < halfColoredCount) {
        if (index == halfColoredCount) {
          canvas.drawLine(Offset(longLength, centerHeight), Offset(longLength, centerHeight), paint2);
        } else {
          canvas.drawLine(
              Offset(coloredLineLengthList[index], centerHeight), Offset(longLength, centerHeight), paint2);
        }
      } else {
        canvas.drawLine(Offset(deltaLength, centerHeight), Offset(longLength, centerHeight), paint);
      }
    }

    ///将中线旋转到对应位置，靠这个来实现旋转动画
    fixedRotate(radians * longestLineIndex);
    for (int index = 0; index <= lineNumber / 2; index++) {
      fixedRotate(radians);
      drawLine(index);
    }
    fixedRotate(-pi);
    for (int index = 0; index <= lineNumber / 2; index++) {
      fixedRotate(-radians);
      drawLine(index);
    }

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    coloredLineLengthList = (oldDelegate as TimerPainter).coloredLineLengthList;
    return false;
  }
}
