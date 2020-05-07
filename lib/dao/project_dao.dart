import 'package:sqflite/sqflite.dart';
import 'package:open_director/model/project.dart';
import 'package:open_director/model/generated_video.dart';

class ProjectDao {
  Database db;

  final migrationScripts = [
    '''
create table project (
  _id integer primary key autoincrement
  , title text not null
  , description text
  , date integer not null
  , duration integer not null
  , layersJson text
  , imagePath text
)
''',
    '''
create table generatedVideo (
  _id integer primary key autoincrement
  , projectId integer not null
  , path text not null
  , date integer not null
  , resolution text
  , thumbnail text
)
  ''',
  ];

  Future open() async {
    db = await openDatabase(
      'project',
      version: migrationScripts.length,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        for (var i = oldVersion; i < newVersion; i++) {
          await db.execute(migrationScripts[i]);
        }
      },
    );
  }

  Future<Project> insert(Project project) async {
    project.id = await db.insert('project', project.toMap());
    return project;
  }

  Future<GeneratedVideo> insertGeneratedVideo(GeneratedVideo generatedVideo) async {
    generatedVideo.id = await db.insert('generatedVideo', generatedVideo.toMap());
    return generatedVideo;
  }

  Future<Project> get(int id) async {
    List<Map> maps = await db.query('project',
        columns: [
          '_id',
          'title',
          'description',
          'date',
          'duration',
          'layersJson',
          'imagePath',
        ],
        where: '_id = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Project.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Project>> findAll() async {
    List<Map> maps = await db.query(
      'project',
      columns: [
        '_id',
        'title',
        'description',
        'date',
        'duration',
        'layersJson',
        'imagePath',
      ],
    );
    return maps.map((m) => Project.fromMap(m)).toList();
  }

  Future<List<GeneratedVideo>> findAllGeneratedVideo(int projectId) async {
    List<Map> maps = await db.query(
      'generatedVideo',
      columns: [
        '_id',
        'projectId',
        'path',
        'date',
        'resolution',
        'thumbnail',
      ],
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: '_id desc'
    );
    return maps.map((m) => GeneratedVideo.fromMap(m)).toList();
  }

  Future<int> delete(int id) async {
    return await db.delete('project', where: '_id = ?', whereArgs: [id]);
  }

  Future<int> deleteGeneratedVideo(int id) async {
    return await db.delete('generatedVideo', where: '_id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    return await db.delete('project');
  }

  Future<int> update(Project project) async {
    return await db.update('project', project.toMap(),
        where: '_id = ?', whereArgs: [project.id]);
  }

  Future close() async => db.close();
}
