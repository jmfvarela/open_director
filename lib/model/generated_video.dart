import 'package:flutter/foundation.dart';

class GeneratedVideo {
  int id;
  int projectId;
  String path;
  DateTime date;
  String resolution;
  String thumbnail;

  GeneratedVideo({
    @required this.projectId,
    @required this.path,
    @required this.date,
    this.resolution,
    this.thumbnail,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'projectId': projectId,
      'path': path,
      'date': date.millisecondsSinceEpoch,
      'resolution': resolution,
      'thumbnail': thumbnail,
    };
    if (id != null) {
      map['_id'] = id;
    }
    return map;
  }

  GeneratedVideo.fromMap(Map<String, dynamic> map) {
    id = map['_id'];
    projectId = map['projectId'];
    path = map['path'];
    date = DateTime.fromMillisecondsSinceEpoch(map['date']);
    resolution = map['resolution'];
    thumbnail = map['thumbnail'];
  }

  @override
  String toString() {
    return 'GeneratedVideo {'
        'id: $id, '
        'projectId: $projectId, '
        'path: $path, '
        'date: $date, '
        'resolution: $resolution, '
        'thumbnail: $thumbnail}';
  }
}
