import 'dart:ui';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/service/director_service.dart';
import 'package:open_director/model/model.dart';
import 'package:open_director/ui/director/params.dart';
import 'package:open_director/ui/director/text_form.dart';

class TextPlayerEditor extends StatelessWidget {
  final directorService = locator.get<DirectorService>();
  final Asset _asset;

  TextPlayerEditor(this._asset);

  @override
  Widget build(BuildContext context) {
    if (_asset == null) return Container();
    var txtController = TextEditingController();
    txtController.text = _asset.title;
    Font font = Font.getByPath(_asset.font);

    return GestureDetector(
      onPanUpdate: (details) {
        if (_asset == null) return;
        // Not create clone because it is too slow
        _asset.x += details.delta.dx / Params.getPlayerWidth(context);
        _asset.y += details.delta.dy / Params.getPlayerHeight(context);
        if (_asset.x < 0) {
          _asset.x = 0;
        }
        if (_asset.x > 0.85) {
          _asset.x = 0.85;
        }
        if (_asset.y < 0) {
          _asset.y = 0;
        }
        if (_asset.y > 0.85) {
          _asset.y = 0.85;
        }
        directorService.editingTextAsset = _asset;
      },
      child: Container(
        width: Params.getPlayerWidth(context),
        child: TextField(
            controller: txtController,
            minLines: 1,
            maxLines: 1,
            autocorrect:
                false, //Doesn´t work: https://github.com/flutter/flutter/issues/22828
            decoration: InputDecoration(
              fillColor: Colors.red,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Colors.pinkAccent,
                  width: 2.0,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(0, 1, 0, 1),
              hintStyle: TextStyle(
                color: Colors.grey.shade200,
              ),
              hintText: 'Click to edit text',
            ),
            /*strutStyle: StrutStyle(
              height: 1.0,
            ),*/
            style: TextStyle(
              height: 1.0,
              fontSize: _asset.fontSize *
                  Params.getPlayerWidth(context) /
                  MediaQuery.of(context).textScaleFactor,
              fontStyle: font.style,
              fontFamily: font.family,
              fontWeight: font.weight,
              color: Color(_asset.fontColor),
              backgroundColor: Color(_asset.boxcolor),
            ),
            onChanged: (newVal) {
              directorService.editingTextAsset.title = newVal;
            }),
      ),
    );
  }
}
