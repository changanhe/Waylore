import 'i18n.dart';

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'store.dart';

Future<ui.Image> decodePoster(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width < 40 ||
        descriptor.height < 40 ||
        descriptor.width * descriptor.height > 100000000) {
      throw const FormatException('图片尺寸不可用');
    }
    final scale = math.min(
      1.0,
      2400 / math.max(descriptor.width, descriptor.height),
    );
    final codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round(),
      targetHeight: (descriptor.height * scale).round(),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

Rect posterCropRect(
  Size source, {
  Offset offset = Offset.zero,
  double zoom = 1,
}) {
  const ratio = 2 / 3;
  var w = source.width, h = source.height;
  if (w / h > ratio) {
    w = h * ratio;
  } else {
    h = w / ratio;
  }
  w /= zoom.clamp(1, 2.5);
  h /= zoom.clamp(1, 2.5);
  final x = (source.width - w) * (offset.dx.clamp(-1, 1) + 1) / 2;
  final y = (source.height - h) * (offset.dy.clamp(-1, 1) + 1) / 2;
  return Rect.fromLTWH(x, y, w, h);
}

void paintPoster(
  Canvas canvas,
  Size target,
  ui.Image image, {
  required bool fill,
  required Offset offset,
  double zoom = 1,
}) {
  final size = Size(image.width.toDouble(), image.height.toDouble());
  canvas.drawRect(
    Offset.zero & target,
    Paint()..color = const Color(0xff202925),
  );
  final src = fill
      ? posterCropRect(size, offset: offset, zoom: zoom)
      : Offset.zero & size;
  final fitted = applyBoxFit(BoxFit.contain, src.size, target);
  final dst = Alignment.center.inscribe(
    fitted.destination,
    Offset.zero & target,
  );
  canvas.drawImageRect(
    image,
    src,
    dst,
    Paint()..filterQuality = FilterQuality.high,
  );
}

Future<String> keepPoster(
  ui.Image image, {
  required bool fill,
  required Offset offset,
  double zoom = 1,
}) async {
  final src = fill
      ? posterCropRect(
          Size(image.width.toDouble(), image.height.toDouble()),
          offset: offset,
          zoom: zoom,
        )
      : Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
  // Do not manufacture detail by upscaling a small source. Keep portrait 2:3 output.
  final width = math
      .min(1200, (fill ? src.width : math.max(src.width, src.height * 2 / 3)))
      .floor()
      .clamp(1, 1200);
  final size = Size(width.toDouble(), (width * 1.5).roundToDouble());
  final recorder = ui.PictureRecorder();
  paintPoster(
    Canvas(recorder),
    size,
    image,
    fill: fill,
    offset: offset,
    zoom: zoom,
  );
  final picture = recorder.endRecording();
  ui.Image? rendered;
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/poster-${JournalStore.newId()}.png');
  try {
    rendered = await picture.toImage(size.width.toInt(), size.height.toInt());
    final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw const FormatException('海报编码失败');
    await file.writeAsBytes(data.buffer.asUint8List());
    return await JournalStore.keepPhoto(file.path);
  } finally {
    rendered?.dispose();
    picture.dispose();
    if (await file.exists()) await file.delete();
  }
}

class PosterCropChoice {
  final bool fill;
  final Offset offset;
  final double zoom;
  const PosterCropChoice(this.fill, this.offset, this.zoom);
}

class PosterCropSheet extends StatefulWidget {
  final ui.Image image;
  final String title;
  const PosterCropSheet({super.key, required this.image, required this.title});
  @override
  State<PosterCropSheet> createState() => _PosterCropSheetState();
}

class _PosterCropSheetState extends State<PosterCropSheet> {
  late final ui.Image displayImage = widget.image.clone();
  @override
  void dispose() {
    displayImage.dispose();
    super.dispose();
  }

  late bool fill =
      widget.image.width / widget.image.height > .52 &&
      widget.image.width / widget.image.height < .88;
  Offset offset = Offset.zero;
  double zoom = 1;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .88,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: LocalText(
                      '调整海报封面',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '取消',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              SizedBox(
                height: (MediaQuery.sizeOf(context).height * .42).clamp(
                  100,
                  420,
                ),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: GestureDetector(
                    onPanUpdate: fill
                        ? (details) => setState(
                            () => offset = Offset(
                              (offset.dx - details.delta.dx / 100).clamp(-1, 1),
                              (offset.dy - details.delta.dy / 140).clamp(-1, 1),
                            ),
                          )
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: _PosterPainter(
                          displayImage,
                          fill,
                          offset,
                          zoom,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: LocalText('填满封面')),
                  ButtonSegment(value: false, label: LocalText('保留全图')),
                ],
                selected: {fill},
                onSelectionChanged: (s) => setState(() => fill = s.first),
              ),
              if (fill)
                Slider(
                  value: zoom,
                  min: 1,
                  max: 2.5,
                  label: '${zoom.toStringAsFixed(1)}×',
                  onChanged: (v) => setState(() => zoom = v),
                ),
              LocalText(
                '${widget.image.width} × ${widget.image.height} · ${tr(fill ? '拖动调整位置' : '保留完整海报')}',
                style: const TextStyle(fontSize: 11),
              ),
              if (widget.image.width < 600)
                const Text('当前来源分辨率较低，可返回选择其他来源。', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    PosterCropChoice(fill, offset, zoom),
                  ),
                  icon: const Icon(Icons.check),
                  label: const LocalText('使用这张海报'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PosterPainter extends CustomPainter {
  final ui.Image image;
  final bool fill;
  final Offset offset;
  final double zoom;
  _PosterPainter(this.image, this.fill, this.offset, this.zoom);
  @override
  void paint(Canvas canvas, Size size) =>
      paintPoster(canvas, size, image, fill: fill, offset: offset, zoom: zoom);
  @override
  bool shouldRepaint(_PosterPainter old) =>
      old.image != image ||
      old.fill != fill ||
      old.offset != offset ||
      old.zoom != zoom;
}
