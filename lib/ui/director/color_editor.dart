import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/service/director_service.dart';
import 'package:open_director/ui/director/params.dart';
import 'package:open_director/model/model.dart';

class ColorEditor extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: directorService.editingColor$,
        initialData: null,
        builder: (BuildContext context, AsyncSnapshot<String> editingColor) {
          if (editingColor.data == null) return Container();
          return Container(
            height: Params.getTimelineHeight(context),
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border(
                top: BorderSide(width: 2, color: Colors.blue),
              ),
            ),
            child: ColorForm(),
          );
        });
  }
}

class ColorForm extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    int fontColor = 0;
    if (directorService.editingColor == 'fontColor') {
      fontColor = directorService.editingTextAsset?.fontColor;
    } else if (directorService.editingColor == 'boxcolor') {
      fontColor = directorService.editingTextAsset?.boxcolor;
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: MediaQuery.of(context).size.width - 130,
        child: Wrap(
          children: [
            Container(
              height:
                  (MediaQuery.of(context).orientation == Orientation.landscape)
                      ? 116
                      : 320,
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: ColorPicker(
                pickerColor: Color(fontColor),
                paletteType: PaletteType.hsv,
                enableLabel: false,
                enableAlpha: true,
                colorPickerWidth: 240,
                pickerAreaHeightPercent: 0.8,
                onColorChanged: (color) {
                  Asset newAsset =
                      Asset.clone(directorService.editingTextAsset);
                  if (directorService.editingColor == 'fontColor') {
                    newAsset.fontColor = color.value;
                  } else if (directorService.editingColor == 'boxcolor') {
                    newAsset.boxcolor = color.value;
                  }
                  directorService.editingTextAsset = newAsset;
                },
              ),
            ),
          ],
        ),
      ),
      Container(
        child: Column(children: <Widget>[
          RaisedButton(
            child: Text('SELECT'),
            onPressed: () {
              directorService.editingColor = null;
            },
          ),
        ]),
      ),
    ]);
  }
}
