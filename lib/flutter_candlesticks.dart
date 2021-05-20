import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OHLCVGraph extends StatelessWidget {
  OHLCVGraph({
    Key key,
    @required this.data,
    this.candleSpacing = 1.0,
    this.fallbackHeight = 100.0,
    this.fallbackWidth = 300.0,
    this.gridLineColor = Colors.grey,
    this.gridLineAmount = 5,
    this.gridLineWidth = 0.5,
    this.gridLineLabelColor = Colors.grey,
    this.labelPrefix = "\$",
    this.decreasePaint,
    this.increasePaint,
    this.volumePaint,
    @required this.enableGridLines,
    @required this.volumeProp,
  })  : assert(data != null),
        assert(candleSpacing != null),
        super(key: key);

  /// OHLCV data to graph
  /// List of Maps containing open, high, low, close and volumeto
  /// Example: [["open" : 40.0, "high" : 75.0, "low" : 25.0, "close" : 50.0, "volumeto" : 5000.0}, {...}]
  final List data;

  /// spacing between lines
  final double candleSpacing;

  /// Enable or disable grid lines
  final bool enableGridLines;

  /// Color of grid lines and label text
  final Color gridLineColor;
  final Color gridLineLabelColor;

  /// Number of grid lines
  final int gridLineAmount;

  /// Width of grid lines
  final double gridLineWidth;

  /// Proportion of paint to be given to volume bar graph
  final double volumeProp;

  /// If graph is given unbounded space,
  /// it will default to given fallback height and width
  final double fallbackHeight;
  final double fallbackWidth;

  /// Symbol prefix for grid line labels
  final String labelPrefix;

  /// Increasing candle paint
  final Paint increasePaint;

  /// Decreasing candle paint
  final Paint decreasePaint;

  /// Volume candle paint (defaults to Increasing/Decreasing paints if empty)
  final Paint volumePaint;

  @override
  Widget build(BuildContext context) {
    return new LimitedBox(
      maxHeight: fallbackHeight,
      maxWidth: fallbackWidth,
      child: new CustomPaint(
        size: Size.infinite,
        painter: new _OHLCVPainter(
          data,
          candleSpacing: candleSpacing,
          gridLineColor: gridLineColor,
          gridLineAmount: gridLineAmount,
          gridLineWidth: gridLineWidth,
          gridLineLabelColor: gridLineLabelColor,
          enableGridLines: enableGridLines,
          volumeProp: volumeProp,
          labelPrefix: labelPrefix,
          decreasePaint: decreasePaint ?? (new Paint()
            ..color = Colors.red
            ..strokeWidth = 1.0
            ..style = PaintingStyle.fill
          ),
          increasePaint: increasePaint ?? (new Paint()
            ..color = Colors.green
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke
          ),
          volumePaint: volumePaint
        ),
      ),
    );
  }
}

class _OHLCVPainter extends CustomPainter {
  _OHLCVPainter(
    this.data, {
    @required this.candleSpacing,
    @required this.enableGridLines,
    @required this.gridLineColor,
    @required this.gridLineAmount,
    @required this.gridLineWidth,
    @required this.gridLineLabelColor,
    @required this.volumeProp,
    @required this.labelPrefix,
    @required this.decreasePaint,
    @required this.increasePaint,
    @required this.volumePaint,
  });

  final List data;
  final double candleSpacing;
  final bool enableGridLines;
  final Color gridLineColor;
  final int gridLineAmount;
  final double gridLineWidth;
  final Color gridLineLabelColor;
  final String labelPrefix;

  final double volumeProp;

  final Paint decreasePaint;
  final Paint increasePaint;
  final Paint volumePaint;

  double _min;
  double _max;
  double _maxVolume;

  List<TextPainter> gridLineTextPainters = [];
  TextPainter maxVolumePainter;

  numCommaParse(number) {
    return number.round().toString().replaceAllMapped(
        new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
  }

  update() {
    _min = double.infinity;
    _max = -double.infinity;
    _maxVolume = -double.infinity;
    for (var i in data) {
      if (i["high"] > _max) {
        _max = i["high"].toDouble();
      }
      if (i["low"] < _min) {
        _min = i["low"].toDouble();
      }
      if (i["volumeto"] > _maxVolume) {
        _maxVolume = i["volumeto"].toDouble();
      }
    }

    if (enableGridLines) {
      double gridLineValue;
      for (int i = 0; i < gridLineAmount; i++) {
        // Label grid lines
        gridLineValue = _max - (((_max - _min) / (gridLineAmount - 1)) * i);

        String gridLineText;
        if (gridLineValue < 1) {
          gridLineText = gridLineValue.toStringAsPrecision(4);
        } else if (gridLineValue < 999) {
          gridLineText = gridLineValue.toStringAsFixed(2);
        } else {
          gridLineText = gridLineValue.round().toString().replaceAllMapped(
              new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => "${m[1]},");
        }

        gridLineTextPainters.add(new TextPainter(
            text: new TextSpan(
                text: labelPrefix + gridLineText,
                style: new TextStyle(
                    color: gridLineLabelColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold)),
            textDirection: TextDirection.ltr));
        gridLineTextPainters[i].layout();
      }

      // Label volume line
      maxVolumePainter = new TextPainter(
          text: new TextSpan(
              text: labelPrefix + numCommaParse(_maxVolume),
              style: new TextStyle(
                  color: gridLineLabelColor,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr);
      maxVolumePainter.layout();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_min == null || _max == null || _maxVolume == null) {
      update();
    }

    final double volumeHeight = size.height * volumeProp;
    final double volumeNormalizer = volumeHeight / _maxVolume;

    double width = size.width;
    final double height = size.height * (1 - volumeProp);

    double gridLineY;

    if (enableGridLines) {
      InlineSpan inlineSpan = gridLineTextPainters[0].text;
      width = size.width - inlineSpan.toPlainText().length * 6;
      Paint gridPaint = new Paint()
        ..color = gridLineColor
        ..strokeWidth = gridLineWidth;

      double gridLineDist = height / (gridLineAmount - 1);

      // Draw grid lines
      for (int i = 0; i < gridLineAmount; i++) {
        gridLineY = (gridLineDist * i).round().toDouble();
        canvas.drawLine(new Offset(0.0, gridLineY),
            new Offset(width, gridLineY), gridPaint);

        // Label grid lines
        gridLineTextPainters[i]
            .paint(canvas, new Offset(width + 2.0, gridLineY - 6.0));
      }
    }

    final double heightNormalizer = height / (_max - _min);
    final double rectWidth = width / data.length;

    double rectLeft;
    double rectTop;
    double rectRight;
    double rectBottom;

    Paint rectPaint;

    // Loop through all data
    for (int i = 0; i < data.length; i++) {
      rectLeft = (i * rectWidth);
      rectRight = ((i + 1) * rectWidth);

      double volBarTop = (height + volumeHeight) -
          (data[i]["volumeto"] * volumeNormalizer);
      double volBarBottom = height + volumeHeight;

      bool isDecreasing = (data[i]["open"] > data[i]["close"]);

      rectPaint = isDecreasing ? decreasePaint : increasePaint;

      rectTop = height - (data[i][isDecreasing ? "open" : "close"] - _min)
          * heightNormalizer;
      rectBottom = height - (data[i][isDecreasing ? "close" : "open"] - _min)
          * heightNormalizer;

      // Draw candlestick body
      var ocRect = new Rect.fromLTRB(
          rectLeft + candleSpacing, rectTop, rectRight - candleSpacing, rectBottom);
      if (rectPaint.style == PaintingStyle.stroke)
        ocRect = ocRect.deflate(rectPaint.strokeWidth/2);
      canvas.drawRect(ocRect, rectPaint);

      // Draw volume bars
      Rect volumeRect = new Rect.fromLTRB(
          rectLeft + candleSpacing, volBarTop, rectRight - candleSpacing, volBarBottom);
      if (volumePaint != null && volumePaint.style == PaintingStyle.stroke)
        volumeRect = volumeRect.deflate(volumePaint.strokeWidth/2);
      canvas.drawRect(volumeRect, volumePaint ?? rectPaint);

      // Draw low/high candlestick wicks
      double low = height - (data[i]["low"] - _min) * heightNormalizer;
      double high = height - (data[i]["high"] - _min) * heightNormalizer;
      canvas.drawLine(
          new Offset(rectLeft + (rectWidth) / 2, rectBottom),
          new Offset(rectLeft + (rectWidth) / 2, low),
          rectPaint);
      canvas.drawLine(
          new Offset(rectLeft + (rectWidth) / 2, rectTop),
          new Offset(rectLeft + (rectWidth) / 2, high),
          rectPaint);
    }

    if (enableGridLines) {
      // Label volume line
      maxVolumePainter.paint(canvas, new Offset(0.0, gridLineY + 2.0));
    }
  }

  @override
  bool shouldRepaint(_OHLCVPainter old) {
    return data != old.data ||
        candleSpacing != old.candleSpacing ||
        enableGridLines != old.enableGridLines ||
        gridLineColor != old.gridLineColor ||
        gridLineAmount != old.gridLineAmount ||
        gridLineWidth != old.gridLineWidth ||
        volumeProp != old.volumeProp ||
        gridLineLabelColor != old.gridLineLabelColor;
  }
}
