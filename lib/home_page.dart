import 'dart:async';
import 'package:flutter/cupertino.dart' hide RefreshIndicatorMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timer/noscale_flexible_spacebar.dart';
import 'package:timer/timer_painter.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart' as extended;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final Color primaryColor = Colors.deepOrangeAccent;
  Animation<int> _intAnim;
  AnimationController _animationController;
  final int lineNum = 180;
  bool isActivated = false;
  bool isAnimating = false;
  final double appbarExpandedHeight = 280;
  final double appbarHeight = 120;
  double fontSize = 38;

  final List<Duration> durationList = <Duration>[];
  Timer _timer;

  ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);

  double get pinnedHeaderHeight => isActivated ? 120 : 290;
  final ScrollController _sc = ScrollController();
  bool isAppbarExpanded = true;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _intAnim = IntTween(begin: 0, end: lineNum).animate(_animationController);
  }

  @override
  void dispose() {
    super.dispose();
    _sc.dispose();
    _animationController.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AnimatedContainer(
              height: isActivated ? 80 : 150,
              duration: const Duration(milliseconds: 150),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: extended.NestedScrollView(
                    controller: _sc,
                    headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverAppBar(
                          expandedHeight: appbarExpandedHeight,
                          toolbarHeight: appbarHeight,
                          elevation: 0,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          flexibleSpace: ValueListenableBuilder(
                              valueListenable: duration,
                              builder: (BuildContext context, value, Widget child) {
                                return NoScaleFlexibleSpaceBar(
                                    centerTitle: true,
                                    titlePadding: EdgeInsets.zero,
                                    title: Center(
                                      child: DefaultTextStyle(
                                          style: TextStyle(color: Colors.black, fontSize: fontSize),
                                          child: dynamicDuration(value)),
                                    ),
                                    background: Column(
                                      children: [
                                        Container(
                                          width: appbarExpandedHeight,
                                          height: appbarExpandedHeight,
                                          child: CustomPaint(
                                            painter: TimerPainter(lineNum, _intAnim.value, isActivated),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Text('秒', style: TextStyle(color: Colors.transparent)),
                                                Text(
                                                  ' ',
                                                  style: TextStyle(color: Colors.black, fontSize: fontSize),
                                                ),
                                                const Text('秒表', style: TextStyle(color: Colors.black54)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ));
                              }),
                        ),
                      ];
                    },
                    pinnedHeaderSliverHeightBuilder: () {
                      return pinnedHeaderHeight;
                    },
                    body: durationsListView()),
              ),
            ),
            bottomButton(),
          ],
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      if (_sc.offset > 0 && _sc.offset < (appbarExpandedHeight - appbarHeight)) {
        double target = isAppbarExpanded ? appbarExpandedHeight - appbarHeight : 0;
        _sc.animateTo(target, duration: const Duration(milliseconds: 100), curve: Curves.linear);
        isAppbarExpanded = !isAppbarExpanded;
      }
      if (_sc.offset == 0) {
        isAppbarExpanded = false;
      }
      if (_sc.offset == appbarExpandedHeight - appbarHeight) {
        isAppbarExpanded = true;
      }
    }
    return false;
  }

  Widget durationsListView() {
    return CupertinoScrollbar(
      child: DefaultTextStyle(
        style: TextStyle(color: Colors.black, fontSize: 16),
        child: ListView.builder(
          physics: isActivated ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
          itemCount: durationList.length,
          itemBuilder: (BuildContext context, int index) {
            return durationItem(index);
          },
        ),
      ),
    );
  }

  Widget durationItem(int index) {
    String realIndex = (durationList.length - index).toStringAsFixedFromStart(2);
    if (index == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(realIndex, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
            SizedBox(height: 40, width: 16),
            ValueListenableBuilder(
              valueListenable: duration,
              builder: (BuildContext context, Duration value, Widget child) {
                return dynamicDuration(value);
              },
            ),
            Spacer(),
            ValueListenableBuilder(
              valueListenable: duration,
              builder: (BuildContext context, Duration currentDuration, Widget child) {
                return Text('+${(currentDuration - durationList.first).toStringAsMyFormat()}',
                    style: TextStyle(fontSize: 14));
              },
            )
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(realIndex),
            const SizedBox(height: 40, width: 16),
            Text(durationList[index - 1].toStringAsMyFormat()),
            const Spacer(),
            Text('+${(durationList[index - 1] - durationList[index]).toStringAsMyFormat()}',
                style: TextStyle(fontSize: 14))
          ],
        ),
      );
    }
  }

  Widget clock() {
    return Container(
      width: 270,
      height: 270,
      child: ValueListenableBuilder(
        valueListenable: duration,
        builder: (BuildContext context, Duration value, Widget child) {
          return CustomPaint(
            painter: TimerPainter(lineNum, _intAnim.value, isActivated),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('秒', style: TextStyle(color: Colors.transparent)),
                DefaultTextStyle(
                    style: TextStyle(color: Colors.black, fontSize: fontSize), child: dynamicDuration(value)),
                const Text('秒表', style: TextStyle(color: Colors.black54)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget dynamicDuration(Duration value) {
    List<String> currentDuration = value.toStringAsMyFormat().split('.');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(text: currentDuration[0], children: <InlineSpan>[
            const TextSpan(text: '.'),
            TextSpan(text: currentDuration[1], style: TextStyle(color: primaryColor))
          ]),
        ),
      ],
    );
  }

  Widget bottomButton() {
    return Container(
        height: 100,
        padding: EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isActivated
                ? Row(
                    children: [
                      Container(
                        height: 60,
                        child: FlatButton(
                          child: Text(isAnimating ? '计次' : '复位'),
                          shape: CircleBorder(side: BorderSide(color: Colors.grey.shade300, width: 2)),
                          color: Colors.transparent,
                          onPressed: onCountOrResetPressed,
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        height: 60,
                        child: FlatButton(
                          child: Text(isAnimating ? '暂停' : '继续'),
                          textColor: isAnimating ? primaryColor : Colors.white,
                          shape: CircleBorder(
                              side: BorderSide(color: Colors.grey.shade300, width: isAnimating ? 2 : 0)),
                          color: isAnimating ? Colors.transparent : primaryColor,
                          onPressed: onPauseOrContinuePressed,
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: 160,
                    height: 40,
                    child: FlatButton(
                      shape: StadiumBorder(),
                      color: primaryColor,
                      textColor: Colors.white,
                      child: Text('开始'),
                      onPressed: onStartPressed,
                    ),
                  ),
          ],
        ));
  }

  void onStartPressed() {
    isActivated = true;
    isAnimating = true;
    _addACount();
    startTimer();
    setState(() {});
    _animationController.repeat();
  }

  void onPauseOrContinuePressed() {
    if (isAnimating) {
      _animationController.stop(canceled: false);
      isAnimating = false;
      _timer.cancel();
    } else {
      _animationController.repeat();
      isAnimating = true;
      startTimer();
    }
    setState(() {});
  }

  void onCountOrResetPressed() {
    if (isAnimating) {
      _addACount();
      setState(() {});
    } else {
      isActivated = false;
      durationList.clear();
      _animationController.stop();
      _timer.cancel();
      duration.value = Duration.zero;
      if (fontSize != 38) {
        fontSize = 38;
      }
      setState(() {});
    }
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      duration.value += Duration(milliseconds: 10);
      if (duration.value.inHours != 0 && fontSize == 38) {
        //加入显示小时位的话字体要变小
        setState(() {
          fontSize = 32;
        });
      }
    });
  }

  //计次
  void _addACount() {
    durationList.insert(0, duration.value);
  }
}

extension IntExtension on int {
  String toStringAsFixedFromStart(int length) {
    String res = this.toString();
    if (length > res.length) {
      res = '0' * (length - res.length) + res;
    }
    return res;
  }
}

extension StringExtension on String {
  String asFixedByZeroFromStart(int length) {
    String res = this;
    if (length > res.length) {
      res = '0' * (length - res.length) + res;
    }
    return res;
  }
}

extension DurationExtension on Duration {
  String toStringAsMyFormat() {
    String res = this.toString();
    res = res.substring(0, res.length - 4);
    int hour = this.inHours;
    if (hour == 0) {
      res = res.substring(2);
    } else if (hour < 10) {
      res = '0' + res;
    }
    return res;
  }
}
