import 'dart:ui';
import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/service/director_service.dart';
import 'package:open_director/model/project.dart';
import 'package:open_director/model/model.dart';
import 'package:open_director/ui/director/params.dart';
import 'package:open_director/ui/director/app_bar.dart';
import 'package:open_director/ui/director/asset_selection.dart';
import 'package:open_director/ui/director/drag_closest.dart';
import 'package:open_director/ui/director/asset_sizer.dart';
import 'package:open_director/ui/director/text_asset_editor.dart';
import 'package:open_director/ui/director/color_editor.dart';
import 'package:open_director/ui/director/text_form.dart';
import 'package:open_director/ui/director/text_player_editor.dart';
import 'package:open_director/ui/common/animated_dialog.dart';

class DirectorScreen extends StatefulWidget {
  final Project project;
  const DirectorScreen(this.project, {Key key}) : super(key: key);

  @override
  _DirectorScreen createState() => _DirectorScreen(project);
}

class _DirectorScreen extends State<DirectorScreen>
    with WidgetsBindingObserver {
  final directorService = locator.get<DirectorService>();
  StreamSubscription<bool> _dialogFilesNotExistSubscription;

  _DirectorScreen(Project project) {
    directorService.setProject(project);

    _dialogFilesNotExistSubscription =
        directorService.filesNotExist$.listen((val) {
      if (val) {
        // Delayed because widgets are building
        Future.delayed(Duration(milliseconds: 100), () {
          AnimatedDialog.show(
            context,
            title: 'Some assets have been deleted',
            child: Text(
                'To continue you must recover deleted assets in your device '
                'or remove them from the timeline (marked in red).'),
            button2Text: 'OK',
            onPressedButton2: () {
              Navigator.of(context).pop();
            },
          );
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dialogFilesNotExistSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      Params.fixHeight = true;
    } else if (state == AppLifecycleState.resumed) {
      Params.fixHeight = false;
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // To release memory
    imageCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (directorService.editingColor != null) {
          directorService.editingColor = null;
          return false;
        }
        if (directorService.editingTextAsset != null) {
          directorService.editingTextAsset = null;
          return false;
        }
        bool exit = await directorService.exitAndSaveProject();
        if (exit) Navigator.pop(context);
        return false;
      },
      child: Material(
        color: Colors.grey.shade900,
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              if (directorService.editingTextAsset == null) {
                directorService.select(-1, -1);
              }
              // Hide keyboard
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: Container(
              color: Colors.grey.shade900,
              child: _Director(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Director extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: Params.getPlayerHeight(context) +
              (MediaQuery.of(context).orientation == Orientation.landscape
                  ? 0
                  : Params.APP_BAR_HEIGHT * 2),
          child: MediaQuery.of(context).orientation == Orientation.landscape
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                      AppBar1(),
                      _Video(),
                      AppBar2(),
                    ])
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                      AppBar1(),
                      _Video(),
                      AppBar2(),
                    ]),
        ),
        Stack(
          alignment: const Alignment(0, -1),
          children: <Widget>[
            SingleChildScrollView(
              child: Stack(
                alignment: const Alignment(-1, -1),
                children: <Widget>[
                  Container(
                    child: GestureDetector(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollState) {
                          if (scrollState is ScrollEndNotification) {
                            directorService.endScroll();
                          }
                          return false;
                        },
                        child: _TimeLine(),
                      ),
                      onScaleStart: (ScaleStartDetails details) {
                        directorService.scaleStart();
                      },
                      onScaleUpdate: (ScaleUpdateDetails details) {
                        directorService.scaleUpdate(details.horizontalScale);
                      },
                      onScaleEnd: (ScaleEndDetails details) {
                        directorService.scaleEnd();
                      },
                    ),
                  ),
                  _LayerHeaders(),
                ],
              ),
            ),
            _PositionLine(),
            _PositionMarker(),
            TextAssetEditor(),
            ColorEditor(),
          ],
        ),
      ],
    );
  }
}

class _PositionLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 2,
        height: Params.getTimelineHeight(context) - 4,
        margin: EdgeInsets.fromLTRB(0, 2, 0, 2),
        color: Colors.grey.shade100);
  }
}

class _PositionMarker extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: Params.RULER_HEIGHT - 4,
      margin: EdgeInsets.fromLTRB(0, 2, 0, 2),
      color: Colors.blue,
      child: StreamBuilder(
          stream: directorService.position$,
          initialData: 0,
          builder: (BuildContext context, AsyncSnapshot<int> position) {
            return Center(
                child: Text(
                    '${directorService.positionMinutes}:${directorService.positionSeconds}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    )));
          }),
    );
  }
}

class _TimeLine extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: directorService.layersChanged$,
        initialData: false,
        builder: (BuildContext context, AsyncSnapshot<bool> layersChanged) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: directorService.scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Ruler(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: directorService.layers
                      .asMap()
                      .map((index, layer) =>
                          MapEntry(index, _LayerAssets(index)))
                      .values
                      .toList(),
                ),
                Container(
                  height: Params.getLayerBottom(context),
                ),
              ],
            ),
          );
        });
  }
}

class _Ruler extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RulerPainter(context),
      child: Container(
        height: Params.RULER_HEIGHT - 4,
        width: MediaQuery.of(context).size.width +
            directorService.pixelsPerSecond * directorService.duration / 1000,
        margin: EdgeInsets.fromLTRB(0, 2, 0, 2),
      ),
    );
  }
}

class RulerPainter extends CustomPainter {
  final directorService = locator.get<DirectorService>();
  final BuildContext context;

  RulerPainter(this.context);

  getSecondsPerDivision(double pixPerSec) {
    if (pixPerSec > 40) {
      return 1;
    } else if (pixPerSec > 20) {
      return 2;
    } else if (pixPerSec > 10) {
      return 5;
    } else if (pixPerSec > 4) {
      return 10;
    } else if (pixPerSec > 1.5) {
      return 30;
    } else {
      return 60;
    }
  }

  getTimeText(int seconds) {
    return '${(seconds / 60).floor() < 10 ? '0' : ''}'
        '${(seconds / 60).floor()}'
        '.${seconds - (seconds / 60).floor() * 60 < 10 ? '0' : ''}'
        '${seconds - (seconds / 60).floor() * 60}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double width =
        directorService.duration / 1000 * directorService.pixelsPerSecond +
            MediaQuery.of(context).size.width;

    final paint = Paint();
    paint.color = Colors.grey.shade800;
    Rect rect = Rect.fromLTWH(0, 2, width, size.height - 4);
    canvas.drawRect(rect, paint);

    paint.color = Colors.grey.shade400;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    Path path = Path();
    path.moveTo(0, size.height - 2);
    path.relativeLineTo(width, 0);
    path.close();
    canvas.drawPath(path, paint);

    int secondsPerDivision =
        getSecondsPerDivision(directorService.pixelsPerSecond);
    final double pixelsPerDivision =
        secondsPerDivision * directorService.pixelsPerSecond;
    final int numberOfDivisions =
        ((width - MediaQuery.of(context).size.width / 2) / pixelsPerDivision)
            .floor();

    for (int i = 0; i <= numberOfDivisions; i++) {
      int seconds = i * secondsPerDivision;
      String text = getTimeText(seconds);

      final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
          ),
        ),
      );

      textPainter.layout();
      double x = MediaQuery.of(context).size.width / 2 + i * pixelsPerDivision;
      textPainter.paint(canvas, Offset(x + 6, 6));

      Path path = Path();
      path.moveTo(x + 1, size.height - 4);
      path.relativeLineTo(0, -8);
      path.moveTo(x + 1 + 0.5 * pixelsPerDivision, size.height - 4);
      path.relativeLineTo(0, -2);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _LayerHeaders extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: Params.RULER_HEIGHT - 4,
          width: 33,
          color: Colors.transparent,
          margin: EdgeInsets.fromLTRB(0, 2, 0, 2),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: directorService.layers
              .asMap()
              .map((index, layer) => MapEntry(index, _LayerHeader(layer.type)))
              .values
              .toList(),
        ),
      ],
    );
  }
}

class _Video extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: directorService.position$,
        builder: (BuildContext context, AsyncSnapshot<int> position) {
          var backgroundContainer = Container(
            color: Colors.black,
            height: Params.getPlayerHeight(context),
            width: Params.getPlayerWidth(context),
          );
          if (directorService.layerPlayers == null ||
              directorService.layerPlayers.length == 0) {
            return backgroundContainer;
          }
          int assetIndex = directorService.layerPlayers[0].currentAssetIndex;
          if (assetIndex == -1 ||
              assetIndex >= directorService.layers[0].assets.length) {
            return backgroundContainer;
          }
          AssetType type = directorService.layers[0].assets[assetIndex].type;
          return Container(
            height: Params.getPlayerHeight(context),
            width: Params.getPlayerWidth(context),
            child: Stack(
              children: [
                backgroundContainer,
                (type == AssetType.video)
                    ? VideoPlayer(
                        directorService.layerPlayers[0].videoController)
                    : _ImagePlayer(
                        directorService.layers[0].assets[assetIndex]),
                _TextPlayer(),
              ],
            ),
          );
        });
  }
}

class _ImagePlayer extends StatelessWidget {
  final directorService = locator.get<DirectorService>();
  final Asset asset;

  _ImagePlayer(this.asset) : super();

  @override
  Widget build(BuildContext context) {
    if (asset.deleted) return Container();
    return StreamBuilder(
        stream: directorService.position$,
        initialData: 0,
        builder: (BuildContext context, AsyncSnapshot<int> position) {
          int assetIndex = directorService.layerPlayers[0].currentAssetIndex;
          double ratio = (directorService.position -
                  directorService.layers[0].assets[assetIndex].begin) /
              directorService.layers[0].assets[assetIndex].duration;
          if (ratio < 0) ratio = 0;
          if (ratio > 1) ratio = 1;
          return KenBurnEffect(
            asset.thumbnailMedPath ?? asset.srcPath,
            ratio,
            zSign: asset.kenBurnZSign,
            xTarget: asset.kenBurnXTarget,
            yTarget: asset.kenBurnYTarget,
          );
        });
  }
}

class KenBurnEffect extends StatelessWidget {
  final String path;
  final double ratio;
  // Effect configuration
  final int zSign;
  final double xTarget;
  final double yTarget;

  KenBurnEffect(
    this.path,
    this.ratio, {
    this.zSign = 0, // Options: {-1, 0, +1}
    this.xTarget = 0, // Options: {0, 0.5, 1}
    this.yTarget = 0, // Options; {0, 0.5, 1}
  }) : super();

  @override
  Widget build(BuildContext context) {
    // Start and end positions
    double xStart = (zSign == 1) ? 0 : (0.5 - xTarget);
    double xEnd =
        (zSign == 1) ? (0.5 - xTarget) : ((zSign == -1) ? 0 : (xTarget - 0.5));
    double yStart = (zSign == 1) ? 0 : (0.5 - yTarget);
    double yEnd =
        (zSign == 1) ? (0.5 - yTarget) : ((zSign == -1) ? 0 : (yTarget - 0.5));
    double zStart = (zSign == 1) ? 0 : 1;
    double zEnd = (zSign == -1) ? 0 : 1;

    // Interpolation
    double x = xStart * (1 - ratio) + xEnd * ratio;
    double y = yStart * (1 - ratio) + yEnd * ratio;
    double z = zStart * (1 - ratio) + zEnd * ratio;

    return LayoutBuilder(builder: (context, constraints) {
      return ClipRect(
        child: Transform.translate(
          offset: Offset(x * 0.2 * Params.getPlayerWidth(context),
              y * 0.2 * Params.getPlayerHeight(context)),
          child: Transform.scale(
            scale: 1 + z * 0.2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(path)),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _TextPlayer extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: directorService.editingTextAsset$,
        initialData: null,
        builder: (BuildContext context, AsyncSnapshot<Asset> editingTextAsset) {
          Asset _asset = editingTextAsset.data;
          if (_asset == null) {
            _asset = directorService.getAssetByPosition(1);
          }
          if (_asset == null || _asset.type != AssetType.text) {
            return Container();
          }
          Font font = Font.getByPath(_asset.font);
          return Positioned(
            left: _asset.x * Params.getPlayerWidth(context),
            top: _asset.y * Params.getPlayerHeight(context),
            child: Container(
              child: (directorService.editingTextAsset == null)
                  ? Text(
                      _asset.title,
                      /*strutStyle: StrutStyle(
                        fontSize: _asset.fontSize *
                            Params.getPlayerWidth(context) /
                            MediaQuery.of(context).textScaleFactor,
                        fontStyle: font.style,
                        fontFamily: font.family,
                        fontWeight: font.weight,
                        height: 1,
                        leading: 0.0,
                      ),*/
                      style: TextStyle(
                        height: 1,
                        fontSize: _asset.fontSize *
                            Params.getPlayerWidth(context) /
                            MediaQuery.of(context).textScaleFactor,
                        fontStyle: font.style,
                        fontFamily: font.family,
                        fontWeight: font.weight,
                        color: Color(_asset.fontColor),
                        backgroundColor: Color(_asset.boxcolor),
                      ),
                    )
                  : TextPlayerEditor(editingTextAsset.data),
            ),
          );
        });
  }
}

class _LayerHeader extends StatelessWidget {
  final String type;
  _LayerHeader(this.type) : super();

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Icon(
          type == "raster"
              ? Icons.photo
              : type == "vector" ? Icons.text_fields : Icons.music_note,
          color: Colors.white,
          size: 16,
        ),
        height: Params.getLayerHeight(context, type),
        width: 28.0,
        margin: EdgeInsets.fromLTRB(0, 1, 1, 1),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
        ));
  }
}

class _LayerAssets extends StatelessWidget {
  final directorService = locator.get<DirectorService>();
  final int layerIndex;
  _LayerAssets(this.layerIndex) : super();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: const Alignment(0, 0),
      children: [
        Container(
          height: Params.getLayerHeight(
              context, directorService.layers[layerIndex].type),
          margin: EdgeInsets.all(1),
          child: Row(
            children: [
              // Half left screen in blank
              Container(width: MediaQuery.of(context).size.width / 2),

              Row(
                children: directorService.layers[layerIndex].assets
                    .asMap()
                    .map((assetIndex, asset) => MapEntry(
                          assetIndex,
                          _Asset(layerIndex, assetIndex),
                        ))
                    .values
                    .toList(),
              ),
              Container(
                width: MediaQuery.of(context).size.width / 2 - 2,
              ),
            ],
          ),
        ),
        AssetSelection(layerIndex),
        AssetSizer(layerIndex, false),
        AssetSizer(layerIndex, true),
        (layerIndex != 1) ? DragClosest(layerIndex) : Container(),
      ],
    );
  }
}

class _Asset extends StatelessWidget {
  final directorService = locator.get<DirectorService>();
  final int layerIndex;
  final int assetIndex;
  _Asset(this.layerIndex, this.assetIndex) : super();
  @override
  Widget build(BuildContext context) {
    Asset asset = directorService.layers[layerIndex].assets[assetIndex];
    Color backgroundColor = Colors.transparent;
    Color borderColor = Colors.transparent;
    Color textColor = Colors.transparent;
    Color backgroundTextColor = Colors.transparent;
    if (asset.deleted) {
      backgroundColor = Colors.red.shade200;
      borderColor = Colors.red;
      textColor = Colors.red.shade900;
    } else if (layerIndex == 0) {
      backgroundColor = Colors.blue.shade200;
      borderColor = Colors.blue;
      textColor = Colors.white;
      backgroundTextColor = Colors.black.withOpacity(0.5);
    } else if (layerIndex == 1 && asset.title != '') {
      backgroundColor = Colors.blue.shade200;
      borderColor = Colors.blue;
      textColor = Colors.blue.shade900;
    } else if (layerIndex == 2) {
      backgroundColor = Colors.orange.shade200;
      borderColor = Colors.orange;
      textColor = Colors.orange.shade900;
    }
    return GestureDetector(
      child: Container(
        height: Params.getLayerHeight(
            context, directorService.layers[layerIndex].type),
        child: Text(
          asset.title,
          style: TextStyle(
              color: textColor,
              fontSize: 12,
              backgroundColor: backgroundTextColor,
              shadows: <Shadow>[
                Shadow(
                    color: Colors.black,
                    offset: (layerIndex == 0) ? Offset(1, 1) : Offset(0, 0))
              ]),
        ),
        width: asset.duration * directorService.pixelsPerSecond / 1000.0,
        padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(width: 2, color: borderColor),
            bottom: BorderSide(width: 2, color: borderColor),
            left: BorderSide(
                width: (assetIndex == 0) ? 1 : 0, color: borderColor),
            right: BorderSide(width: 1, color: borderColor),
          ),
          image: (!asset.deleted &&
                  asset.thumbnailPath != null &&
                  !directorService.isGenerating)
              ? DecorationImage(
                  image: FileImage(File(asset.thumbnailPath)),
                  fit: BoxFit.cover,
                  alignment: Alignment.topLeft,
                  //repeat: ImageRepeat.repeatX // Doesn't work with fitHeight
                )
              : null,
        ),
      ),
      onTap: () => directorService.select(layerIndex, assetIndex),
      onLongPressStart: (LongPressStartDetails details) {
        directorService.dragStart(layerIndex, assetIndex);
      },
      onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
        directorService.dragSelected(layerIndex, assetIndex,
            details.offsetFromOrigin.dx, MediaQuery.of(context).size.width);
      },
      onLongPressEnd: (LongPressEndDetails details) {
        directorService.dragEnd();
      },
    );
  }
}
