library stopper;

import 'package:flutter/material.dart';
import 'dart:math';

/// A builder function to be passed to [Stopper].
typedef Widget StopperBuilder(
    /// A build context
    BuildContext context,
    /// A scroll controller to be passed to a scrollable widget
    ScrollController controller, 
    // A scroll physics to be passed to a scrollable widget
    ScrollPhysics physics, 
    /// The current stop value.
    int stop
  );

/// A widget that changes its height to one of the predefined values based on user-initiated dragging.
/// Designed to be used with [showBottomSheet()] method.
class Stopper extends StatefulWidget {
    /// The list of stop heights in logical pixels. The values must be sorted from lowest to highest.
  final List<double> stops;
    /// This callback function is called when the user triggers a close. If null, the bottom sheet cannot be closed by the user.
  final Function onClose;
    /// A builder to build the contents of the bottom sheet.
  final StopperBuilder builder;
    /// The initial stop.
  final int initialStop;
    /// The minimum offset (in logical pixels) necessary to trigger a stop change when dragging.
  final double dragThreshold;
    /// THe desidered shape
  final ShapeBorder shape;

  /// The constructor.
  Stopper({
    Key key,
    @required this.builder,
    @required this.stops,
    this.initialStop = 0,
    this.onClose,
    this.dragThreshold = 25,
    this.shape = null
  })
      : assert(initialStop < stops.length),
        super(key: key);

  @override
  StopperState createState() => StopperState();
}

/// The state of [Stopper] widget.
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

  ScrollPhysics _getScrollPhysicsForStop(s) {
    if (s == _stops.length - 1)
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
    _scrollPhysics = _getScrollPhysicsForStop(_currentStop);
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    final curveAnimation = CurvedAnimation(parent: _animationController, curve: Curves.linear);
    _tween = Tween<double>(begin: _stops[_currentStop], end: _stops[_targetStop]);
    _animation = _tween.animate(curveAnimation);
    _scrollController.addListener(() {
      if (_scrollController.offset < -widget.dragThreshold) {
        if (this._currentStop != this._targetStop || _dragging) return;
        if (this._currentStop > 0) {
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
    this._currentStop = min(_currentStop, _stops.length - 1);
    this._targetStop = min(_currentStop, _stops.length - 1);
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
    _scrollController.dispose();
  }

  /// The current stop value. The value changes after the stop change animation is complete.
  get stop => _currentStop;

  set stop(nextStop) {
    _targetStop = max(0, min(_stops.length - 1, nextStop));
    _animate(height, nextStop);
  }

  /// Returns true if this [Stopper] can be closed by the user.
  bool get canClose {
    return widget.onClose != null;
  }

  /// Closes the bottom sheet. Repeated calls to this method will be ignored.
  void close() {
    if (!_closing && canClose) {
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
    if (_scrollController.offset < 0) _scrollController.animateTo(0, duration: Duration(milliseconds: 200), curve: Curves.linear);
    _animationController.fling().then((_) {
      this._currentStop = this._targetStop;
      setState(() {
        _scrollPhysics = _getScrollPhysicsForStop(_currentStop);
      });
    });
  }

  /// The current height of the bottom sheet.
  get height {
    if (_closing)
      return _closingHeight;
    else if (_dragging)
      return _stops[_currentStop] + _dragOffset;
    else if (_animationController.isAnimating)
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
            if (_currentStop != _targetStop) return;
            _scrollController.jumpTo(0);
            _dragging = true;
            _dragOffset = 0;
            setState(() {});
          },
          onVerticalDragUpdate: (details) {
            if (_dragging) {
              _scrollController.jumpTo(0);
              _dragOffset -= details.delta.dy;
              setState(() {});
            }
          },
          onVerticalDragEnd: (details) {
            if (!_dragging || _closing) return;
            if (_dragOffset > widget.dragThreshold) {
              _targetStop = min(_currentStop + 1, _stops.length - 1);
            } else if (_dragOffset < -widget.dragThreshold) {
              _targetStop = max(canClose ? -1 : 0, _currentStop - 1);
            }
            if (_targetStop < 0) {
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
            height: min(_stops[_stops.length - 1], max(0, height)),
            child: child,
          );
        });
  }
}

/// Shows the Stopper bottom sheet.
/// Returns a [PersistentBottomSheetController] that can be used 
PersistentBottomSheetController showStopper(
    {
    /// The key of the [Stopper] widget
    Key key,
    /// The build context 
    @required BuildContext context,
    /// The builder of the bottom sheet
    @required StopperBuilder builder,
    /// The list of stop heights as logical pixel values. Use [MediaQuery] to compute the heights relative to screen height.
    /// The order of the stop heights must be from the lowest to the highest.
    @required List<double> stops,
    /// The initial stop number.
    int initialStop = 0,
    /// If [true] then the user can close the bottom sheet dragging it down from the lowest stop. 
    bool userCanClose = true,
    /// The minimum offset (in logical pixels) to trigger a stop change when dragging.
    double dragThreshold = 25,
    /// The desidered shape
    ShapeBorder shape = null,
    /// Required for modal bottomSheet
    bool isScrollController = true
    }) {
  PersistentBottomSheetController cont;
  cont = showBottomSheet(
    context: context,
    builder: (context) {
      return Stopper(
        shape: shape,
        key: key,
        builder: builder,
        stops: stops,
        initialStop: initialStop,
        dragThreshold: dragThreshold,
        onClose: userCanClose ? () {
          cont.close();
        }: null,
      );
    },
  );
  return cont;
}

/// Shows the Stopper modal bottom sheet.
/// Returns a [Future] that can be used
Future showModalStopper(
    {
      /// The key of the [Stopper] widget
      Key key,
      /// The build context
      @required BuildContext context,
      /// The builder of the bottom sheet
      @required StopperBuilder builder,
      /// The list of stop heights as logical pixel values. Use [MediaQuery] to compute the heights relative to screen height.
      /// The order of the stop heights must be from the lowest to the highest.
      @required List<double> stops,
      /// The initial stop number.
      int initialStop = 0,
      /// If [true] then the user can close the bottom sheet dragging it down from the lowest stop.
      bool userCanClose = true,
      /// The minimum offset (in logical pixels) to trigger a stop change when dragging.
      double dragThreshold = 25,
      /// The desidered shape
      ShapeBorder shape = null,
      /// Required for modal bottomSheet
      bool isScrollController = true
    }) {
  Future cont;
  cont = showModalBottomSheet(
    shape: shape,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return Stopper(
        shape: shape,
        key: key,
        builder: builder,
        stops: stops,
        initialStop: initialStop,
        dragThreshold: dragThreshold,
//        onClose: userCanClose ? () {
//          cont.close();
//        }: null,
      );
    },
  );
  return cont;
}