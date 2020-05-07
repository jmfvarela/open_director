import 'dart:core';
import 'package:flutter/material.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/service/director_service.dart';
import 'package:open_director/model/model.dart';
import 'package:open_director/ui/director/params.dart';
import 'package:open_director/service/director/generator.dart';
import 'package:open_director/ui/director/progress_dialog.dart';
import 'package:open_director/ui/generated_video_list.dart';

class AppBar1 extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: directorService.appBar$,
        builder: (BuildContext context, AsyncSnapshot<bool> appBar) {
          bool isLandscape =
              (MediaQuery.of(context).orientation == Orientation.landscape);
          if (directorService.editingTextAsset == null) {
            if (isLandscape) {
              return _AppBar1Landscape();
            } else {
              return _AppBar1Portrait();
            }
          } else if (directorService.editingColor == null) {
            if (isLandscape) {
              return Container(width: Params.getSideMenuWidth(context));
            } else {
              return _AppBar1Portrait();
            }
          } else {
            if (isLandscape) {
              return Container(width: Params.getSideMenuWidth(context));
            } else {
              return _AppBar1Portrait();
            }
          }
        });
  }
}

class AppBar2 extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: directorService.appBar$,
        builder: (BuildContext context, AsyncSnapshot<bool> appBar) {
          bool isLandscape =
              (MediaQuery.of(context).orientation == Orientation.landscape);
          if (directorService.editingTextAsset == null) {
            if (isLandscape) {
              return _AppBar2Landscape();
            } else {
              return _AppBar2Portrait();
            }
          } else if (directorService.editingColor == null) {
            if (isLandscape) {
              return _AppBar2EditingTextLandscape();
            } else {
              return _AppBar2EditingTextPortrait();
            }
          } else {
            if (isLandscape) {
              return Container(width: Params.getSideMenuWidth(context));
            } else {
              return Container();
            }
          }
        });
  }
}

class _AppBar1Landscape extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    List<Widget> children = List();
    children.add(_ButtonBack());
    if (directorService.selected.layerIndex != -1) {
      children.add(_ButtonDelete());
    } else {
      children.add(Container(height: 48));
    }
    if (directorService.assetSelected?.type == AssetType.video ||
        directorService.assetSelected?.type == AssetType.audio) {
      children.add(_ButtonCut());
    } else if (directorService.assetSelected?.type == AssetType.text) {
      children.add(_ButtonEdit());
    } else {
      children.add(Container(height: 48));
    }
    return Container(
      width: Params.getSideMenuWidth(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _AppBar1Portrait extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    List<Widget> children = List();
    children.add(_ButtonBack());
    return AppBar(
      leading: _ButtonBack(),
      title: Text(directorService.project.title),
      actions: children,
    );
  }
}

class _AppBar2Landscape extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    List<Widget> children = List();
    children.add(_ButtonAdd());
    if (directorService.layers[0].assets.isNotEmpty &&
        !directorService.isPlaying) {
      children.add(_ButtonPlay());
    }
    if (directorService.isPlaying) {
      children.add(_ButtonPause());
    }
    if (directorService.layers[0].assets.isNotEmpty) {
      children.add(_ButtonGenerate());
    }
    return Container(
      width: Params.getSideMenuWidth(context),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children),
    );
  }
}

class _AppBar2Portrait extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    List<Widget> children = List();
    children.add(_ButtonAdd());
    if (directorService.layers[0].assets.isNotEmpty &&
        !directorService.isPlaying) {
      children.add(_ButtonPlay());
    }
    if (directorService.isPlaying) {
      children.add(_ButtonPause());
    }
    if (directorService.layers[0].assets.isNotEmpty) {
      children.add(_ButtonGenerate());
    }

    List<Widget> children2 = List();
    if (directorService.selected.layerIndex != -1) {
      children2.add(_ButtonDelete());
    }
    if (directorService.assetSelected?.type == AssetType.video ||
        directorService.assetSelected?.type == AssetType.audio) {
      children2.add(_ButtonCut());
    } else if (directorService.assetSelected?.type == AssetType.text) {
      children2.add(_ButtonEdit());
    }

    return Container(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: children2),
          Row(children: children),
        ],
      ),
    );
  }
}

class _AppBar2EditingTextLandscape extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Params.getSideMenuWidth(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RaisedButton(
            child: Text('SAVE'),
            onPressed: () {
              directorService.saveTextAsset();
            },
          ),
          FlatButton(
            child: Text('Cancel'),
            onPressed: () {
              directorService.editingTextAsset = null;
            },
          ),
        ],
      ),
    );
  }
}

class _AppBar2EditingTextPortrait extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    List<Widget> children = List();
    children.add(_ButtonAdd());

    return Container(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          RaisedButton(
            child: Text('SAVE'),
            onPressed: () {
              directorService.saveTextAsset();
            },
          ),
          FlatButton(
            child: Text('Cancel'),
            onPressed: () {
              directorService.editingTextAsset = null;
            },
          ),
        ],
      ),
    );
  }
}

class _ButtonBack extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.grey.shade500),
        tooltip: "Back",
        onPressed: () async {
          bool exit = await directorService.exitAndSaveProject();
          if (exit) Navigator.pop(context);
        });
  }
}

class _ButtonDelete extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "delete",
      tooltip: "Delete selected",
      backgroundColor: Colors.pink,
      mini: MediaQuery.of(context).size.width < 900,
      child: Icon(Icons.delete, color: Colors.white),
      onPressed: directorService.delete,
    );
  }
}

class _ButtonCut extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "cut",
      tooltip: "Cut video selected",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      child: Icon(Icons.content_cut, color: Colors.white),
      onPressed: directorService.cutVideo,
    );
  }
}

class _ButtonEdit extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "edit",
      tooltip: "Edit",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      child: Icon(Icons.edit, color: Colors.white),
      onPressed: () {
        directorService.editTextAsset();
      },
    );
  }
}

class _ButtonAdd extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "add",
      tooltip: "Add media",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      onPressed: () {},
      child: PopupMenuButton<AssetType>(
        icon: Icon(Icons.add, color: Colors.white),
        onSelected: (AssetType result) {
          directorService.add(result);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<AssetType>>[
          const PopupMenuItem<AssetType>(
            value: AssetType.video,
            child: Text('Add video'),
          ),
          const PopupMenuItem<AssetType>(
            value: AssetType.image,
            child: Text('Add image'),
          ),
          const PopupMenuItem<AssetType>(
            value: AssetType.audio,
            child: Text('Add audio'),
          ),
          const PopupMenuItem<AssetType>(
            value: AssetType.text,
            child: Text('Add title'),
          ),
        ],
      ),
    );
  }
}

class _ButtonPlay extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "play",
      tooltip: "Play",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      child: Icon(Icons.play_arrow, color: Colors.white),
      onPressed: directorService.play,
    );
  }
}

class _ButtonPause extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "pause",
      tooltip: "Pause",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      child: Icon(Icons.pause, color: Colors.white),
      onPressed: directorService.stop,
    );
  }
}

class _ButtonGenerate extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProgressDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "generate",
      tooltip: "Generate video",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      onPressed: () {},
      child: PopupMenuButton<dynamic>(
        icon: Icon(Icons.theaters, color: Colors.white),
        onSelected: (dynamic val) {
          if (val == 99) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      GeneratedVideoList(directorService.project)),
            );
          } else {
            directorService.generateVideo(directorService.layers, val);
            showProgressDialog(context);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<dynamic>>[
          const PopupMenuItem<VideoResolution>(
            value: VideoResolution.fullHd,
            child: Text('Generate Full HD 1080px'),
          ),
          const PopupMenuItem<VideoResolution>(
            value: VideoResolution.hd,
            child: Text('Generate HD 720px'),
          ),
          const PopupMenuItem<VideoResolution>(
            value: VideoResolution.sd,
            child: Text('Generate SD 360px'),
          ),
          const PopupMenuDivider(height: 10),
          const PopupMenuItem<int>(
            value: 99,
            child: Text('View generated videos'),
          ),
        ],
      ),
    );
  }
}
