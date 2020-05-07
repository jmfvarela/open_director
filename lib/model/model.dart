import 'package:flutter/foundation.dart';

class Layer {
  String type; // TODO: enums
  List<Asset> assets;
  double volume;
  Layer({@required this.type, this.assets, this.volume}) {
    assets = List<Asset>();
  }

  Layer.clone(Layer layer) {
    this.type = layer.type;
    this.assets = layer.assets.map((asset) => Asset.clone(asset)).toList();
    this.volume = layer.volume;
  }

  Layer.fromJson(Map<String, dynamic> map)
      : type = map['type'],
        assets = List<Asset>.from(
            map['assets'].map((json) => Asset.fromJson(json)).toList()),
        volume = map['volume'];

  Map<String, dynamic> toJson() => {
        'type': type,
        'assets': assets.map((asset) => asset.toJson()).toList(),
        'volume': volume,
      };
}

enum AssetType {
  video,
  image,
  text,
  audio,
}

class Asset {
  AssetType type;
  String srcPath;
  String thumbnailPath;
  String thumbnailMedPath;
  String title;
  int duration;
  int begin;
  int cutFrom;

  int kenBurnZSign;
  double kenBurnXTarget;
  double kenBurnYTarget;
  double x;
  double y;
  String font;
  double fontSize;
  int fontColor;
  double alpha;
  double borderw;
  int bordercolor;
  int shadowcolor;
  double shadowx;
  double shadowy;
  bool box;
  double boxborderw;
  int boxcolor;
  bool deleted;

  Asset({
    @required this.type,
    @required this.srcPath,
    this.thumbnailPath,
    this.thumbnailMedPath,
    @required this.title,
    @required this.duration,
    @required this.begin,
    this.cutFrom = 0,
    this.kenBurnZSign = 0,
    this.kenBurnXTarget = 0.5,
    this.kenBurnYTarget = 0.5,
    this.x = 0.1,
    this.y = 0.1,
    this.font = 'Lato/Lato-Regular.ttf',
    this.fontSize = 0.1,
    this.fontColor = 0xFFFFFFFF,
    this.alpha = 1,
    this.borderw = 0,
    this.bordercolor = 0xFFFFFFFF,
    this.shadowcolor = 0xFFFFFFFF,
    this.shadowx = 0,
    this.shadowy = 0,
    this.box = false,
    this.boxborderw = 0,
    this.boxcolor = 0x88000000,
    this.deleted = false,
  });

  Asset.clone(Asset asset) {
    this.type = asset.type;
    this.srcPath = asset.srcPath;
    this.thumbnailPath = asset.thumbnailPath;
    this.thumbnailMedPath = asset.thumbnailMedPath;
    this.title = asset.title;
    this.duration = asset.duration;
    this.begin = asset.begin;
    this.cutFrom = asset.cutFrom;
    this.kenBurnZSign = asset.kenBurnZSign;
    this.kenBurnXTarget = asset.kenBurnXTarget;
    this.kenBurnYTarget = asset.kenBurnYTarget;
    this.x = asset.x;
    this.y = asset.y;
    this.font = asset.font;
    this.fontSize = asset.fontSize;
    this.fontColor = asset.fontColor;
    this.alpha = asset.alpha;
    this.borderw = asset.borderw;
    this.bordercolor = asset.bordercolor;
    this.shadowcolor = asset.shadowcolor;
    this.shadowx = asset.shadowx;
    this.shadowy = asset.shadowy;
    this.box = asset.box;
    this.boxborderw = asset.boxborderw;
    this.boxcolor = asset.boxcolor;
    this.deleted = asset.deleted;
  }

  Asset.fromJson(Map<String, dynamic> map)
      : type = getAssetTypeFromString(map['type']),
        srcPath = map['srcPath'],
        thumbnailPath = map['thumbnailPath'],
        thumbnailMedPath = map['thumbnailMedPath'],
        title = map['title'],
        duration = map['duration'],
        begin = map['begin'],
        cutFrom = map['cutFrom'],
        kenBurnZSign = map['kenBurnZSign'],
        kenBurnXTarget = map['kenBurnXTarget'],
        kenBurnYTarget = map['kenBurnYTarget'],
        x = map['x'],
        y = map['y'],
        font = map['font'],
        fontSize = map['fontSize'],
        fontColor = map['fontColor'],
        alpha = map['alpha'],
        borderw = map['borderw'],
        bordercolor = map['bordercolor'],
        shadowcolor = map['shadowcolor'],
        shadowx = map['shadowx'],
        shadowy = map['shadowy'],
        box = map['box'],
        boxborderw = map['boxborderw'],
        boxcolor = map['boxcolor'],
        deleted = map['deleted'];

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'srcPath': srcPath,
        'thumbnailPath': thumbnailPath,
        'thumbnailMedPath': thumbnailMedPath,
        'title': title,
        'duration': duration,
        'begin': begin,
        'cutFrom': cutFrom,
        'kenBurnZSign': kenBurnZSign,
        'kenBurnXTarget': kenBurnXTarget,
        'kenBurnYTarget': kenBurnYTarget,
        'x': x,
        'y': y,
        'font': font,
        'fontSize': fontSize,
        'fontColor': fontColor,
        'alpha': alpha,
        'borderw': borderw,
        'bordercolor': bordercolor,
        'shadowcolor': shadowcolor,
        'shadowx': shadowx,
        'shadowy': shadowy,
        'box': box,
        'boxborderw': boxborderw,
        'boxcolor': boxcolor,
        'deleted': deleted,
      };

  static AssetType getAssetTypeFromString(String assetTypeAsString) {
    for (AssetType element in AssetType.values) {
      if (element.toString() == assetTypeAsString) {
        return element;
      }
    }
    return null;
  }
}

class Selected {
  int layerIndex;
  int assetIndex;
  double initScrollOffset;
  double incrScrollOffset;
  double dragX;
  int closestAsset;
  Selected(this.layerIndex, this.assetIndex,
      {this.dragX = 0,
      this.closestAsset = -1,
      this.initScrollOffset = 0,
      this.incrScrollOffset = 0});

  bool isSelected(int layerIndex, int assetIndex) {
    return (layerIndex == this.layerIndex && assetIndex == this.assetIndex);
  }
}
