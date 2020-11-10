import 'package:flutter/cupertino.dart' hide RefreshIndicatorMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  bool _isActivated = false;
  bool _isAnimating = false;
  final double _appbarExpandedHeight = 280;
  final double _appbarHeight = 120;
  double _fontSize = 38;

  final List<Duration> _durationList = <Duration>[];

  ValueNotifier<Duration> _currentDuration = ValueNotifier(Duration.zero);
  DateTime _startTime;
  DateTime _pauseTime;  //  暂停时
  DateTime _reStartTime;

  double get pinnedHeaderHeight => _isActivated ? 120 : 290;
  final ScrollController _sc = ScrollController();
  bool _isAppbarExpanded = true;

  Ticker _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration elapsed) {
      DateTime now = DateTime.now();
      _currentDuration.value = now.difference(_startTime);
      if (_currentDuration.value.inHours != 0 && _fontSize == 38) {
        //加入显示小时位的话字体要变小
        setState(() {
          _fontSize = 32;
        });
      }
    });

    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _intAnim = IntTween(begin: 0, end: lineNum).animate(_animationController);
  }

  @override
  void dispose() {
    super.dispose();
    _sc.dispose();
    _animationController.dispose();
    _ticker.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AnimatedContainer(
              height: _isActivated ? 80 : 150,
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
                          expandedHeight: _appbarExpandedHeight,
                          toolbarHeight: _appbarHeight,
                          elevation: 0,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          flexibleSpace: ValueListenableBuilder(
                              valueListenable: _currentDuration,
                              builder: (BuildContext context, value, Widget child) {
                                return NoScaleFlexibleSpaceBar(
                                    centerTitle: true,
                                    titlePadding: EdgeInsets.zero,
                                    title: Center(
                                      child: DefaultTextStyle(
                                          style: TextStyle(color: Colors.black, fontSize: _fontSize),
                                          child: dynamicDuration(value)),
                                    ),
                                    background: Column(
                                      children: [
                                        Container(
                                          width: _appbarExpandedHeight,
                                          height: _appbarExpandedHeight,
                                          child: CustomPaint(
                                            painter: TimerPainter(lineNum, _intAnim.value, _isActivated),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Text('秒', style: TextStyle(color: Colors.transparent)),
                                                Text(
                                                  ' ',
                                                  style: TextStyle(color: Colors.black, fontSize: _fontSize),
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
      print(_isAppbarExpanded);
      if (_sc.offset > 0 && _sc.offset < (_appbarExpandedHeight - _appbarHeight)) {
        double target = _isAppbarExpanded ? _appbarExpandedHeight - _appbarHeight : 0;
        _sc.animateTo(target, duration: const Duration(milliseconds: 100), curve: Curves.linear);
        _isAppbarExpanded = !_isAppbarExpanded;
      }
      if (_sc.offset == 0) {
        _isAppbarExpanded = false;
      }
      if (_sc.offset == _appbarExpandedHeight - _appbarHeight) {
        _isAppbarExpanded = true;
      }
    }
    return false;
  }

  Widget durationsListView() {
    return CupertinoScrollbar(
      child: DefaultTextStyle(
        style: TextStyle(color: Colors.black, fontSize: 16),
        child: ListView.builder(
          physics: _isActivated ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
          itemCount: _durationList.length,
          itemBuilder: (BuildContext context, int index) {
            return durationItem(index);
          },
        ),
      ),
    );
  }

  Widget durationItem(int index) {
    String realIndex = (_durationList.length - index).toStringAsFixedFromStart(2);
    if (index == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(realIndex, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
            SizedBox(height: 40, width: 16),
            ValueListenableBuilder(
              valueListenable: _currentDuration,
              builder: (BuildContext context, Duration value, Widget child) {
                return dynamicDuration(value);
              },
            ),
            Spacer(),
            ValueListenableBuilder(
              valueListenable: _currentDuration,
              builder: (BuildContext context, Duration currentDuration, Widget child) {
                return Text('+${(currentDuration - _durationList.first).toStringAsMyFormat()}',
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
            Text(_durationList[index - 1].toStringAsMyFormat()),
            const Spacer(),
            Text('+${(_durationList[index - 1] - _durationList[index]).toStringAsMyFormat()}',
                style: TextStyle(fontSize: 14))
          ],
        ),
      );
    }
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
            _isActivated
                ? Row(
                    children: [
                      Container(
                        height: 60,
                        child: FlatButton(
                          child: Text(_isAnimating ? '计次' : '复位'),
                          shape: CircleBorder(side: BorderSide(color: Colors.grey.shade300, width: 2)),
                          color: Colors.transparent,
                          onPressed: onCountOrResetPressed,
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        height: 60,
                        child: FlatButton(
                          child: Text(_isAnimating ? '暂停' : '继续'),
                          textColor: _isAnimating ? primaryColor : Colors.white,
                          shape: CircleBorder(
                              side: BorderSide(color: Colors.grey.shade300, width: _isAnimating ? 2 : 0)),
                          color: _isAnimating ? Colors.transparent : primaryColor,
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
    _isActivated = true;
    _isAnimating = true;
    _addACount();
    _startTime = DateTime.now();
    _ticker.start();
    setState(() {});
    _animationController.repeat();
  }

  void onPauseOrContinuePressed() {
    if (_isAnimating) {
      _animationController.stop(canceled: false);
      _isAnimating = false;
      _ticker.stop();
      _pauseTime = DateTime.now();
    } else {
      _animationController.repeat();
      _isAnimating = true;
      _reStartTime = DateTime.now();
      _startTime = _startTime.add(_reStartTime.difference(_pauseTime));
      _ticker.start();
    }
    setState(() {});
  }

  void onCountOrResetPressed() {
    if (_isAnimating) {
      _addACount();
      setState(() {});
    } else {
      _isActivated = false;
      _durationList.clear();
      _animationController.stop();
      _ticker.stop();
      _currentDuration.value = Duration.zero;
      if (_fontSize != 38) {
        _fontSize = 38;
      }
      setState(() {});
    }
  }
  //计次
  void _addACount() {
    _durationList.insert(0, _currentDuration.value);
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
