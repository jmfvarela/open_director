import 'dart:io';
import 'package:rxdart/rxdart.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/model/generated_video.dart';
import 'package:open_director/dao/project_dao.dart';

class GeneratedVideoService {
  final ProjectDao projectDao = locator.get<ProjectDao>();

  List<GeneratedVideo> generatedVideoList = [];
  int projectId;

  BehaviorSubject<bool> _generatedVideoListChanged =
      BehaviorSubject.seeded(false);
  Observable<bool> get generatedVideoListChanged$ =>
      _generatedVideoListChanged.stream;
  bool get generatedVideoListChanged => _generatedVideoListChanged.value;

  GeneratedVideoService() {
    open();
  }

  dispose() {
    _generatedVideoListChanged.close();
  }

  void open() async {
    await projectDao.open();
  }

  void refresh(int _projectId) async {
    projectId = _projectId;
    generatedVideoList = [];
    _generatedVideoListChanged.add(true);
    generatedVideoList = await projectDao.findAllGeneratedVideo(projectId);
    _generatedVideoListChanged.add(true);
  }

  fileExists(index) {
    return File(generatedVideoList[index].path).existsSync();
  }

  delete(index) async {
    if (fileExists(index)) File(generatedVideoList[index].path).deleteSync();
    await projectDao.deleteGeneratedVideo(generatedVideoList[index].id);
    refresh(projectId);
  }
}
