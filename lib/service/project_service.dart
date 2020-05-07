import 'dart:io';
import 'package:rxdart/rxdart.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/model/project.dart';
import 'package:open_director/dao/project_dao.dart';

class ProjectService {
  final ProjectDao projectDao = locator.get<ProjectDao>();

  List<Project> projectList = [];
  Project project;

  BehaviorSubject<bool> _projectListChanged = BehaviorSubject.seeded(false);
  Observable<bool> get projectListChanged$ => _projectListChanged.stream;
  bool get projectListChanged => _projectListChanged.value;

  ProjectService() {
    load();
  }

  dispose() {
    _projectListChanged.close();
  }

  void load() async {
    await projectDao.open();
    refresh();
  }

  void refresh() async {
    projectList = await projectDao.findAll();
    _projectListChanged.add(true);
    checkSomeFileNotExists();
  }

  checkSomeFileNotExists() {
    for (int i = 0; i < projectList.length; i++) {
      if (projectList[i].imagePath != null &&
          !File(projectList[i].imagePath).existsSync()) {
        print('${projectList[i].imagePath} does not exists');
        projectList[i].imagePath = null;
      }
    }
  }

  Project createNew() {
    return Project(title: '', duration: 0, date: DateTime.now());
  }

  insert(_project) async {
    _project.date = DateTime.now();
    await projectDao.insert(_project);
    refresh();
  }

  update(_project) async {
    await projectDao.update(_project);
    refresh();
  }

  delete(index) async {
    await projectDao.delete(projectList[index].id);
    refresh();
  }
}
