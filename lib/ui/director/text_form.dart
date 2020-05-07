import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/service/director_service.dart';
import 'package:open_director/model/model.dart';

class TextForm extends StatelessWidget {
  final directorService = locator.get<DirectorService>();
  final Asset _asset;

  TextForm(this._asset) : super();

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SubMenu(),
      Container(
        width: MediaQuery.of(context).size.width - 120,
        child: Wrap(
          spacing: 0.0,
          runSpacing: 0.0,
          children: [
            _FontFamily(_asset),
            _FontSize(_asset),
            _ColorField(label: 'Color', field: 'fontColor', color: _asset.fontColor, size: 110),
            _ColorField(label: 'Box color', field: 'boxcolor', color: _asset.boxcolor, size: 140),
          ],
        ),
      ),
    ]);
  }
}

class _SubMenu extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      margin: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          IconButton(
            icon: Icon(Icons.text_format, color: Colors.white),
            onPressed: () {},
          ), /*
          IconButton(
            icon: Icon(Icons.aspect_ratio, color: Colors.grey.shade500),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings_brightness, color: Colors.grey.shade500),
            onPressed: () {},
          ), */
        ],
      ),
    );
  }
}

class _FontFamily extends StatelessWidget {
  final directorService = locator.get<DirectorService>();
  final Asset _asset;

  _FontFamily(this._asset);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      child: Row(children: [
        Text('Font:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100)),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
        DropdownButton(
          value: (directorService.editingTextAsset != null)
              ? Font.getByPath(directorService.editingTextAsset.font)
              : Font.allFonts[0],
          items: Font.allFonts
              .map((Font font) => DropdownMenuItem(
                  value: font,
                  child: Text(
                    font.title,
                    style: TextStyle(
                      fontFamily: font.family,
                      fontSize: 14 / MediaQuery.of(context).textScaleFactor,
                      fontStyle: font.style,
                      fontWeight: font.weight,
                    ),
                  )))
              .toList(),
          onChanged: (font) {
            Asset newAsset = Asset.clone(_asset);
            newAsset.font = font.path;
            directorService.editingTextAsset = newAsset;
          },
        ),
      ]),
    );
  }
}

class _FontSize extends StatelessWidget {
  final directorService = locator.get<DirectorService>();
  final Asset _asset;

  _FontSize(this._asset);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 235,
      child: Row(children: [
        Text('Size:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100)),
        Slider(
          min: 0.03,
          max: 1,
          value: math.sqrt(_asset?.fontSize ?? 1),
          onChanged: (size) {
            Asset newAsset = Asset.clone(_asset);
            newAsset.fontSize = size;
            directorService.editingTextAsset = newAsset;
          },
        ),
      ]),
    );
  }
}

class _ColorField extends StatelessWidget {
  final directorService = locator.get<DirectorService>();
  final String label;
  final String field;
  final int color;
  final double size;

  _ColorField({this.label = 'Color', this.field, this.color = 0, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      child: Row(children: <Widget>[
        Text('$label:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100)),
        IconButton(
          icon: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                  color: Color(color),
                  border: Border.all(
                    color: Colors.grey.shade500,
                    width: 1,
                  ))),
          onPressed: () {
            directorService.editingColor = field;
          },
        ),
      ]),
    );
  }
}

class Font {
  String title;
  String family;
  FontWeight weight;
  FontStyle style;
  String path;

  Font({
    this.title,
    this.family,
    this.weight = FontWeight.w400,
    this.style = FontStyle.normal,
    this.path,
  });

  static Font getByPath(String path) {
    return allFonts.firstWhere((font) => font.path == path);
  }

  static List<Font> allFonts = [
    Font(
        title: 'Amaranth bold',
        family: 'Amaranth',
        weight: FontWeight.w700,
        path: 'Amaranth/Amaranth-Bold.ttf'),
    Font(
        title: 'Amaranth bold italic',
        family: 'Amaranth',
        style: FontStyle.italic,
        weight: FontWeight.w700,
        path: 'Amaranth/Amaranth-BoldItalic.ttf'),
    Font(
        title: 'Amaranth  italic',
        family: 'Amaranth',
        style: FontStyle.italic,
        weight: FontWeight.w400,
        path: 'Amaranth/Amaranth-Italic.ttf'),
    Font(
        title: 'Amaranth regular',
        family: 'Amaranth',
        weight: FontWeight.w400,
        path: 'Amaranth/Amaranth-Regular.ttf'),
    Font(
        title: 'Bangers regular',
        family: 'Bangers',
        weight: FontWeight.w400,
        path: 'Bangers/Bangers-Regular.ttf'),
    Font(
        title: 'CarterOne regular',
        family: 'CarterOne',
        weight: FontWeight.w400,
        path: 'Carter_One/CarterOne-Regular.ttf'),
    Font(
        title: 'Chilanka regular',
        family: 'Chilanka',
        weight: FontWeight.w400,
        path: 'Chilanka/Chilanka-Regular.ttf'),
    Font(
        title: 'Courgette regular',
        family: 'Courgette',
        weight: FontWeight.w400,
        path: 'Courgette/Courgette-Regular.ttf'),
    Font(
        title: 'DancingScript bold',
        family: 'DancingScript',
        weight: FontWeight.w700,
        path: 'Dancing_Script/DancingScript-Bold.ttf'),
    Font(
        title: 'DancingScript regular',
        family: 'DancingScript',
        weight: FontWeight.w400,
        path: 'Dancing_Script/DancingScript-Regular.ttf'),
    Font(
        title: 'GochiHand regular',
        family: 'GochiHand',
        weight: FontWeight.w400,
        path: 'Gochi_Hand/GochiHand-Regular.ttf'),
    Font(
        title: 'Grenze black',
        family: 'Grenze',
        weight: FontWeight.w900,
        path: 'Grenze/Grenze-Black.ttf'),
    Font(
        title: 'Grenze black italic',
        family: 'Grenze',
        style: FontStyle.italic,
        weight: FontWeight.w900,
        path: 'Grenze/Grenze-BlackItalic.ttf'),
    Font(
        title: 'Grenze bold',
        family: 'Grenze',
        weight: FontWeight.w700,
        path: 'Grenze/Grenze-Bold.ttf'),
    Font(
        title: 'Grenze bold italic',
        family: 'Grenze',
        style: FontStyle.italic,
        weight: FontWeight.w700,
        path: 'Grenze/Grenze-BoldItalic.ttf'),
    Font(
        title: 'Grenze extrabold',
        family: 'Grenze',
        weight: FontWeight.w800,
        path: 'Grenze/Grenze-ExtraBold.ttf'),
    Font(
        title: 'Grenze extrabold italic',
        family: 'Grenze',
        style: FontStyle.italic,
        weight: FontWeight.w800,
        path: 'Grenze/Grenze-ExtraBoldItalic.ttf'),
    Font(
        title: 'Grenze extralight',
        family: 'Grenze',
        weight: FontWeight.w200,
        path: 'Grenze/Grenze-ExtraLight.ttf'),
    Font(
        title: 'Grenze extralight italic',
        family: 'Grenze',
        style: FontStyle.italic,
        weight: FontWeight.w200,
        path: 'Grenze/Grenze-ExtraLightItalic.ttf'),
    Font(
        title: 'Grenze  italic',
        family: 'Grenze',
        style: FontStyle.italic,
        weight: FontWeight.w400,
        path: 'Grenze/Grenze-Italic.ttf'),
    Font(
        title: 'Grenze light',
        family: 'Grenze',
        weight: FontWeight.w300,
        path: 'Grenze/Grenze-Light.ttf'),
    Font(
        title: 'Grenze light italic',
        family: 'Grenze',
        style: FontStyle.italic,
        weight: FontWeight.w300,
        path: 'Grenze/Grenze-LightItalic.ttf'),
    Font(
        title: 'Grenze medium',
        family: 'Grenze',
        weight: FontWeight.w500,
        path: 'Grenze/Grenze-Medium.ttf'),
    Font(
        title: 'Grenze medium italic',
        family: 'Grenze',
        style: FontStyle.italic,
        weight: FontWeight.w500,
        path: 'Grenze/Grenze-MediumItalic.ttf'),
    Font(
        title: 'Grenze regular',
        family: 'Grenze',
        weight: FontWeight.w400,
        path: 'Grenze/Grenze-Regular.ttf'),
    Font(
        title: 'Grenze semibold',
        family: 'Grenze',
        weight: FontWeight.w600,
        path: 'Grenze/Grenze-SemiBold.ttf'),
    Font(
        title: 'Grenze semibold italic',
        family: 'Grenze',
        style: FontStyle.italic,
        weight: FontWeight.w600,
        path: 'Grenze/Grenze-SemiBoldItalic.ttf'),
    Font(
        title: 'Grenze thin',
        family: 'Grenze',
        weight: FontWeight.w100,
        path: 'Grenze/Grenze-Thin.ttf'),
    Font(
        title: 'Grenze thin italic',
        family: 'Grenze',
        style: FontStyle.italic,
        weight: FontWeight.w100,
        path: 'Grenze/Grenze-ThinItalic.ttf'),
    Font(
        title: 'Handlee regular',
        family: 'Handlee',
        weight: FontWeight.w400,
        path: 'Handlee/Handlee-Regular.ttf'),
    Font(
        title: 'IndieFlower regular',
        family: 'IndieFlower',
        weight: FontWeight.w400,
        path: 'Indie_Flower/IndieFlower-Regular.ttf'),
    Font(
        title: 'Lato black',
        family: 'Lato',
        weight: FontWeight.w900,
        path: 'Lato/Lato-Black.ttf'),
    Font(
        title: 'Lato black italic',
        family: 'Lato',
        style: FontStyle.italic,
        weight: FontWeight.w900,
        path: 'Lato/Lato-BlackItalic.ttf'),
    Font(
        title: 'Lato bold',
        family: 'Lato',
        weight: FontWeight.w700,
        path: 'Lato/Lato-Bold.ttf'),
    Font(
        title: 'Lato bold italic',
        family: 'Lato',
        style: FontStyle.italic,
        weight: FontWeight.w700,
        path: 'Lato/Lato-BoldItalic.ttf'),
    Font(
        title: 'Lato light',
        family: 'Lato',
        weight: FontWeight.w300,
        path: 'Lato/Lato-Light.ttf'),
    Font(
        title: 'Lato light italic',
        family: 'Lato',
        style: FontStyle.italic,
        weight: FontWeight.w300,
        path: 'Lato/Lato-LightItalic.ttf'),
    Font(
        title: 'Lato regular',
        family: 'Lato',
        weight: FontWeight.w400,
        path: 'Lato/Lato-Regular.ttf'),
    Font(
        title: 'Lato regular italic',
        family: 'Lato',
        style: FontStyle.italic,
        weight: FontWeight.w400,
        path: 'Lato/Lato-RegularItalic.ttf'),
    Font(
        title: 'Lato thin',
        family: 'Lato',
        weight: FontWeight.w100,
        path: 'Lato/Lato-Thin.ttf'),
    Font(
        title: 'Lato thin italic',
        family: 'Lato',
        style: FontStyle.italic,
        weight: FontWeight.w100,
        path: 'Lato/Lato-ThinItalic.ttf'),
    Font(
        title: 'LibreFranklin black',
        family: 'LibreFranklin',
        weight: FontWeight.w900,
        path: 'Libre_Franklin/LibreFranklin-Black.ttf'),
    Font(
        title: 'LibreFranklin black italic',
        family: 'LibreFranklin',
        style: FontStyle.italic,
        weight: FontWeight.w900,
        path: 'Libre_Franklin/LibreFranklin-BlackItalic.ttf'),
    Font(
        title: 'LibreFranklin bold',
        family: 'LibreFranklin',
        weight: FontWeight.w700,
        path: 'Libre_Franklin/LibreFranklin-Bold.ttf'),
    Font(
        title: 'LibreFranklin bold italic',
        family: 'LibreFranklin',
        style: FontStyle.italic,
        weight: FontWeight.w700,
        path: 'Libre_Franklin/LibreFranklin-BoldItalic.ttf'),
    Font(
        title: 'LibreFranklin extrabold',
        family: 'LibreFranklin',
        weight: FontWeight.w800,
        path: 'Libre_Franklin/LibreFranklin-ExtraBold.ttf'),
    Font(
        title: 'LibreFranklin extrabold italic',
        family: 'LibreFranklin',
        style: FontStyle.italic,
        weight: FontWeight.w800,
        path: 'Libre_Franklin/LibreFranklin-ExtraBoldItalic.ttf'),
    Font(
        title: 'LibreFranklin extralight',
        family: 'LibreFranklin',
        weight: FontWeight.w200,
        path: 'Libre_Franklin/LibreFranklin-ExtraLight.ttf'),
    Font(
        title: 'LibreFranklin extralight italic',
        family: 'LibreFranklin',
        style: FontStyle.italic,
        weight: FontWeight.w200,
        path: 'Libre_Franklin/LibreFranklin-ExtraLightItalic.ttf'),
    Font(
        title: 'LibreFranklin  italic',
        family: 'LibreFranklin',
        style: FontStyle.italic,
        weight: FontWeight.w400,
        path: 'Libre_Franklin/LibreFranklin-Italic.ttf'),
    Font(
        title: 'LibreFranklin light',
        family: 'LibreFranklin',
        weight: FontWeight.w300,
        path: 'Libre_Franklin/LibreFranklin-Light.ttf'),
    Font(
        title: 'LibreFranklin light italic',
        family: 'LibreFranklin',
        style: FontStyle.italic,
        weight: FontWeight.w300,
        path: 'Libre_Franklin/LibreFranklin-LightItalic.ttf'),
    Font(
        title: 'LibreFranklin medium',
        family: 'LibreFranklin',
        weight: FontWeight.w500,
        path: 'Libre_Franklin/LibreFranklin-Medium.ttf'),
    Font(
        title: 'LibreFranklin medium italic',
        family: 'LibreFranklin',
        style: FontStyle.italic,
        weight: FontWeight.w500,
        path: 'Libre_Franklin/LibreFranklin-MediumItalic.ttf'),
    Font(
        title: 'LibreFranklin regular',
        family: 'LibreFranklin',
        weight: FontWeight.w400,
        path: 'Libre_Franklin/LibreFranklin-Regular.ttf'),
    Font(
        title: 'LibreFranklin semibold',
        family: 'LibreFranklin',
        weight: FontWeight.w600,
        path: 'Libre_Franklin/LibreFranklin-SemiBold.ttf'),
    Font(
        title: 'LibreFranklin semibold italic',
        family: 'LibreFranklin',
        style: FontStyle.italic,
        weight: FontWeight.w600,
        path: 'Libre_Franklin/LibreFranklin-SemiBoldItalic.ttf'),
    Font(
        title: 'LibreFranklin thin',
        family: 'LibreFranklin',
        weight: FontWeight.w100,
        path: 'Libre_Franklin/LibreFranklin-Thin.ttf'),
    Font(
        title: 'LibreFranklin thin italic',
        family: 'LibreFranklin',
        style: FontStyle.italic,
        weight: FontWeight.w100,
        path: 'Libre_Franklin/LibreFranklin-ThinItalic.ttf'),
    Font(
        title: 'Lobster regular',
        family: 'Lobster',
        weight: FontWeight.w400,
        path: 'Lobster/Lobster-Regular.ttf'),
    Font(
        title: 'LuckiestGuy regular',
        family: 'LuckiestGuy',
        weight: FontWeight.w400,
        path: 'Luckiest_Guy/LuckiestGuy-Regular.ttf'),
    Font(
        title: 'Mansalva regular',
        family: 'Mansalva',
        weight: FontWeight.w400,
        path: 'Mansalva/Mansalva-Regular.ttf'),
    Font(
        title: 'Merriweather black',
        family: 'Merriweather',
        weight: FontWeight.w900,
        path: 'Merriweather/Merriweather-Black.ttf'),
    Font(
        title: 'Merriweather black italic',
        family: 'Merriweather',
        style: FontStyle.italic,
        weight: FontWeight.w900,
        path: 'Merriweather/Merriweather-BlackItalic.ttf'),
    Font(
        title: 'Merriweather bold',
        family: 'Merriweather',
        weight: FontWeight.w700,
        path: 'Merriweather/Merriweather-Bold.ttf'),
    Font(
        title: 'Merriweather bold italic',
        family: 'Merriweather',
        style: FontStyle.italic,
        weight: FontWeight.w700,
        path: 'Merriweather/Merriweather-BoldItalic.ttf'),
    Font(
        title: 'Merriweather  italic',
        family: 'Merriweather',
        style: FontStyle.italic,
        weight: FontWeight.w400,
        path: 'Merriweather/Merriweather-Italic.ttf'),
    Font(
        title: 'Merriweather light',
        family: 'Merriweather',
        weight: FontWeight.w300,
        path: 'Merriweather/Merriweather-Light.ttf'),
    Font(
        title: 'Merriweather light italic',
        family: 'Merriweather',
        style: FontStyle.italic,
        weight: FontWeight.w300,
        path: 'Merriweather/Merriweather-LightItalic.ttf'),
    Font(
        title: 'Merriweather regular',
        family: 'Merriweather',
        weight: FontWeight.w400,
        path: 'Merriweather/Merriweather-Regular.ttf'),
    Font(
        title: 'OpenSans bold',
        family: 'OpenSans',
        weight: FontWeight.w700,
        path: 'Open_Sans/OpenSans-Bold.ttf'),
    Font(
        title: 'OpenSans bold italic',
        family: 'OpenSans',
        style: FontStyle.italic,
        weight: FontWeight.w700,
        path: 'Open_Sans/OpenSans-BoldItalic.ttf'),
    Font(
        title: 'OpenSans extrabold',
        family: 'OpenSans',
        weight: FontWeight.w800,
        path: 'Open_Sans/OpenSans-ExtraBold.ttf'),
    Font(
        title: 'OpenSans extrabold italic',
        family: 'OpenSans',
        style: FontStyle.italic,
        weight: FontWeight.w800,
        path: 'Open_Sans/OpenSans-ExtraBoldItalic.ttf'),
    Font(
        title: 'OpenSans  italic',
        family: 'OpenSans',
        style: FontStyle.italic,
        weight: FontWeight.w400,
        path: 'Open_Sans/OpenSans-Italic.ttf'),
    Font(
        title: 'OpenSans light',
        family: 'OpenSans',
        weight: FontWeight.w300,
        path: 'Open_Sans/OpenSans-Light.ttf'),
    Font(
        title: 'OpenSans light italic',
        family: 'OpenSans',
        style: FontStyle.italic,
        weight: FontWeight.w300,
        path: 'Open_Sans/OpenSans-LightItalic.ttf'),
    Font(
        title: 'OpenSans regular',
        family: 'OpenSans',
        weight: FontWeight.w400,
        path: 'Open_Sans/OpenSans-Regular.ttf'),
    Font(
        title: 'OpenSans semibold',
        family: 'OpenSans',
        weight: FontWeight.w600,
        path: 'Open_Sans/OpenSans-SemiBold.ttf'),
    Font(
        title: 'OpenSans semibold italic',
        family: 'OpenSans',
        style: FontStyle.italic,
        weight: FontWeight.w600,
        path: 'Open_Sans/OpenSans-SemiBoldItalic.ttf'),
    Font(
        title: 'Pacifico regular',
        family: 'Pacifico',
        weight: FontWeight.w400,
        path: 'Pacifico/Pacifico-Regular.ttf'),
    Font(
        title: 'PermanentMarker regular',
        family: 'PermanentMarker',
        weight: FontWeight.w400,
        path: 'Permanent_Marker/PermanentMarker-Regular.ttf'),
    Font(
        title: 'Righteous regular',
        family: 'Righteous',
        weight: FontWeight.w400,
        path: 'Righteous/Righteous-Regular.ttf'),
    Font(
        title: 'Roboto black',
        family: 'Roboto',
        weight: FontWeight.w900,
        path: 'Roboto/Roboto-Black.ttf'),
    Font(
        title: 'Roboto black italic',
        family: 'Roboto',
        style: FontStyle.italic,
        weight: FontWeight.w900,
        path: 'Roboto/Roboto-BlackItalic.ttf'),
    Font(
        title: 'Roboto bold',
        family: 'Roboto',
        weight: FontWeight.w700,
        path: 'Roboto/Roboto-Bold.ttf'),
    Font(
        title: 'Roboto bold italic',
        family: 'Roboto',
        style: FontStyle.italic,
        weight: FontWeight.w700,
        path: 'Roboto/Roboto-BoldItalic.ttf'),
    Font(
        title: 'Roboto  italic',
        family: 'Roboto',
        style: FontStyle.italic,
        weight: FontWeight.w400,
        path: 'Roboto/Roboto-Italic.ttf'),
    Font(
        title: 'Roboto light',
        family: 'Roboto',
        weight: FontWeight.w300,
        path: 'Roboto/Roboto-Light.ttf'),
    Font(
        title: 'Roboto light italic',
        family: 'Roboto',
        style: FontStyle.italic,
        weight: FontWeight.w300,
        path: 'Roboto/Roboto-LightItalic.ttf'),
    Font(
        title: 'Roboto medium',
        family: 'Roboto',
        weight: FontWeight.w500,
        path: 'Roboto/Roboto-Medium.ttf'),
    Font(
        title: 'Roboto medium italic',
        family: 'Roboto',
        style: FontStyle.italic,
        weight: FontWeight.w500,
        path: 'Roboto/Roboto-MediumItalic.ttf'),
    Font(
        title: 'Roboto regular',
        family: 'Roboto',
        weight: FontWeight.w400,
        path: 'Roboto/Roboto-Regular.ttf'),
    Font(
        title: 'Roboto regular italic',
        family: 'Roboto',
        style: FontStyle.italic,
        weight: FontWeight.w400,
        path: 'Roboto/Roboto-RegularItalic.ttf'),
    Font(
        title: 'Roboto thin',
        family: 'Roboto',
        weight: FontWeight.w100,
        path: 'Roboto/Roboto-Thin.ttf'),
    Font(
        title: 'Roboto thin italic',
        family: 'Roboto',
        style: FontStyle.italic,
        weight: FontWeight.w100,
        path: 'Roboto/Roboto-ThinItalic.ttf'),
    Font(
        title: 'SourceSansPro black',
        family: 'SourceSansPro',
        weight: FontWeight.w900,
        path: 'Source_Sans_Pro/SourceSansPro-Black.ttf'),
    Font(
        title: 'SourceSansPro black italic',
        family: 'SourceSansPro',
        style: FontStyle.italic,
        weight: FontWeight.w900,
        path: 'Source_Sans_Pro/SourceSansPro-BlackItalic.ttf'),
    Font(
        title: 'SourceSansPro bold',
        family: 'SourceSansPro',
        weight: FontWeight.w700,
        path: 'Source_Sans_Pro/SourceSansPro-Bold.ttf'),
    Font(
        title: 'SourceSansPro bold italic',
        family: 'SourceSansPro',
        style: FontStyle.italic,
        weight: FontWeight.w700,
        path: 'Source_Sans_Pro/SourceSansPro-BoldItalic.ttf'),
    Font(
        title: 'SourceSansPro extralight',
        family: 'SourceSansPro',
        weight: FontWeight.w200,
        path: 'Source_Sans_Pro/SourceSansPro-ExtraLight.ttf'),
    Font(
        title: 'SourceSansPro extralight italic',
        family: 'SourceSansPro',
        style: FontStyle.italic,
        weight: FontWeight.w200,
        path: 'Source_Sans_Pro/SourceSansPro-ExtraLightItalic.ttf'),
    Font(
        title: 'SourceSansPro  italic',
        family: 'SourceSansPro',
        style: FontStyle.italic,
        weight: FontWeight.w400,
        path: 'Source_Sans_Pro/SourceSansPro-Italic.ttf'),
    Font(
        title: 'SourceSansPro light',
        family: 'SourceSansPro',
        weight: FontWeight.w300,
        path: 'Source_Sans_Pro/SourceSansPro-Light.ttf'),
    Font(
        title: 'SourceSansPro light italic',
        family: 'SourceSansPro',
        style: FontStyle.italic,
        weight: FontWeight.w300,
        path: 'Source_Sans_Pro/SourceSansPro-LightItalic.ttf'),
    Font(
        title: 'SourceSansPro regular',
        family: 'SourceSansPro',
        weight: FontWeight.w400,
        path: 'Source_Sans_Pro/SourceSansPro-Regular.ttf'),
    Font(
        title: 'SourceSansPro semibold',
        family: 'SourceSansPro',
        weight: FontWeight.w600,
        path: 'Source_Sans_Pro/SourceSansPro-SemiBold.ttf'),
    Font(
        title: 'SourceSansPro semibold italic',
        family: 'SourceSansPro',
        style: FontStyle.italic,
        weight: FontWeight.w600,
        path: 'Source_Sans_Pro/SourceSansPro-SemiBoldItalic.ttf'),
  ];
}
