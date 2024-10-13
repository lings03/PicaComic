import 'dart:async';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import '../download.dart';
import 'methods.dart';
import 'dart:io';

class DownloadedComic extends DownloadedItem {
  ComicItem comicItem;
  List<String> chapters;
  List<int> downloadedChapters;
  double? size;

  DownloadedComic(
      this.comicItem, this.chapters, this.size, this.downloadedChapters);

  @override
  Map<String, dynamic> toJson() => {
        "comicItem": comicItem.toJson(),
        "chapters": chapters,
        "size": size,
        "downloadedChapters": downloadedChapters
      };

  DownloadedComic.fromJson(Map<String, dynamic> json)
      : comicItem = ComicItem.fromJson(json["comicItem"]),
        chapters = List<String>.from(json["chapters"]),
        size = json["size"],
        downloadedChapters = [] {
    if (json["downloadedChapters"] == null) {
      //旧版本中的数据不包含这一项
      for (int i = 0; i < chapters.length; i++) {
        downloadedChapters.add(i);
      }
    } else {
      downloadedChapters = List<int>.from(json["downloadedChapters"]);
    }
  }

  @override
  DownloadType get type => DownloadType.picacg;

  @override
  List<int> get downloadedEps => downloadedChapters;

  @override
  List<String> get eps => chapters.getNoBlankList();

  @override
  String get name => comicItem.title;

  @override
  String get id => comicItem.id;

  @override
  String get subTitle => comicItem.author;

  @override
  double? get comicSize => size;

  @override
  set comicSize(double? value) => size = value;

  @override
  List<String> get tags => comicItem.tags;
}

///picacg的下载进程模型
class PicDownloadingItem extends DownloadingItem {
  PicDownloadingItem(this.comic, this._downloadEps, super.whenFinish,
      super.whenError, super.updateInfo, super.id,
      {super.type = DownloadType.picacg});

  ///漫画模型
  final ComicItem comic;

  ///章节名称
  var _eps = <String>[];

  ///要下载的章节序号
  final List<int> _downloadEps;

  ///获取各章节名称
  List<String> get eps => _eps;

  @override
  get cover => getImageUrl(comic.thumbUrl);

  @override
  String get title => comic.title;

  @override
  Future<Map<int, List<String>>> getLinks() async {
    var res = <int, List<String>>{};
    _eps = (await network.getEps(id)).data;
    for (var i in _downloadEps) {
      res[i + 1] = (await network.getComicContent(id, i + 1)).data;
    }
    return res;
  }

  @override
  Stream<DownloadProgress> downloadImage(String link) {
    return ImageManager().getImage(getImageUrl(link));
  }

  @override
  Map<String, dynamic> toMap() => {
        "comic": comic.toJson(),
        "_eps": _eps,
        "_downloadEps": _downloadEps,
        ...super.toBaseMap()
      };

  PicDownloadingItem.fromMap(
      super.map,
      DownloadProgressCallback super.whenFinish,
      DownloadProgressCallback super.whenError,
      DownloadProgressCallbackAsync super.updateInfo,
      String id)
      : comic = ComicItem.fromJson(map["comic"]),
        _eps = List<String>.from(map["_eps"]),
        _downloadEps = List<int>.from(map["_downloadEps"]),
        super.fromMap();

  @override
  FutureOr<DownloadedItem> toDownloadedItem() async {
    var previous = <int>[];
    if (DownloadManager().isExists(id)) {
      var comic =
          (await DownloadManager().getComicOrNull(id))! as DownloadedComic;
      previous = comic.downloadedEps;
    }
    var downloaded = (_downloadEps + previous).toSet().toList();
    downloaded.sort();
    return DownloadedComic(
      comic,
      eps,
      await getFolderSize(Directory(path)),
      downloaded,
    );
  }
}
