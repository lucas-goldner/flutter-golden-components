import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pixel ratio goldens are captured at.
const double kGoldenPixelRatio = 2;

/// Captures the [RepaintBoundary] under [key] as an image.
Future<ui.Image> captureBoundary(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  return (await tester.runAsync(() => boundary.toImage(pixelRatio: kGoldenPixelRatio)))!;
}

/// Stacks [images] vertically (or horizontally) into one sheet and compares
/// it against the golden [file].
Future<void> expectSheet(
  WidgetTester tester,
  List<ui.Image> images,
  String file, {
  Axis axis = Axis.vertical,
}) async {
  final sheet = (await tester.runAsync(() => _compose(images, axis)))!;
  await expectLater(sheet, matchesGoldenFile(file));
  sheet.dispose();
  for (final image in images) {
    image.dispose();
  }
}

Future<ui.Image> _compose(List<ui.Image> images, Axis axis) {
  const gap = 8.0 * kGoldenPixelRatio;
  final vertical = axis == Axis.vertical;
  var width = 0.0;
  var height = 0.0;
  for (final image in images) {
    if (vertical) {
      width = width < image.width ? image.width.toDouble() : width;
      height += image.height;
    } else {
      height = height < image.height ? image.height.toDouble() : height;
      width += image.width;
    }
  }
  if (vertical) {
    height += gap * (images.length - 1);
  } else {
    width += gap * (images.length - 1);
  }
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = const Color(0xFF26262B));
  var offset = 0.0;
  for (final image in images) {
    canvas.drawImage(image, vertical ? Offset(0, offset) : Offset(offset, 0), Paint());
    offset += (vertical ? image.height : image.width) + gap;
  }
  return recorder.endRecording().toImage(width.round(), height.round());
}

/// Advances time in 16 ms frames, as at 60 fps.
Future<void> advance(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 16);
  var left = total;
  while (left > Duration.zero) {
    final d = left < step ? left : step;
    await tester.pump(d);
    left -= d;
  }
}
