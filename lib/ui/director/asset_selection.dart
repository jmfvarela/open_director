import 'dart:ui';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/service/director_service.dart';
import 'package:open_director/model/model.dart';
import 'package:open_director/ui/director/params.dart';

class AssetSelection extends StatelessWidget {
  final directorService = locator.get<DirectorService>();
  final int layerIndex;

  AssetSelection(this.layerIndex) : super();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: directorService.selected$,
        initialData: Selected(-1, -1),
        builder: (BuildContext context, AsyncSnapshot<Selected> selected) {
          Color borderColor = Colors.pinkAccent;
          double left, width;
          if (selected.data.layerIndex == layerIndex &&
              selected.data.assetIndex != -1) {
            if (directorService.isDragging || directorService.isSizerDragging) {
              borderColor = Colors.greenAccent;
            }
            Asset asset = directorService
                .layers[layerIndex].assets[selected.data.assetIndex];
            left = asset.begin * directorService.pixelsPerSecond / 1000.0 +
                selected.data.dragX +
                selected.data.incrScrollOffset;
            width = asset.duration * directorService.pixelsPerSecond / 1000.0;
            if (directorService.isSizerDragging &&
                !directorService.isSizerDraggingEnd) {
              left += directorService.dxSizerDrag;
              if (left >
                  (asset.begin + asset.duration - 1000) *
                      directorService.pixelsPerSecond /
                      1000) {
                left = (asset.begin + asset.duration - 1000) *
                    directorService.pixelsPerSecond /
                    1000;
              }
              if (left < 0) {
                left = 0;
              }
              width = (asset.begin + asset.duration) *
                      directorService.pixelsPerSecond /
                      1000 -
                  left;
            } else if (directorService.isSizerDragging) {
              width += directorService.dxSizerDrag;
              if (width < directorService.pixelsPerSecond) {
                width = directorService.pixelsPerSecond;
              }
            }
            if (left < 0) {
              left = 0;
            }
          } else {
            borderColor = Colors.transparent;
            left = -1;
            width = 0;
          }

          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + left + 1,
            child: GestureDetector(
              child: Container(
                height: Params.getLayerHeight(
                    context, directorService.layers[layerIndex].type),
                width: width,
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.25),
                  border: Border.all(width: 3, color: borderColor),
                ),
              ),
              onLongPressStart: (LongPressStartDetails details) {
                directorService.dragStart(layerIndex, selected.data.assetIndex);
              },
              onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
                directorService.dragSelected(
                    layerIndex,
                    selected.data.assetIndex,
                    details.offsetFromOrigin.dx,
                    MediaQuery.of(context).size.width);
              },
              onLongPressEnd: (LongPressEndDetails details) {
                directorService.dragEnd();
              },
            ),
          );
        });
  }
}
