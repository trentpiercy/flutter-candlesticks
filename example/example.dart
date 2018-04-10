import 'package:flutter/material.dart';
import 'package:flutter_candlesticks/flutter_candlesticks.dart';

void main() {
  List singleSample = [
    {"open":50.0, "high":100.0, "low":40.0, "close":80, "volumeto":5000.0},
    {"open":80.0, "high":90.0, "low":55.0, "close":65, "volumeto":4000.0},
    {"open":65.0, "high":120.0, "low":60.0, "close":90, "volumeto":7000.0},
    {"open":90.0, "high":95.0, "low":85.0, "close":80, "volumeto":2000.0},
    {"open":80.0, "high":85.0, "low":40.0, "close":50, "volumeto":3000.0},
  ];

  List sampleData = singleSample*10;

  runApp(
    new MaterialApp(
      home: new Center(
        child: new Container(
          height: 500.0,
          child: new OHLCVGraph(
            data: sampleData,
            enableGridLines: false,
            volumeProp: 0.2
          ),
        ),
      ),
    )
  );
}