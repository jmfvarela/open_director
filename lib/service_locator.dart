import 'package:get_it/get_it.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';
import 'package:open_director/service/director_service.dart';
import 'package:open_director/service/director/generator.dart';
import 'package:open_director/service/project_service.dart';
import 'package:open_director/dao/project_dao.dart';
import 'package:open_director/service/generated_video_service.dart';

GetIt locator = GetIt();

void setupLocator() {
  locator.registerSingleton<Logger>(createLog());
  locator.registerSingleton<FirebaseAnalytics>(FirebaseAnalytics());
  locator.registerSingleton<ProjectDao>(ProjectDao());
  locator.registerSingleton<ProjectService>(ProjectService());
  locator.registerSingleton<Generator>(Generator());
  locator.registerSingleton<DirectorService>(DirectorService());
  locator.registerSingleton<GeneratedVideoService>(GeneratedVideoService());
}

Logger createLog() {
  Logger.level = Level.debug;
  return Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        printTime: false
        ),
    output: null,
  );
}
