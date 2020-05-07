import 'dart:core';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:open_file/open_file.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/service/director_service.dart';
import 'package:open_director/service/director/generator.dart';


class ProgressDialog extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: directorService.generator.ffmepegStat$,
        initialData: FFmpegStat(),
        builder: (BuildContext context, AsyncSnapshot<FFmpegStat> ffmepegStat) {
          String title, progressText;
          double progress = 0;
          String buttonText = 'CANCEL';
          if (ffmepegStat.data.totalFiles != null &&
              ffmepegStat.data.fileNum != null) {
            title = 'Preprocessing files';
            progress = (ffmepegStat.data.fileNum -
                    1 +
                    ffmepegStat.data.time / directorService.duration) /
                ffmepegStat.data.totalFiles;
            progressText =
                'File ${ffmepegStat.data.fileNum} of ${ffmepegStat.data.totalFiles}';
          } else if (ffmepegStat.data.time > 100) {
            title = 'Building your video';
            progress = ffmepegStat.data.time / directorService.duration;
            int remaining = (ffmepegStat.data.timeElapsed *
                    (directorService.duration / ffmepegStat.data.time - 1))
                .floor();
            int minutes = Duration(milliseconds: remaining).inMinutes;
            int seconds = Duration(milliseconds: remaining).inSeconds -
                60 * Duration(milliseconds: remaining).inMinutes;
            progressText = '$minutes min $seconds secs remaining';
          } else {
            title = 'Building your video';
            progress = ffmepegStat.data.time / directorService.duration;
            progressText = '';
          }
          Widget child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              progress == 0
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          LinearProgressIndicator(value: progress),
                          Padding(padding: EdgeInsets.symmetric(vertical: 4)),
                          Text(progressText),
                          Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                        ]),
            ],
          );
          if (ffmepegStat.data.finished) {
            title = 'Your video has been saved in the gallery';
            buttonText = 'OK';
            child = LinearProgressIndicator(value: 1);
          } else if (ffmepegStat.data.error) {
            title = 'Error';
            buttonText = 'OK';
            child = Text('An unexpected error occurred. We will work on it. '
                'Please try again or upgrade to new versions of the app if the error persists.');
          }
          return AlertDialog(
            title: Text(title),
            content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width / 2,
                child: child,
              ),
            ]),
            actions: [
              ffmepegStat.data.finished
                  ? FlatButton(
                      child: Text("OPEN VIDEO"),
                      textColor: Colors.white,
                      onPressed: () async {
                        OpenFile.open(ffmepegStat.data.outputPath);
                      },
                    )
                  : Container(),
              FlatButton(
                child: Text(buttonText),
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).pop();
                  // Delay to not see changes in dialog
                  Future.delayed(Duration(milliseconds: 100), () {
                    directorService.generator.finishVideoGeneration();
                  });
                },
              ),
            ],
          );
        });
  }
}
