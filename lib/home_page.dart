import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart' as extended;
import 'package:timer/noscale_flexible_spacebar.dart';
import 'package:timer/timer_painter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {

  final Color _primaryColor = Colors.deepOrangeAccent; //主色
  Animation<int> _intAnim;  //控制圈圈
  AnimationController _animationController; //控制圈圈
  bool _isActivated = false;  //是否点过了开始
  bool _isAnimating = false;  //理解为是否在转圈圈
  bool _isAppbarExpanded = true;  //bar是否为展开状态
  final int _lineNum = 180;    //控制圈圈的竖线的数量
  final double _appbarExpandedHeight = 280; //bar展开的高度
  final double _appbarHeight = 120; //bar折叠后的高度
  double _fontSize = 38;  //计时不够一小时是不显示 小时(hour) 的，当显示 小时 时将这个变量调小以适应界面
  final List<Duration> _durationList = <Duration>[];  ///存放每次点击计次按钮时的[_currentDuration]
  ValueNotifier<Duration> _currentDuration = ValueNotifier(Duration.zero);  //时刻增长着的，已经累计的时间
  DateTime _startTime;  //按下开始时
  DateTime _pauseTime;  //按下暂停时
  DateTime _continueTime;  //按下继续时
  final ScrollController _sc = ScrollController();
  Ticker _ticker; //在此ticker的回调中触发计时功能
  double get _pinnedHeaderHeight => _isActivated ? 120 : 290;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);  //构造一个Ticker并添加了回调
    //设置了圈圈转一圈的时间 2000 毫秒
    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    ///实际上控制了圈圈的旋转效果[_intAnim.value]是最长彩色短线的位置，变换后就形成了动画效果
    _intAnim = IntTween(begin: 0, end: _lineNum).animate(_animationController);
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
              child: _clockAndDurationList(),
            ),
            _bottomButton(),
          ],
        ),
      ),
    );
  }
  //旋转计时器以及计次列表
  Widget _clockAndDurationList() {
    return NotificationListener<ScrollNotification>(
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
                                child: _dynamicDuration(value)),
                          ),
                          background: Column(
                            children: [
                              Container(
                                width: _appbarExpandedHeight,
                                height: _appbarExpandedHeight,
                                child: CustomPaint(
                                  painter: TimerPainter(_lineNum, _intAnim.value, _isActivated),
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
            return _pinnedHeaderHeight;
          },
          body: _durationsListView()),
    );
  }
  //计次列表
  Widget _durationsListView() {
    return CupertinoScrollbar(
      child: DefaultTextStyle(
        style: TextStyle(color: Colors.black, fontSize: 16),
        child: ListView.builder(
          physics: _isActivated ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
          itemCount: _durationList.length,
          itemBuilder: (BuildContext context, int index) {
            return _durationItem(index);
          },
        ),
      ),
    );
  }
  //计次列表的每一行
  Widget _durationItem(int index) {
    String realIndex = (_durationList.length - index).toStringAsFixedFromStart(2);
    if (index == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(realIndex, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500)),
            SizedBox(height: 40, width: 16),
            ValueListenableBuilder(
              valueListenable: _currentDuration,
              builder: (BuildContext context, Duration value, Widget child) {
                return _dynamicDuration(value);
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
  ///监听[_currentDuration]刷新[Text]的内容构成动态计时的样式
  Widget _dynamicDuration(Duration value) {
    List<String> currentDuration = value.toStringAsMyFormat().split('.');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(text: currentDuration[0], children: <InlineSpan>[
            const TextSpan(text: '.'),
            TextSpan(text: currentDuration[1], style: TextStyle(color: _primaryColor))
          ]),
        ),
      ],
    );
  }
  //底部的按钮区域
  Widget _bottomButton() {
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
                          onPressed: _onCountOrResetPressed,
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        height: 60,
                        child: FlatButton(
                          child: Text(_isAnimating ? '暂停' : '继续'),
                          textColor: _isAnimating ? _primaryColor : Colors.white,
                          shape: CircleBorder(
                              side: BorderSide(color: Colors.grey.shade300, width: _isAnimating ? 2 : 0)),
                          color: _isAnimating ? Colors.transparent : _primaryColor,
                          onPressed: _onPauseOrContinuePressed,
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: 160,
                    height: 40,
                    child: FlatButton(
                      shape: StadiumBorder(),
                      color: _primaryColor,
                      textColor: Colors.white,
                      child: const Text('开始'),
                      onPressed: _onStartPressed,
                    ),
                  ),
          ],
        ));
  }
  ///通过监听滚动区域滚动状态来实现'自动'展开或收起[SliverAppBar]
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
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
  ///[_ticker]将会触发的回调
  void _onTick(Duration elapsed) {
    DateTime now = DateTime.now();
    _currentDuration.value = now.difference(_startTime);
    if (_currentDuration.value.inHours != 0 && _fontSize == 38) {
      //加入显示小时位的话字体要变小
      setState(() {
        _fontSize = 32;
      });
    }
  }
  //开始 按钮
  void _onStartPressed() {
    _isActivated = true;
    _isAnimating = true;
    _addACount();
    _startTime = DateTime.now();
    _ticker.start();
    setState(() {});
    _animationController.repeat();
  }
  //暂停/继续 按钮
  void _onPauseOrContinuePressed() {
    if (_isAnimating) {
      _animationController.stop(canceled: false);
      _isAnimating = false;
      _ticker.stop();
      _pauseTime = DateTime.now();
    } else {
      _animationController.repeat();
      _isAnimating = true;
      _continueTime = DateTime.now();
      _startTime = _startTime.add(_continueTime.difference(_pauseTime));
      _ticker.start();
    }
    setState(() {});
  }
  //计次/重置 按钮
  void _onCountOrResetPressed() {
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
