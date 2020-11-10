import 'package:flutter/material.dart';
import 'dart:math';
class TimerPainter extends CustomPainter {
  TimerPainter(this.lineNumber, this.longestLineIndex, this.activated);

  final int lineNumber;///短线数量
  final int longestLineIndex;///当前最长中线的位置
  final bool activated;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    Paint paint2 = Paint()
      ..color = Colors.deepOrangeAccent
      ..strokeWidth = 1;

    void fixedRotate(double radians){
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(radians);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    final double centerHeight = size.height / 2;
    final double longLength = 20;   ///长线长度
    final double shortLength = 8;  ///短线长度
    double radians = 2*pi/lineNumber; ///每一次旋转的度
    final int coloredCount = 20;
    double changedLength = (longLength - shortLength) / coloredCount*2;

    ///将中线旋转到对应位置，靠这个来实现旋转动画
    fixedRotate(radians*longestLineIndex);
    for(int i = 0;i<=lineNumber/2;i++){
      fixedRotate(radians);
      if(activated && i <= coloredCount/2){
        canvas.drawLine(Offset(changedLength * i,centerHeight), Offset(longLength,centerHeight), paint2);
      }else{
        canvas.drawLine(Offset(longLength - shortLength,centerHeight), Offset(longLength,centerHeight), paint);
      }
    }
    fixedRotate(-pi);
    for(int i = 0;i<=lineNumber/2;i++){
      fixedRotate(-radians);
      if(activated && i <= coloredCount/2){
        canvas.drawLine(Offset(changedLength * i,centerHeight), Offset(longLength,centerHeight), paint2);
      }else{
        canvas.drawLine(Offset(longLength - shortLength,centerHeight), Offset(longLength,centerHeight), paint);
      }
    }

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }



}