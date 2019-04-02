library stepper;

import 'package:flutter/material.dart';
import 'dart:math';

typedef StopperBuilder(BuildContext context, ScrollController controller, ScrollPhysics physics, int stop);

class Stopper extends StatefulWidget {

  final List<double> stops;
  final Function onClose;
  final StopperBuilder builder;
  final int initialStop;
  final double dragThreshold;

  Stopper({
    Key key,
    @required
    this.builder,
    @required
    this.stops,
    this.initialStop = 0,
    this.onClose,
    this.dragThreshold = 25
  }): assert(initialStop < stops.length), super(key: key);

  @override
  StopperState createState() => StopperState();

}

class StopperState extends State<Stopper> with SingleTickerProviderStateMixin {

  List<double> _stops;
  int _currentStop;
  int _targetStop;
  bool _dragging = false;
  bool _closing = false;
  double _dragOffset;
  double _closingHeight;
  ScrollController _scrollController;
  ScrollPhysics _scrollPhysics;
  Animation<double> _animation;
  AnimationController _animationController;
  Tween<double> _tween;

  ScrollPhysics getScrollPhysicsForStop(s) {
    if(s == _stops.length-1)
      return BouncingScrollPhysics();
    else
      return NeverScrollableScrollPhysics();
  }

  @override
  void initState() {
    super.initState();
    this._stops = widget.stops;
    this._currentStop = widget.initialStop;
    this._targetStop = _currentStop;
    _scrollController = ScrollController();
    _scrollPhysics = getScrollPhysicsForStop(_currentStop);
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    final curveAnimation = CurvedAnimation(parent: _animationController, curve: Curves.linear);
    _tween = Tween<double>(begin: _stops[_currentStop], end: _stops[_targetStop]);
    _animation = _tween.animate(curveAnimation);
    _scrollController.addListener(() {
      if(_scrollController.offset < -widget.dragThreshold) {
        if(this._currentStop != this._targetStop || _dragging)
          return;
        if(this._currentStop > 0) {
          final h0 = height;
          this._targetStop = this._currentStop - 1;
          _animate(h0, _stops[_targetStop]);
        } else if (!_closing) {
          close();
        }
      }
    });
  }

  @override
  void didUpdateWidget(Stopper oldWidget) {
    super.didUpdateWidget(oldWidget);
    this._stops = widget.stops;
    this._currentStop = min(_currentStop, _stops.length-1);
    this._targetStop = min(_currentStop, _stops.length-1);
  }

  get stop => _currentStop;
  set stop(nextStop) {
    _targetStop = nextStop;
  }

  bool get canClose {
    return widget.onClose != null;
  }

  void close() {
    if(!_closing && canClose) {
      _closingHeight = height;
      _animationController.stop(canceled: true);
      _dragging = false;
      _closing = true;
      widget.onClose();
    }
  }

  void _animate(double from, double to, [double velocity]) {
    _tween.begin = from;
    _tween.end = to;
    _animationController.value = 0;
    if(_scrollController.offset < 0)
      _scrollController.animateTo(0, duration: Duration(milliseconds: 200), curve: Curves.linear);
    _animationController.fling().then((_) {
      this._currentStop = this._targetStop;
      setState(() {
        _scrollPhysics = getScrollPhysicsForStop(_currentStop);
      });
    });
  }

  get height {
    if(_closing)
      return _closingHeight;
    else if(_dragging)
      return _stops[_currentStop] + _dragOffset;
    else if(_animationController.isAnimating)
      return _animation.value;
    else
      return _stops[_currentStop];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          if(_currentStop != _targetStop)
            return;
          _scrollController.jumpTo(0);
          _dragging = true;
          _dragOffset = 0;
          setState(() {
          });
        },
        onVerticalDragUpdate: (details) {
          if(_dragging) {
            _scrollController.jumpTo(0);
            _dragOffset -= details.delta.dy;
            setState(() {});
          }
        },
        onVerticalDragEnd: (details) {
          if(!_dragging || _closing)
            return;
          if (_dragOffset > widget.dragThreshold) {
            _targetStop = min(_currentStop + 1, _stops.length-1);
          } else if (_dragOffset < -widget.dragThreshold) {
            _targetStop = max(canClose ? -1 : 0 , _currentStop - 1);
          }
          if(_targetStop < 0) {
            close();
          } else {
            _dragging = false;
            _animate(_stops[_currentStop] + _dragOffset, _stops[_targetStop]);
          }
        },
        child: widget.builder(context, _scrollController, _scrollPhysics, _currentStop),
      ),
      builder: (context, child) {
        return SizedBox(
          height: min(_stops[_stops.length-1], max(0, height)),
          child: child,
        );
      }
    );
  }

}

class MyScrollPhysics extends ScrollPhysics {

  const MyScrollPhysics({ScrollPhysics parent}): super(parent: parent);

  @override
  ScrollPhysics applyTo(ScrollPhysics ancestor) {
    return MyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if(position.pixels > position.maxScrollExtent)
      return false;
    return true;
//    return parent.shouldAcceptUserOffset(position);
  }

  @override
  bool get allowImplicitScrolling {
    return true;//parent?.allowImplicitScrolling ?? true;
  }

}

Future showStopper({
    Key key,
    @required
    StopperBuilder builder,
    @required
    List<double> stops,
    int initialStop = 0,
    double dragThreshold = 25
  }) {
    PersistentBottomSheetController cont;
    cont = showBottomSheet(
      builder: (context) {
        return Stopper(
          key: key, builder: builder, stops: stops, initialStop: initialStop, dragThreshold: dragThreshold,
          onClose: () {
            cont.close();
          },
        );
      },
    );
    return cont.closed;
}