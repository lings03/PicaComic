import 'dart:async';
import 'dart:io';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/image_manager.dart';
import '../../tools/io_tools.dart';
import '../download_model.dart';

class NhentaiDownloadedComic extends DownloadedItem {
  NhentaiDownloadedComic(
      this.comicID, this.title, this.size, this.cover, this.tags);

  final String comicID;

  final String title;

  final double? size;

  final String cover;

  @override
  double? get comicSize => size;

  @override
  List<int> get downloadedEps => [0];

  @override
  List<String> get eps => ["第一章".tl];

  @override
  String get id => comicID;

  @override
  String get name => title;

  @override
  String get subTitle => "";

  @override
  DownloadType get type => DownloadType.nhentai;

  @override
  Map<String, dynamic> toJson() =>
      {'comicID': comicID, 'title': title, 'size': size, 'cover': cover};

  NhentaiDownloadedComic.fromJson(Map<String, dynamic> json)
      : comicID = json["comicID"],
        title = json["title"],
        size = json["size"],
        tags = List.from(json["tags"] ?? []),
        cover = json["cover"];

  @override
  set comicSize(double? value) {}

  @override
  List<String> tags;
}

class NhentaiDownloadingItem extends DownloadingItem {
  NhentaiDownloadingItem(
      this.comic, super.whenFinish, super.whenError, super.updateInfo, super.id,
      {super.type = DownloadType.nhentai});

  final NhentaiComic comic;

  @override
  String get cover => comic.cover;

  @override
  Future<Map<int, List<String>>> getLinks() async {
    var res = await NhentaiNetwork().getImages(comic.id);
    return {0: res.data};
  }

  @override
  Stream<DownloadProgress> downloadImage(String link) {
    return ImageManager().getImage(link);
  }

  @override
  String get title => comic.title;

  @override
  Map<String, dynamic> toMap() =>
      {"comic": comic.toMap(), ...super.toBaseMap()};

  NhentaiDownloadingItem.fromMap(
      super.map,
      DownloadProgressCallback super.whenFinish,
      DownloadProgressCallback super.whenError,
      DownloadProgressCallbackAsync super.updateInfo,
      String id)
      : comic = NhentaiComic.fromMap(map["comic"]),
        super.fromMap();

  @override
  FutureOr<DownloadedItem> toDownloadedItem() async {
    return NhentaiDownloadedComic(
      id,
      title,
      await getFolderSize(Directory(path)),
      comic.cover,
      comic.tags["tags"] ?? [],
    );
  }
}
