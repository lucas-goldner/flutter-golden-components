import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A card that morphs into a centred dialog and back.
///
/// Tapping [card] (or pressing Enter or Space while it is focused) opens
/// the dialog: the card's box grows on [spring] into the box of [dialog],
/// its corners easing from [cardRadius] to [dialogRadius], while the card's
/// content fades out, the dialog's fades in, and the page behind blurs
/// under a tinted barrier. Tapping the barrier, pressing Escape, a
/// [MorphCardClose] inside the dialog, or [MorphCard.close] morphs it back.
///
/// Wrap parts of [dialog] in [MorphCardReveal] to have them drift in after
/// the morph. The dialog keeps the text style and icon theme of the place
/// the card sits in. It needs an [Overlay] above it, which [WidgetsApp]
/// provides.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the dialog opens and closes without
/// morphing.
class MorphCard extends StatefulWidget {
  /// Creates a morphing card.
  const MorphCard({
    super.key,
    required this.card,
    required this.dialog,
    this.spring = defaultSpring,
    this.cardRadius = 12,
    this.dialogRadius = 24,
    this.dialogMaxWidth = 500,
    this.color,
    this.borderColor,
    this.barrierColor,
    this.barrierBlur = 4,
    this.semanticLabel,
    this.onOpenChanged,
  });

  /// A quick spring with a hint of bounce (about 320 ms, 8% bounce).
  static const SpringDescription defaultSpring = SpringDescription(
    mass: 1,
    stiffness: 385,
    damping: 36,
  );

  /// The closed card. Its box is what morphs.
  final Widget card;

  /// The open dialog, at most [dialogMaxWidth] wide and the screen height
  /// minus 32 tall.
  final Widget dialog;

  /// The spring of the morph.
  final SpringDescription spring;

  /// Corner radius of the closed card.
  final double cardRadius;

  /// Corner radius of the open dialog.
  final double dialogRadius;

  /// Widest the dialog gets.
  final double dialogMaxWidth;

  /// Fill of the card and dialog. Defaults to white, or near-black when
  /// the ambient text is light.
  final Color? color;

  /// Hairline border of the card and dialog. Defaults to the ambient text
  /// color at 10%.
  final Color? borderColor;

  /// Tint over the page while open. Defaults to a translucent [color].
  final Color? barrierColor;

  /// Blur of the page behind the open dialog, in logical pixels.
  final double barrierBlur;

  /// Read out by screen readers for the card and the dialog.
  final String? semanticLabel;

  /// Called when the dialog opens or closes.
  final ValueChanged<bool>? onOpenChanged;

  /// Closes the open dialog that [context] is inside, if any.
  static void close(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MorphScope>()?.state._close();

  @override
  State<MorphCard> createState() => _MorphCardState();
}

class _MorphScope extends InheritedWidget {
  const _MorphScope({required this.state, required super.child});

  final _MorphCardState state;

  @override
  bool updateShouldNotify(_MorphScope oldWidget) => oldWidget.state != state;
}

class _MorphCardState extends State<MorphCard> with SingleTickerProviderStateMixin {
  /// 0 closed, 1 open (overshoots on the spring).
  late final AnimationController _morph = AnimationController.unbounded(vsync: this)
    ..addStatusListener((status) {
      // The spring stops within its tolerance; land exactly open.
      if (status == AnimationStatus.completed && _open) _morph.value = 1;
    });

  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _measureKey = GlobalKey();
  final FocusNode _cardFocus = FocusNode(debugLabel: 'MorphCard');
  final FocusScopeNode _dialogFocus = FocusScopeNode(debugLabel: 'MorphCard dialog');
  OverlayEntry? _entry;
  bool _open = false;

  /// The card's box in overlay coordinates.
  Rect _from = Rect.zero;

  /// The dialog's laid-out size; null until it has been measured.
  Size? _dialogSize;

  /// Ambient styles captured where the card sits, for the overlay.
  TextStyle _textStyle = const TextStyle();
  IconThemeData _iconTheme = const IconThemeData();

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void dispose() {
    _removeEntry();
    _morph.dispose();
    _cardFocus.dispose();
    _dialogFocus.dispose();
    super.dispose();
  }

  Rect _measureCard() {
    final card = _cardKey.currentContext?.findRenderObject();
    final overlay = Overlay.maybeOf(context, rootOverlay: true)?.context.findRenderObject();
    if (card is! RenderBox || !card.hasSize || overlay is! RenderBox) return _from;
    return MatrixUtils.transformRect(card.getTransformTo(overlay), Offset.zero & card.size);
  }

  void _openDialog() {
    if (_open) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _textStyle = DefaultTextStyle.of(context).style;
    _iconTheme = IconTheme.of(context);
    _from = _measureCard();
    _dialogSize = null;
    _morph
      ..stop()
      ..value = 0;
    _removeEntry();
    _entry = OverlayEntry(builder: (context) => _Overlay(state: this));
    overlay.insert(_entry!);
    setState(() => _open = true);
    widget.onOpenChanged?.call(true);
    SchedulerBinding.instance.addPostFrameCallback((_) => _startMorph());
  }

  /// Once the dialog has been laid out invisibly, morph toward it.
  void _startMorph() {
    if (!mounted || !_open) return;
    final box = _measureKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      SchedulerBinding.instance
        ..addPostFrameCallback((_) => _startMorph())
        ..ensureVisualUpdate();
      return;
    }
    _dialogSize = box.size;
    _entry?.markNeedsBuild();
    // Take focus even if the card still holds it (autofocus would not).
    _dialogFocus.requestFocus();
    if (_reduceMotion) {
      _morph.value = 1;
    } else {
      _morph.animateWith(SpringSimulation(widget.spring, _morph.value, 1, _morph.velocity));
    }
  }

  void _close() {
    if (!_open) return;
    _open = false;
    widget.onOpenChanged?.call(false);
    void finish() {
      if (_open || !mounted) return;
      _removeEntry();
      setState(() {});
      _cardFocus.requestFocus();
    }

    if (_dialogSize == null || _reduceMotion) return finish();
    // The card may have moved (scrolling, resizing) while open.
    _from = _measureCard();
    _entry?.markNeedsBuild();
    _morph
        .animateWith(SpringSimulation(widget.spring, _morph.value, 0, _morph.velocity))
        .whenCompleteOrCancel(finish);
  }

  void _removeEntry() {
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
  }

  Color _surface(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    return widget.color ??
        (ink.computeLuminance() < 0.5 ? const Color(0xFFFFFFFF) : const Color(0xFF18181B));
  }

  Color _border(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    return widget.borderColor ?? ink.withValues(alpha: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        focusNode: _cardFocus,
        mouseCursor: SystemMouseCursors.click,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _openDialog())},
        child: GestureDetector(
          onTap: _openDialog,
          child: Opacity(
            // The overlay draws the card while it is open or closing.
            opacity: _open || _entry != null ? 0 : 1,
            child: _Surface(
              key: _cardKey,
              radius: widget.cardRadius,
              color: _surface(context),
              border: _border(context),
              child: widget.card,
            ),
          ),
        ),
      ),
    );
  }
}

/// The card's fill, hairline border and clip at a given corner radius.
class _Surface extends StatelessWidget {
  const _Surface({
    super.key,
    required this.radius,
    required this.color,
    required this.border,
    required this.child,
  });

  final double radius;
  final Color color;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: r),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: r,
          border: Border.all(color: border),
        ),
        child: ClipRRect(borderRadius: r, child: child),
      ),
    );
  }
}

/// Everything drawn in the overlay: barrier, morphing box, dialog.
class _Overlay extends StatelessWidget {
  const _Overlay({required this.state});

  final _MorphCardState state;

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final surface = state._surface(state.context);
    final border = state._border(state.context);
    final barrier = widget.barrierColor ?? surface.withValues(alpha: 0.4);
    return _MorphScope(
      state: state,
      child: DefaultTextStyle(
        style: state._textStyle,
        child: IconTheme(
          data: state._iconTheme,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screen = constraints.biggest;
              final maxWidth = math.max(0.0, math.min(widget.dialogMaxWidth, screen.width - 32));
              final dialog = ConstrainedBox(
                constraints: BoxConstraints(maxHeight: math.max(0.0, screen.height - 32)),
                child: SizedBox(width: maxWidth, child: widget.dialog),
              );
              return FocusScope(
                node: state._dialogFocus,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                    state._close();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: AnimatedBuilder(
                  animation: state._morph,
                  builder: (context, _) => _Frame(
                    state: state,
                    screen: screen,
                    dialog: dialog,
                    surface: surface,
                    border: border,
                    barrier: barrier,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One frame of the morph.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.state,
    required this.screen,
    required this.dialog,
    required this.surface,
    required this.border,
    required this.barrier,
  });

  final _MorphCardState state;
  final Size screen;
  final Widget dialog;
  final Color surface;
  final Color border;
  final Color barrier;

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final t = state._morph.value;
    final shown = t.clamp(0.0, 1.0);
    final size = state._dialogSize;
    final from = state._from;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: state._close,
            child: shown <= 0.001
                ? const SizedBox.expand()
                : BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: widget.barrierBlur * shown,
                      sigmaY: widget.barrierBlur * shown,
                    ),
                    child: ColoredBox(
                      color: barrier.withValues(alpha: barrier.a * shown),
                      child: const SizedBox.expand(),
                    ),
                  ),
          ),
        ),
        if (size == null) ...[
          // Measuring pass: the dialog laid out invisibly where it will end.
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: Center(
                  child: KeyedSubtree(key: state._measureKey, child: dialog),
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: from,
            child: _Surface(
              radius: widget.cardRadius,
              color: surface,
              border: border,
              child: widget.card,
            ),
          ),
        ] else
          _Morphing(
            state: state,
            rect: Rect.lerp(
              from,
              Rect.fromCenter(
                center: screen.center(Offset.zero),
                width: size.width,
                height: size.height,
              ),
              t,
            )!,
            dialogSize: size,
            dialog: dialog,
            surface: surface,
            border: border,
          ),
      ],
    );
  }
}

/// The box between card and dialog, cross-fading the two inside.
class _Morphing extends StatelessWidget {
  const _Morphing({
    required this.state,
    required this.rect,
    required this.dialogSize,
    required this.dialog,
    required this.surface,
    required this.border,
  });

  final _MorphCardState state;
  final Rect rect;
  final Size dialogSize;
  final Widget dialog;
  final Color surface;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final t = state._morph.value;
    final shown = t.clamp(0.0, 1.0);
    final from = state._from;
    // The card clears out in the first 40%; the dialog arrives by 50%.
    final cardOpacity = (1 - t * 2.5).clamp(0.0, 1.0);
    final dialogOpacity = (t * 2).clamp(0.0, 1.0);
    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        scopesRoute: true,
        namesRoute: widget.semanticLabel != null,
        explicitChildNodes: true,
        label: widget.semanticLabel,
        child: _Surface(
          radius: ui.lerpDouble(widget.cardRadius, widget.dialogRadius, shown)!,
          color: surface,
          border: border,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (dialogOpacity > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  child: IgnorePointer(
                    ignoring: !state._open,
                    child: Opacity(
                      opacity: dialogOpacity,
                      child: Transform.scale(
                        alignment: Alignment.topLeft,
                        scale: rect.width / math.max(dialogSize.width, 1),
                        child: SizedBox.fromSize(size: dialogSize, child: dialog),
                      ),
                    ),
                  ),
                ),
              if (cardOpacity > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: Opacity(
                        opacity: cardOpacity,
                        child: Transform.scale(
                          alignment: Alignment.topLeft,
                          scale: rect.width / math.max(from.width, 1),
                          child: SizedBox.fromSize(size: from.size, child: widget.card),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Part of a [MorphCard] dialog that drifts in after the morph.
///
/// It goes from [fromOpacity], [fromScale] and [fromOffset] to rest as the
/// dialog opens, and back as it closes.
class MorphCardReveal extends StatelessWidget {
  /// Creates a reveal.
  const MorphCardReveal({
    super.key,
    required this.child,
    this.fromOpacity = 0,
    this.fromScale = 0.8,
    this.fromOffset = const Offset(0, 100),
  });

  /// The content to reveal.
  final Widget child;

  /// Opacity while closed.
  final double fromOpacity;

  /// Scale while closed.
  final double fromScale;

  /// Offset while closed.
  final Offset fromOffset;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_MorphScope>();
    if (scope == null) return child;
    final morph = scope.state._morph;
    return AnimatedBuilder(
      animation: morph,
      child: child,
      builder: (context, child) {
        final t = morph.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: ui.lerpDouble(fromOpacity, 1, t)!.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: fromOffset * (1 - t),
            child: Transform.scale(scale: ui.lerpDouble(fromScale, 1, t)!, child: child),
          ),
        );
      },
    );
  }
}

/// A button inside a [MorphCard] dialog that closes it. Shows an X unless
/// given a [child].
class MorphCardClose extends StatelessWidget {
  /// Creates a close button.
  const MorphCardClose({super.key, this.child, this.color, this.size = 24});

  /// Custom content in place of the X.
  final Widget? child;

  /// Color of the X; defaults to the ambient icon color.
  final Color? color;

  /// Size of the X.
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return Semantics(
      button: true,
      label: 'Close',
      excludeSemantics: child == null,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => MorphCard.close(context)),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => MorphCard.close(context),
          child:
              child ??
              SizedBox.square(
                dimension: size,
                child: CustomPaint(painter: _CrossPainter(color)),
              ),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    final a = size.width * 0.27;
    final b = size.width - a;
    canvas
      ..drawLine(Offset(a, a), Offset(b, b), paint)
      ..drawLine(Offset(b, a), Offset(a, b), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}
