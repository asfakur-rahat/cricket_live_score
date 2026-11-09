import 'package:cricket_live_score/src/controller/cricket_score_controller.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:flutter/widgets.dart';

/// The [CricketScoreController] behind a widget that takes either a
/// controller or a source.
///
/// With a source, the host creates the controller, starts it, pauses it
/// while the app is in the background and disposes it. An injected
/// controller is left alone: its owner starts, pauses and disposes it.
mixin ScoreControllerHost<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  /// The controller passed to the widget, if any.
  CricketScoreController? get widgetController;

  /// The source passed to the widget, if any.
  CricketScoreSource? get widgetSource;

  /// The controller in use.
  late CricketScoreController controller;

  /// Whether [controller] was created, and so is disposed, by this host.
  bool ownsController = false;

  /// Whether the app is in the background.
  bool inBackground = false;

  /// Called when [controller]'s state changes; rebuilds by default.
  void onScoreStateChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachController();
  }

  // What the last attach used. The mixin cannot read the old widget's
  // fields, so didUpdateWidget compares the new widget against these.
  CricketScoreController? _lastController;
  CricketScoreSource? _lastSource;

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastController != widgetController || _lastSource != widgetSource) {
      _detachController();
      _attachController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        inBackground = true;
        if (ownsController) controller.pause();
      case AppLifecycleState.resumed:
        if (!inBackground) return;
        inBackground = false;
        if (ownsController) controller.start();
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachController();
    super.dispose();
  }

  void _attachController() {
    final injected = widgetController;
    _lastController = injected;
    _lastSource = widgetSource;
    ownsController = injected == null;
    controller = injected ?? CricketScoreController(source: widgetSource!);
    controller.addListener(onScoreStateChanged);
    if (ownsController && !inBackground) controller.start();
  }

  void _detachController() {
    controller.removeListener(onScoreStateChanged);
    if (ownsController) controller.dispose();
  }
}
