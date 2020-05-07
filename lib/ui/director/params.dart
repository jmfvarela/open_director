import 'dart:core';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class Params {
  static bool fixHeight = false;

  static double getPlayerHeight(BuildContext context) {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      return MediaQuery.of(context).size.height -
          getTimelineHeight(context) -
          (fixHeight ? 24 : 24);
    } else {
      return getPlayerWidth(context) * 9 / 16;
    }
  }

  static double getPlayerWidth(BuildContext context) {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      return getPlayerHeight(context) * 16 / 9;
    } else {
      return MediaQuery.of(context).size.width;
    }
  }

  static double getSideMenuWidth(BuildContext context) {
    return (MediaQuery.of(context).size.width - getPlayerWidth(context)) / 2;
  }

  static const double APP_BAR_HEIGHT = 56;
  static const double RULER_HEIGHT = 24;

  static double getTimelineHeight(BuildContext context) {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      return 0.4 * MediaQuery.of(context).size.height;
    } else {
      return MediaQuery.of(context).size.height -
          (getPlayerHeight(context) + APP_BAR_HEIGHT * 2 + 24);
    }
  }

  static double getLayerHeight(BuildContext context, String type) {
    if (type == "raster") {
      return math.min(
          100, (getTimelineHeight(context) - RULER_HEIGHT) / 4.5 * 2 - 2);
    } else {
      return math.min(
          50, (getTimelineHeight(context) - RULER_HEIGHT) / 4.5 - 2);
    }
  }

  static double getLayerBottom(BuildContext context) =>
      getTimelineHeight(context) -
      RULER_HEIGHT -
      getLayerHeight(context, "raster") * 2 -
      6;
}
