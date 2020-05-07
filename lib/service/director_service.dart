import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_director/service_locator.dart';
import 'package:open_director/service/director/layer_player.dart';
import 'package:open_director/service/director/generator.dart';
import 'package:open_director/service/project_service.dart';
import 'package:open_director/model/model.dart';
import 'package:open_director/model/project.dart';
import 'package:open_director/model/generated_video.dart';
import 'package:open_director/dao/project_dao.dart';

class DirectorService {
  Project project;
  final logger = locator.get<Logger>();
  final projectService = locator.get<ProjectService>();
  final generator = locator.get<Generator>();
  final projectDao = locator.get<ProjectDao>();

  List<Layer> layers;

  // Flags for concurrency
  bool isEntering = false;
  bool isExiting = false;
  bool isPlaying = false;
  bool isPreviewing = false;
  int mainLayerIndexForConcurrency = -1;
  bool isDragging = false;
  bool isSizerDragging = false;
  bool isCutting = false;
  bool isScaling = false;
  bool isAdding = false;
  bool isDeleting = false;
  bool isGenerating = false;
  bool get isOperating => (isEntering ||
      isExiting ||
      isPlaying ||
      isPreviewing ||
      isDragging ||
      isSizerDragging ||
      isCutting ||
      isScaling ||
      isAdding ||
      isDeleting ||
      isGenerating);
  double _pixelsPerSecondOnInitScale;
  double _scrollOffsetOnInitScale;
  double dxSizerDrag = 0;
  bool isSizerDraggingEnd = false;

  BehaviorSubject<bool> _filesNotExist = BehaviorSubject.seeded(false);
  Observable<bool> get filesNotExist$ => _filesNotExist.stream;
  bool get filesNotExist => _filesNotExist.value;

  List<LayerPlayer> layerPlayers;

  ScrollController scrollController = ScrollController();

  BehaviorSubject<bool> _layersChanged = BehaviorSubject.seeded(false);
  Observable<bool> get layersChanged$ => _layersChanged.stream;
  bool get layersChanged => _layersChanged.value;

  BehaviorSubject<Selected> _selected =
      BehaviorSubject.seeded(Selected(-1, -1));
  Observable<Selected> get selected$ => _selected.stream;
  Selected get selected => _selected.value;
  Asset get assetSelected {
    if (selected.layerIndex == -1 || selected.assetIndex == -1) return null;
    return layers[selected.layerIndex].assets[selected.assetIndex];
  }

  static const double DEFAULT_PIXELS_PER_SECONDS = 100.0 / 5.0;
  BehaviorSubject<double> _pixelsPerSecond =
      BehaviorSubject.seeded(DEFAULT_PIXELS_PER_SECONDS);
  Observable<double> get pixelsPerSecond$ => _pixelsPerSecond.stream;
  double get pixelsPerSecond => _pixelsPerSecond.value;

  BehaviorSubject<bool> _appBar = BehaviorSubject.seeded(false);
  Observable<bool> get appBar$ => _appBar.stream;

  BehaviorSubject<int> _position = BehaviorSubject.seeded(0);
  Observable<int> get position$ => _position.stream;
  int get position => _position.value;

  BehaviorSubject<Asset> _editingTextAsset = BehaviorSubject.seeded(null);
  Observable<Asset> get editingTextAsset$ => _editingTextAsset.stream;
  Asset get editingTextAsset => _editingTextAsset.value;
  set editingTextAsset(Asset value) {
    _editingTextAsset.add(value);
    _appBar.add(true);
  }

  BehaviorSubject<String> _editingColor = BehaviorSubject.seeded(null);
  Observable<String> get editingColor$ => _editingColor.stream;
  String get editingColor => _editingColor.value;
  set editingColor(String value) {
    _editingColor.add(value);
    _appBar.add(true);
  }

  String get positionMinutes {
    int minutes = (position / 1000 / 60).floor();
    return (minutes < 10) ? '0' + minutes.toString() : minutes.toString();
  }

  String get positionSeconds {
    int minutes = (position / 1000 / 60).floor();
    double seconds = (((position / 1000 - minutes * 60) * 10).floor() / 10);
    return (seconds < 10) ? '0' + seconds.toString() : seconds.toString();
  }

  int get duration {
    int maxDuration = 0;
    for (int i = 0; i < layers.length; i++) {
      for (int j = layers[i].assets.length - 1; j >= 0; j--) {
        if (!(i == 1 && layers[i].assets[j].title == '')) {
          int dur = layers[i].assets[j].begin + layers[i].assets[j].duration;
          maxDuration = math.max(maxDuration, dur);
          break;
        }
      }
    }
    return maxDuration;
  }

  DirectorService() {
    scrollController.addListener(_listenerScrollController);
    _layersChanged.listen((bool onData) => _saveProject());
  }

  dispose() {
    _layersChanged.close();
    _selected.close();
    _pixelsPerSecond.close();
    _position.close();
    _appBar.close();
    _editingTextAsset.close();
    _editingColor.close();
    _filesNotExist.close();
  }

  setProject(Project _project) async {
    isEntering = true;

    _position.add(0);
    _selected.add(Selected(-1, -1));
    editingTextAsset = null;
    _editingColor.add(null);
    _pixelsPerSecond.add(DEFAULT_PIXELS_PER_SECONDS);
    _appBar.add(true);

    if (project != _project) {
      project = _project;
      if (_project.layersJson == null) {
        layers = [
          // TODO: audio mixing between layers
          Layer(type: "raster", volume: 0.1),
          Layer(type: "vector"),
          Layer(type: "audio", volume: 1.0),
        ];
      } else {
        layers = List<Layer>.from(json
            .decode(_project.layersJson)
            .map((layerMap) => Layer.fromJson(layerMap))).toList();
        _filesNotExist.add(checkSomeFileNotExists());
      }
      _layersChanged.add(true);

      layerPlayers = List<LayerPlayer>();
      for (int i = 0; i < layers.length; i++) {
        LayerPlayer layerPlayer;
        if (i != 1) {
          layerPlayer = LayerPlayer(layers[i]);
          await layerPlayer.initialize();
        }
        layerPlayers.add(layerPlayer);
      }
    }
    isEntering = false;
    await _previewOnPosition();
  }

  checkSomeFileNotExists() {
    bool _someFileNotExists = false;
    for (int i = 0; i < layers.length; i++) {
      for (int j = 0; j < layers[i].assets.length; j++) {
        Asset asset = layers[i].assets[j];
        if (asset.srcPath != '' && !File(asset.srcPath).existsSync()) {
          asset.deleted = true;
          _someFileNotExists = true;
          print(asset.srcPath + ' does not exists');
        }
      }
    }
    return _someFileNotExists;
  }

  exitAndSaveProject() async {
    if (isPlaying) await stop();
    if (isOperating) return false;
    isExiting = true;
    _saveProject();

    Future.delayed(Duration(milliseconds: 500), () {
      project = null;
      layerPlayers.forEach((layerPlayer) {
        layerPlayer?.dispose();
        layerPlayer = null;
      });
      isExiting = false;
    });

    _deleteThumbnailsNotUsed();
    return true;
  }

  _saveProject() {
    if (layers == null) return;
    project.layersJson = json.encode(layers);
    project.imagePath =
        layers[0].assets.isNotEmpty ? getFirstThumbnailMedPath() : null;
    projectService.update(project);
  }

  String getFirstThumbnailMedPath() {
    for (int i = 0; i < layers[0].assets.length; i++) {
      Asset asset = layers[0].assets[i];
      if (asset.thumbnailMedPath != null &&
          File(asset.thumbnailMedPath).existsSync()) {
        return asset.thumbnailMedPath;
      }
    }
    return null;
  }

  _listenerScrollController() async {
    // When playing position is defined by the video player
    if (isPlaying) return;
    // In other case by the scroll manually
    _position.sink
        .add(((scrollController.offset / pixelsPerSecond) * 1000).floor());
    // Delayed 10 to get more fuidity in scroll and preview
    Future.delayed(Duration(milliseconds: 10), () {
      _previewOnPosition();
    });
  }

  endScroll() async {
    _position.sink
        .add(((scrollController.offset / pixelsPerSecond) * 1000).floor());
    // Delayed 200 because position may not be updated at this time
    Future.delayed(Duration(milliseconds: 200), () {
      _previewOnPosition();
    });
  }

  _previewOnPosition() async {
    if (filesNotExist) return;
    if (isOperating) return;
    isPreviewing = true;
    scrollController.removeListener(_listenerScrollController);

    await layerPlayers[0].preview(position);
    _position.add(position);

    scrollController.addListener(_listenerScrollController);
    isPreviewing = false;
  }

  play() async {
    if (filesNotExist) {
      _filesNotExist.add(true);
      return;
    }
    if (isOperating) return;
    if (position >= duration) return;
    logger.i('DirectorService.play()');
    isPlaying = true;
    scrollController.removeListener(_listenerScrollController);
    _appBar.add(true);
    _selected.add(Selected(-1, -1));

    int mainLayer = mainLayerForConcurrency();
    print('mainLayer: $mainLayer');

    for (int i = 0; i < layers.length; i++) {
      if (i == 1) continue;
      if (i == mainLayer) {
        await layerPlayers[i].play(
          position,
          onMove: (int newPosition) {
            _position.add(newPosition);
            scrollController.animateTo(
                (300 + newPosition) / 1000 * pixelsPerSecond,
                duration: Duration(milliseconds: 300),
                curve: Curves.linear);
          },
          onEnd: () {
            isPlaying = false;
            _appBar.add(true);
          },
        );
      } else {
        await layerPlayers[i].play(position);
      }
      _position.add(position);
    }
  }

  stop() async {
    if ((isOperating && !isPlaying) || !isPlaying) return;
    print('>> DirectorService.stop()');
    for (int i = 0; i < layers.length; i++) {
      if (i == 1) continue;
      await layerPlayers[i].stop();
    }
    isPlaying = false;
    scrollController.addListener(_listenerScrollController);
    _appBar.add(true);
  }

  int mainLayerForConcurrency() {
    int mainLayer = 0, mainLayerDuration = 0;
    for (int i = 0; i < layers.length; i++) {
      if (i != 1 &&
          layers[i].assets.isNotEmpty &&
          layers[i].assets.last.begin + layers[i].assets.last.duration >
              mainLayerDuration) {
        mainLayer = i;
        mainLayerDuration =
            layers[i].assets.last.begin + layers[i].assets.last.duration;
      }
    }
    return mainLayer;
  }

  add(AssetType assetType) async {
    if (isOperating) return;
    isAdding = true;
    print('>> DirectorService.add($assetType)');

    Map<String, String> filePaths;

    if (assetType == AssetType.video) {
      filePaths = await FilePicker.getMultiFilePath(type: FileType.VIDEO);
      if (filePaths == null) {
        isAdding = false;
        return;
      }
      List<File> fileList = _sortFilesByDate(filePaths);
      for (int i = 0; i < fileList.length; i++) {
        await _addAssetToLayer(0, AssetType.video, fileList[i].path);
        _generateAllVideoThumbnails(layers[0].assets);
      }
    } else if (assetType == AssetType.image) {
      filePaths = await FilePicker.getMultiFilePath(type: FileType.IMAGE);
      if (filePaths == null) {
        isAdding = false;
        return;
      }
      List<File> fileList = _sortFilesByDate(filePaths);
      for (int i = 0; i < fileList.length; i++) {
        await _addAssetToLayer(0, AssetType.image, fileList[i].path);
        _generateKenBurnEffects(layers[0].assets.last);
        _generateAllImageThumbnails(layers[0].assets);
      }
    } else if (assetType == AssetType.text) {
      editingTextAsset = Asset(
        type: AssetType.text,
        begin: 0, // TODO:
        duration: 5000,
        title: '',
        srcPath: '',
      );
    } else if (assetType == AssetType.audio) {
      filePaths = await FilePicker.getMultiFilePath(type: FileType.AUDIO);
      if (filePaths == null) {
        isAdding = false;
        return;
      }
      List<File> fileList = _sortFilesByDate(filePaths);
      for (int i = 0; i < fileList.length; i++) {
        await _addAssetToLayer(2, AssetType.audio, fileList[i].path);
      }
    }
    isAdding = false;
  }

  _sortFilesByDate(Map<String, String> filePaths) {
    var fileList = filePaths.entries.map((entry) => File(entry.value)).toList();
    fileList.sort((file1, file2) {
      return file1.lastModifiedSync().compareTo(file2.lastModifiedSync());
    });
    return fileList;
  }

  _generateKenBurnEffects(Asset asset) {
    asset.kenBurnZSign = math.Random().nextInt(2) - 1;
    asset.kenBurnXTarget = (math.Random().nextInt(2) / 2).toDouble();
    asset.kenBurnYTarget = (math.Random().nextInt(2) / 2).toDouble();
    if (asset.kenBurnZSign == 0 &&
        asset.kenBurnXTarget == 0.5 &&
        asset.kenBurnYTarget == 0.5) {
      asset.kenBurnZSign = 1;
    }
  }

  _generateAllVideoThumbnails(List<Asset> assets) async {
    await _generateVideoThumbnails(assets, VideoResolution.mini);
    await _generateVideoThumbnails(assets, VideoResolution.sd);
  }

  _generateVideoThumbnails(
      List<Asset> assets, VideoResolution videoResolution) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    await Directory(p.join(appDocDir.path, 'thumbnails')).create();
    for (int i = 0; i < assets.length; i++) {
      Asset asset = assets[i];
      if (((videoResolution == VideoResolution.mini &&
                  asset.thumbnailPath == null) ||
              asset.thumbnailMedPath == null) &&
          !asset.deleted) {
        String thumbnailFileName =
            p.setExtension(asset.srcPath, '').split('/').last +
                '_pos_${asset.cutFrom}.jpg';
        String thumbnailPath =
            p.join(appDocDir.path, 'thumbnails', thumbnailFileName);
        thumbnailPath = await generator.generateVideoThumbnail(
            asset.srcPath, thumbnailPath, asset.cutFrom, videoResolution);

        if (videoResolution == VideoResolution.mini) {
          asset.thumbnailPath = thumbnailPath;
        } else {
          asset.thumbnailMedPath = thumbnailPath;
        }
        _layersChanged.add(true);
      }
    }
  }

  _generateAllImageThumbnails(List<Asset> assets) async {
    await _generateImageThumbnails(assets, VideoResolution.mini);
    await _generateImageThumbnails(assets, VideoResolution.sd);
  }

  _generateImageThumbnails(
      List<Asset> assets, VideoResolution videoResolution) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    await Directory(p.join(appDocDir.path, 'thumbnails')).create();
    for (int i = 0; i < assets.length; i++) {
      Asset asset = assets[i];
      if (((videoResolution == VideoResolution.mini &&
                  asset.thumbnailPath == null) ||
              asset.thumbnailMedPath == null) &&
          !asset.deleted) {
        String thumbnailFileName =
            p.setExtension(asset.srcPath, '').split('/').last + '_min.jpg';
        String thumbnailPath =
            p.join(appDocDir.path, 'thumbnails', thumbnailFileName);
        thumbnailPath = await generator.generateImageThumbnail(
            asset.srcPath, thumbnailPath, videoResolution);
        if (videoResolution == VideoResolution.mini) {
          asset.thumbnailPath = thumbnailPath;
        } else {
          asset.thumbnailMedPath = thumbnailPath;
        }
        _layersChanged.add(true);
      }
    }
  }

  editTextAsset() {
    if (assetSelected == null) return;
    if (assetSelected.type != AssetType.text) return;
    editingTextAsset = Asset.clone(assetSelected);
    scrollController.animateTo(assetSelected.begin / 1000 * pixelsPerSecond,
        duration: Duration(milliseconds: 300), curve: Curves.linear);
  }

  saveTextAsset() {
    if (editingTextAsset.title == '') {
      editingTextAsset.title = 'No title';
    }
    if (assetSelected == null) {
      editingTextAsset.begin = position;
      layers[1].assets.add(editingTextAsset);
      reorganizeTextAssets(1);
    } else {
      layers[1].assets[selected.assetIndex] = editingTextAsset;
    }
    _layersChanged.add(true);
    editingTextAsset = null;
  }

  reorganizeTextAssets(int layerIndex) {
    if (layers[layerIndex].assets.isEmpty) return;
    // After adding an asset in a position (begin = position),
    // it´s neccesary to sort
    layers[layerIndex].assets.sort((a, b) => a.begin - b.begin);

    // Configuring other assets and spaces after that
    for (int i = 1; i < layers[layerIndex].assets.length; i++) {
      Asset asset = layers[layerIndex].assets[i];
      Asset prevAsset = layers[layerIndex].assets[i - 1];

      if (prevAsset.title == '' && asset.title == '') {
        asset.begin = prevAsset.begin;
        asset.duration += prevAsset.duration;
        prevAsset.duration = 0; // To delete at the end
      } else if (prevAsset.title == '' && asset.title != '') {
        prevAsset.duration = asset.begin - prevAsset.begin;
      } else if (prevAsset.title != '' && asset.title == '') {
        asset.duration -= prevAsset.begin + prevAsset.duration - asset.begin;
        asset.duration = math.max(asset.duration, 0);
        asset.begin = prevAsset.begin + prevAsset.duration;
      } else if (prevAsset.title != '' && asset.title != '') {
        // Nothing, only insert space in a second loop if it´s neccesary
      }
    }

    // Remove duplicated spaces
    layers[layerIndex].assets.removeWhere((asset) => asset.duration <= 0);

    // Second loop to insert spaces between assets or move asset
    for (int i = 1; i < layers[layerIndex].assets.length; i++) {
      Asset asset = layers[layerIndex].assets[i];
      Asset prevAsset = layers[layerIndex].assets[i - 1];
      if (asset.begin > prevAsset.begin + prevAsset.duration) {
        Asset newAsset = Asset(
          type: AssetType.text,
          begin: prevAsset.begin + prevAsset.duration,
          duration: asset.begin - (prevAsset.begin + prevAsset.duration),
          title: '',
          srcPath: '',
        );
        layers[layerIndex].assets.insert(i, newAsset);
      } else {
        asset.begin = prevAsset.begin + prevAsset.duration;
      }
    }
    if (layers[layerIndex].assets.isNotEmpty &&
        layers[layerIndex].assets[0].begin > 0) {
      Asset newAsset = Asset(
        type: AssetType.text,
        begin: 0,
        duration: layers[layerIndex].assets[0].begin,
        title: '',
        srcPath: '',
      );
      layers[layerIndex].assets.insert(0, newAsset);
    }

    // Last space until video duration
    if (layers[layerIndex].assets.last.title == '') {
      layers[layerIndex].assets.last.duration =
          duration - layers[layerIndex].assets.last.begin;
    } else {
      Asset prevAsset = layers[layerIndex].assets.last;
      Asset asset = Asset(
        type: AssetType.text,
        begin: prevAsset.begin + prevAsset.duration,
        duration: duration - (prevAsset.begin + prevAsset.duration),
        title: '',
        srcPath: '',
      );
      layers[layerIndex].assets.add(asset);
    }
  }

  _addAssetToLayer(int layerIndex, AssetType type, String srcPath) async {
    print('_addAssetToLayer: $srcPath');

    int assetDuration;
    if (type == AssetType.video || type == AssetType.audio) {
      assetDuration = await generator.getVideoDuration(srcPath);
    } else {
      assetDuration = 5000;
    }

    layers[layerIndex].assets.add(Asset(
          type: type,
          srcPath: srcPath,
          title: p.basename(srcPath),
          duration: assetDuration,
          begin: layers[layerIndex].assets.isEmpty
              ? 0
              : layers[layerIndex].assets.last.begin +
                  layers[layerIndex].assets.last.duration,
        ));

    layerPlayers[layerIndex]?.addMediaSource(
        layers[layerIndex].assets.length - 1, layers[layerIndex].assets.last);

    _layersChanged.add(true);
    _appBar.add(true);
  }

  select(int layerIndex, int assetIndex) async {
    if (isOperating) return;
    if (layerIndex == 1 && layers[layerIndex].assets[assetIndex].title == '') {
      _selected.add(Selected(-1, -1));
    } else {
      _selected.add(Selected(layerIndex, assetIndex));
    }
    _appBar.add(true);
  }

  dragStart(layerIndex, assetIndex) {
    if (isOperating) return;
    if (layerIndex == 1 && layers[layerIndex].assets[assetIndex].title == '')
      return;
    isDragging = true;
    Selected sel = Selected(layerIndex, assetIndex);
    sel.initScrollOffset = scrollController.offset;
    _selected.add(sel);
    _appBar.add(true);
  }

  dragSelected(
      int layerIndex, int assetIndex, double dragX, double scrollWidth) {
    if (layerIndex == 1 && layers[layerIndex].assets[assetIndex].title == '')
      return;
    Asset assetSelected = layers[layerIndex].assets[assetIndex];
    int closest = assetIndex;
    int pos = assetSelected.begin +
        ((dragX + scrollController.offset - selected.initScrollOffset) /
                pixelsPerSecond *
                1000)
            .floor();
    if (dragX + scrollController.offset - selected.initScrollOffset < 0) {
      closest = getClosestAssetIndexLeft(layerIndex, assetIndex, pos);
    } else {
      pos = pos + assetSelected.duration;
      closest = getClosestAssetIndexRight(layerIndex, assetIndex, pos);
    }
    updateScrollOnDrag(pos, scrollWidth);
    Selected sel = Selected(layerIndex, assetIndex,
        dragX: dragX,
        closestAsset: closest,
        initScrollOffset: selected.initScrollOffset,
        incrScrollOffset: scrollController.offset - selected.initScrollOffset);
    _selected.add(sel);
  }

  updateScrollOnDrag(int pos, double scrollWidth) {
    double outOfScrollRight = pos * pixelsPerSecond / 1000 -
        scrollController.offset -
        scrollWidth / 2;
    double outOfScrollLeft = scrollController.offset -
        pos * pixelsPerSecond / 1000 -
        scrollWidth / 2 +
        32; // Layer header width: 32
    if (outOfScrollRight > 0 && outOfScrollLeft < 0) {
      scrollController.animateTo(
          scrollController.offset + math.min(outOfScrollRight, 50),
          duration: Duration(milliseconds: 100),
          curve: Curves.linear);
    }
    if (outOfScrollRight < 0 && outOfScrollLeft > 0) {
      scrollController.animateTo(
          scrollController.offset - math.min(outOfScrollLeft, 50),
          duration: Duration(milliseconds: 100),
          curve: Curves.linear);
    }
  }

  int getClosestAssetIndexLeft(int layerIndex, int assetIndex, int pos) {
    int closest = assetIndex;
    int distance = (pos - layers[layerIndex].assets[assetIndex].begin).abs();
    if (assetIndex < 1) return assetIndex;
    for (int i = assetIndex - 1; i >= 0; i--) {
      int d = (pos - layers[layerIndex].assets[i].begin).abs();
      if (d < distance) {
        closest = i;
        distance = d;
      }
    }
    return closest;
  }

  int getClosestAssetIndexRight(int layerIndex, int assetIndex, int pos) {
    int closest = assetIndex;
    int endAsset = layers[layerIndex].assets[assetIndex].begin +
        layers[layerIndex].assets[assetIndex].duration;
    int distance = (pos - endAsset).abs();
    if (assetIndex >= layers[layerIndex].assets.length - 1) return assetIndex;
    for (int i = assetIndex + 1; i < layers[layerIndex].assets.length; i++) {
      int end = layers[layerIndex].assets[i].begin +
          layers[layerIndex].assets[i].duration;
      int d = (pos - end).abs();
      if (d < distance) {
        closest = i;
        distance = d;
      }
    }
    return closest;
  }

  dragEnd() async {
    if (selected.layerIndex != 1) {
      await exchange();
    } else {
      moveTextAsset();
    }
    isDragging = false;
    _appBar.add(true);
  }

  exchange() async {
    int layerIndex = selected.layerIndex;
    int assetIndex1 = selected.assetIndex;
    int assetIndex2 = selected.closestAsset;
    // Reset selected before
    _selected.add(Selected(-1, -1));

    if (layerIndex == -1 ||
        assetIndex1 == -1 ||
        assetIndex2 == -1 ||
        assetIndex1 == assetIndex2) return;

    Asset asset1 = layers[layerIndex].assets[assetIndex1];

    layers[layerIndex].assets.removeAt(assetIndex1);
    await layerPlayers[layerIndex]?.removeMediaSource(assetIndex1);

    layers[layerIndex].assets.insert(assetIndex2, asset1);
    await layerPlayers[layerIndex]?.addMediaSource(assetIndex2, asset1);

    refreshCalculatedFieldsInAssets(layerIndex, 0);
    _layersChanged.add(true);

    // Delayed 100 because it seems updating mediaSources is not immediate
    Future.delayed(Duration(milliseconds: 100), () async {
      await _previewOnPosition();
    });
  }

  moveTextAsset() {
    int layerIndex = selected.layerIndex;
    int assetIndex = selected.assetIndex;
    if (layerIndex == -1 || assetIndex == -1) return;

    int pos = assetSelected.begin +
        ((selected.dragX +
                    scrollController.offset -
                    selected.initScrollOffset) /
                pixelsPerSecond *
                1000)
            .floor();

    // Reset selected before
    _selected.add(Selected(-1, -1));

    layers[layerIndex].assets[assetIndex].begin = math.max(pos, 0);
    reorganizeTextAssets(layerIndex);
    _layersChanged.add(true);
    _previewOnPosition();
  }

  cutVideo() async {
    if (isOperating) return;
    if (selected.layerIndex == -1 || selected.assetIndex == -1) return;
    print('>> DirectorService.cutVideo()');
    final Asset assetAfter =
        layers[selected.layerIndex].assets[selected.assetIndex];
    final int diff = position - assetAfter.begin;
    if (diff <= 0 || diff >= assetAfter.duration) return;
    isCutting = true;

    final Asset assetBefore = Asset.clone(assetAfter);
    layers[selected.layerIndex].assets.insert(selected.assetIndex, assetBefore);

    assetBefore.duration = diff;
    assetAfter.begin = assetBefore.begin + diff;
    assetAfter.cutFrom = assetBefore.cutFrom + diff;
    assetAfter.duration = assetAfter.duration - diff;

    layerPlayers[selected.layerIndex]?.removeMediaSource(selected.assetIndex);
    await layerPlayers[selected.layerIndex]
        ?.addMediaSource(selected.assetIndex, assetBefore);
    await layerPlayers[selected.layerIndex]
        ?.addMediaSource(selected.assetIndex + 1, assetAfter);

    _layersChanged.add(true);

    if (assetAfter.type == AssetType.video) {
      assetAfter.thumbnailPath = null;
      _generateAllVideoThumbnails(layers[selected.layerIndex].assets);
    }

    _selected.add(Selected(-1, -1));
    _appBar.add(true);

    // Delayed blocking 300 because it seems updating mediaSources is not immediate
    // because preview can fail
    Future.delayed(Duration(milliseconds: 300), () {
      isCutting = false;
    });
  }

  delete() {
    if (isOperating) return;
    if (selected.layerIndex == -1 || selected.assetIndex == -1) return;
    print('>> DirectorService.delete()');
    isDeleting = true;
    AssetType type = assetSelected.type;
    layers[selected.layerIndex].assets.removeAt(selected.assetIndex);
    layerPlayers[selected.layerIndex]?.removeMediaSource(selected.assetIndex);
    if (type != AssetType.text) {
      refreshCalculatedFieldsInAssets(selected.layerIndex, selected.assetIndex);
    }
    _layersChanged.add(true);

    _selected.add(Selected(-1, -1));

    _filesNotExist.add(checkSomeFileNotExists());
    reorganizeTextAssets(1);

    isDeleting = false;

    if (position > duration) {
      _position.add(duration);
      scrollController.jumpTo(duration / 1000 * pixelsPerSecond);
    }
    _layersChanged.add(true);
    _appBar.add(true);
    // TODO: remove thumbnails not used

    // Delayed because it seems updating mediaSources is not immediate
    Future.delayed(Duration(milliseconds: 100), () {
      _previewOnPosition();
    });
  }

  refreshCalculatedFieldsInAssets(int layerIndex, int assetIndex) {
    for (int i = assetIndex; i < layers[layerIndex].assets.length; i++) {
      layers[layerIndex].assets[i].begin = (i == 0)
          ? 0
          : layers[layerIndex].assets[i - 1].begin +
              layers[layerIndex].assets[i - 1].duration;
    }
  }

  scaleStart() {
    if (isOperating) return;
    isScaling = true;
    _selected.add(Selected(-1, -1));
    _pixelsPerSecondOnInitScale = pixelsPerSecond;
    _scrollOffsetOnInitScale = scrollController.offset;
  }

  scaleUpdate(double scale) {
    if (!isScaling || _pixelsPerSecondOnInitScale == null) return;
    double pixPerSecond = _pixelsPerSecondOnInitScale * scale;
    pixPerSecond = math.min(pixPerSecond, 100);
    pixPerSecond = math.max(pixPerSecond, 1);
    _pixelsPerSecond.add(pixPerSecond);
    _layersChanged.add(true);
    scrollController.jumpTo(
        _scrollOffsetOnInitScale * pixPerSecond / _pixelsPerSecondOnInitScale);
  }

  scaleEnd() {
    isScaling = false;
    _layersChanged.add(true);
  }

  Asset getAssetByPosition(int layerIndex) {
    if (position == null) return null;
    for (int i = 0; i < layers[layerIndex].assets.length; i++) {
      if (layers[layerIndex].assets[i].begin +
              layers[layerIndex].assets[i].duration -
              1 >=
          position) {
        return layers[layerIndex].assets[i];
      }
    }
    return null;
  }

  sizerDragStart(bool sizerEnd) {
    if (isOperating) return;
    isSizerDragging = true;
    isSizerDraggingEnd = sizerEnd;
    dxSizerDrag = 0;
  }

  sizerDragUpdate(bool sizerEnd, double dx) {
    dxSizerDrag += dx;
    _selected.add(selected); // To refresh UI
  }

  sizerDragEnd(bool sizerEnd) async {
    await executeSizer(sizerEnd);
    _selected.add(selected); // To refresh UI
    dxSizerDrag = 0;
    isSizerDragging = false;
  }

  executeSizer(bool sizerEnd) async {
    Asset asset = assetSelected;
    if (asset == null) return;
    if (asset.type == AssetType.text || asset.type == AssetType.image) {
      int dxSizerDragMillis = (dxSizerDrag / pixelsPerSecond * 1000).floor();
      if (!isSizerDraggingEnd) {
        if (asset.begin + dxSizerDragMillis < 0) {
          dxSizerDragMillis = -asset.begin;
        }
        if (asset.duration - dxSizerDragMillis < 1000) {
          dxSizerDragMillis = asset.duration - 1000;
        }
        asset.begin += dxSizerDragMillis;
        asset.duration -= dxSizerDragMillis;
      } else {
        if (asset.duration + dxSizerDragMillis < 1000) {
          dxSizerDragMillis = -asset.duration + 1000;
        }
        asset.duration += dxSizerDragMillis;
      }
      if (asset.type == AssetType.text) {
        reorganizeTextAssets(1);
      } else if (asset.type == AssetType.image) {
        refreshCalculatedFieldsInAssets(
            selected.layerIndex, selected.assetIndex);
        await layerPlayers[selected.layerIndex]
            ?.removeMediaSource(selected.assetIndex);
        await layerPlayers[selected.layerIndex]
            ?.addMediaSource(selected.assetIndex, asset);
      }
      _selected.add(Selected(-1, -1));
    }
    _layersChanged.add(true);
  }

  generateVideo(List<Layer> layers, VideoResolution videoResolution,
      {int framerate}) async {
    if (filesNotExist) {
      _filesNotExist.add(true);
      return false;
    }
    isGenerating = true;
    _layersChanged.add(true); // Hide images for memory
    String outputFile =
        await generator.generateVideoAll(layers, videoResolution);
    if (outputFile != null) {
      DateTime date = DateTime.now();
      String dateStr = generator.dateTimeString(date);
      String resolutionStr = generator.videoResolutionString(videoResolution);
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String thumbnailPath =
          p.join(appDocDir.path, 'thumbnails', 'generated-$dateStr.jpg');
      thumbnailPath = await generator.generateVideoThumbnail(
          outputFile, thumbnailPath, 0, VideoResolution.sd);

      projectDao.insertGeneratedVideo(GeneratedVideo(
        projectId: project.id,
        path: outputFile,
        date: date,
        resolution: resolutionStr,
        thumbnail: thumbnailPath,
      ));
    }
    isGenerating = false;
    _layersChanged.add(true); // Show images
  }

  _deleteThumbnailsNotUsed() async {
    // TODO: pending to implement
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Directory fontsDir = Directory(p.join(appDocDir.parent.path, 'code_cache'));

    List<FileSystemEntity> entityList =
        fontsDir.listSync(recursive: true, followLinks: false);
    for (FileSystemEntity entity in entityList) {
      if (!await FileSystemEntity.isFile(entity.path) &&
          entity.path.split('/').last.startsWith('open_director')) {}
      //print(entity.path);
    }
  }
}
