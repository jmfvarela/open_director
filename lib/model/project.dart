import 'package:flutter/foundation.dart';

class Project {
  int id;
  String title;
  String description;
  DateTime date;
  int duration;
  String layersJson;
  String imagePath;

  Project({
    @required this.title,
    this.description,
    @required this.date,
    @required this.duration,
    this.layersJson,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'duration': duration,
      'layersJson': layersJson,
      'imagePath': imagePath,
    };
    if (id != null) {
      map['_id'] = id;
    }
    return map;
  }

  Project.fromMap(Map<String, dynamic> map) {
    id = map['_id'];
    title = map['title'];
    description = map['description'];
    date = DateTime.fromMillisecondsSinceEpoch(map['date']);
    duration = map['duration'];
    layersJson = map['layersJson'];
    imagePath = map['imagePath'];
  }

  @override
  String toString() {
    return 'Project {'
        'id: $id, '
        'title: $title, '
        'description: $description, '
        'date: $date, '
        'duration: $duration, '
        'imagePath: $imagePath}';
  }
}
