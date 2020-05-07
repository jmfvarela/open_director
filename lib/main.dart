import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/ui/project_list.dart';

void main() {
  //CustomImageCache(); // Disabled at this time
  //setupDevice(); // Disabled at this time
  setupAnalyticsAndCrashlytics();
  setupLocator();
  runApp(MyApp());
}

setupDevice() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Status bar disabled
  SystemChrome.setEnabledSystemUIOverlays([]);
}

setupAnalyticsAndCrashlytics() {
  // Set `enableInDevMode` to true to see reports while in debug mode
  // This is only to be used for confirming that reports are being
  // submitted as expected. It is not intended to be used for everyday
  // development.
  Crashlytics.instance.enableInDevMode = false;

  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = Crashlytics.instance.recordFlutterError;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics analytics = FirebaseAnalytics();
    return MaterialApp(
      title: 'Open Director',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.blue,
        brightness: Brightness.dark,
        textTheme: TextTheme(
          button: TextStyle(color: Colors.white),
        ),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('es', 'ES'),
      ],
      home: Scaffold(
        body: ProjectList(),
      ),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    );
  }
}

class CustomImageCache extends WidgetsFlutterBinding {
  @override
  ImageCache createImageCache() {
    ImageCache imageCache = super.createImageCache();
    imageCache.maximumSize = 5;
    return imageCache;
  }
}
