
[![Alt text](/doc/image001.jpg?raw=true)](https://www.youtube.com/watch?v=1pp6mBj7QgY)

Open Director allows you to create videos quickly and easily by importing your own photos, videos and adding titles on a timeline using "drag and drop".

[Open Director on Google Play](https://play.google.com/store/apps/details?id=io.opendirector.app) 


# Developer info

Built with [Flutter](https://flutter.dev).


## Prerequisites

- Android Studio, including Android SDK and emulators (I use API 28, beacause I found a bug in API 29).
- Visual Studio Code with dart and flutter plugins.
- Optional: dart and flutter plugins for Android Studio.


## Installing

User environment variables. Examples for Windows:
```
ANDROID_HOME C:\Users\<user>\AppData\Local\Android\Sdk
HOME C:\Users\<user>
```

System environment variables:
```
PATH C:\flutter\bin; C:\Users\<user>\AppData\Local\Android\Sdk\emulator
```

Check status and license acceptance (optional: dart and flutter plugins for Android Studio):
```
flutter doctor
```


## Running and deploying

To check connected devices:
```
flutter devices
```

To check available emulators:
```
flutter emulators
```
or:
```
emulator -list-avds
```

To launch an emulator:
```
flutter emulators --launch Pixel_2_API_28
```
or:
```
emulator -avd Pixel_2_API_28
```
or from Visual Studio Code:
```
> shift + ctrl + p > Flutter: Launch emulator > Pixel_2_API_28
```

Run on connected device or launched emulator:
```
flutter run
```

To run from VS Code with hot reload and debug mode, on connected device or on a launched emulator:
```
> Debug > Flutter (launch)
```

Install apk on the connected device:
```
flutter clean
flutter build apk
flutter install
```

To generate an app bundle, because the apk is very fat:
```
flutter build appbundle --target-platform android-arm,android-arm64
```

# License

This project is based on [mobile-ffmpeg](https://github.com/tanersener/mobile-ffmpeg) and is licensed under the LGPL v3.0. However, if source code is built using optional --enable-gpl flag or prebuilt binaries with -gpl postfix are used then MobileFFmpeg is subject to the GPL v3.0 license.