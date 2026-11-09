import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A line of [children] that scrolls sideways without stopping, like a TV
/// news ticker, and loops seamlessly.
///
/// The children sit [gap] apart with [separator] centred between them. The
/// line moves [speed] logical pixels a second towards the start (to the
/// left, or to the right in a right-to-left language), stops while
/// [paused], and fades out at both ends. When it fits, it stays still.
class TickerCrawl extends StatefulWidget {
  /// Creates a crawl.
  const TickerCrawl({
    required this.children,
    required this.separator,
    required this.gap,
    required this.speed,
    required this.paused,
    required this.fadeWidth,
    super.key,
  });

  /// The items, in order.
  final List<Widget> children;

  /// Shown between items.
  final Widget separator;

  /// The width given to each separator.
  final double gap;

  /// Logical pixels a second.
  final double speed;

  /// Whether the line holds still.
  final bool paused;

  /// How far in from each end the line fades out while it scrolls.
  final double fadeWidth;

  @override
  State<TickerCrawl> createState() => _TickerCrawlState();
}

class _TickerCrawlState extends State<TickerCrawl>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _offset = ValueNotifier<double>(0);
  Duration _last = Duration.zero;

  /// The width of one copy of the items, measured after layout.
  double _contentWidth = 0;
  double _viewport = 0;

  bool get _scrolls => _viewport > 0 && _contentWidth > _viewport;

  /// The distance after which the line repeats itself.
  double get _loop => _contentWidth + widget.gap;

  @override
  void didUpdateWidget(TickerCrawl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final seconds =
        (elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond;
    _last = elapsed;
    _offset.value = (_offset.value + seconds * widget.speed) % _loop;
  }

  void _sync() {
    final run = _scrolls && !widget.paused && widget.speed > 0;
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      unawaited(_ticker.start());
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
    if (!_scrolls) _offset.value = 0;
  }

  void _onContentWidth(double width) {
    if (!mounted || width == _contentWidth) return;
    setState(() => _contentWidth = width);
    _sync();
  }

  Widget _row(List<Widget> children, {bool trailingGap = false}) {
    final spacer = SizedBox(
      width: widget.gap,
      child: Center(child: widget.separator),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) spacer,
          children[i],
        ],
        if (trailingGap) spacer,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth != _viewport) {
          _viewport = constraints.maxWidth;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) _sync();
          });
        }
        final scrolls = _scrolls;
        final copy = _SizeReporter(
          onWidth: _onContentWidth,
          child: _row(widget.children),
        );
        Widget line = OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          maxWidth: double.infinity,
          child: scrolls
              ? AnimatedBuilder(
                  animation: _offset,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(rtl ? _offset.value : -_offset.value, 0),
                    child: child,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      copy,
                      SizedBox(
                        width: widget.gap,
                        child: Center(child: widget.separator),
                      ),
                      // The second copy only fills the gap as the first
                      // scrolls away; screen readers hear the first.
                      ExcludeSemantics(
                        child: _row(widget.children, trailingGap: true),
                      ),
                    ],
                  ),
                )
              : copy,
        );
        if (scrolls) {
          final fade = (widget.fadeWidth / _viewport).clamp(0.0, 0.5);
          line = ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => LinearGradient(
              colors: const [
                Color(0x00000000),
                Color(0xFF000000),
                Color(0xFF000000),
                Color(0x00000000),
              ],
              stops: [0, fade, 1 - fade, 1],
            ).createShader(rect),
            child: line,
          );
        }
        return ClipRect(child: line);
      },
    );
  }
}

/// Reports its child's width after layout, whenever it changes.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onWidth, super.child});

  final ValueChanged<double> onWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onWidth = onWidth;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onWidth);

  ValueChanged<double> onWidth;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final width = size.width;
    if (width == _reported) return;
    _reported = width;
    // Layout can't change state; report once the frame is done.
    SchedulerBinding.instance.addPostFrameCallback((_) => onWidth(width));
  }
}
