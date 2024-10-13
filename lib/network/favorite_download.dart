import 'dart:async';

import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/custom_download_model.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/network/eh_network/eh_download_model.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_download_model.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/htmanga_network/ht_download_model.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_download.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/nhentai_network/download.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/picacg_network/picacg_download_model.dart';

class FavoriteDownloading extends DownloadingItem{
  FavoriteDownloading(this.comic, super.whenFinish, super.onError,
      super.updateInfo, super.id, {super.type = DownloadType.favorite});

  FavoriteItem comic;

  late DownloadingItem downloadLogic;

  @override
  void start() async{
    await onStart();
    downloadLogic.start();
  }

  @override
  Future<void> onStart() async{
    try {
      switch(comic.type.key){
        case 0: {
          var comicItem = await PicacgNetwork().getComicInfo(comic.target);
          downloadLogic = PicDownloadingItem(
              comicItem.data, List.generate(comicItem.data.eps.length,
                  (index) => index), onFinish, onError, updateInfo, id);
        }
        case 1: {
          var gallery = await EhNetwork().getGalleryInfo(comic.target);
          downloadLogic = EhDownloadingItem(gallery.data,
              onFinish, onError, updateInfo, id, 0);
        }
        case 2: {
          var jmComic = await JmNetwork().getComicInfo(comic.target);
          var downloadedEp = List.generate(jmComic.data.epNames.length, (index) => index);
          if(downloadedEp.isEmpty) {
            downloadedEp.add(0);
          }
          downloadLogic = JmDownloadingItem(jmComic.data, downloadedEp,
              onFinish, onError, updateInfo, id);
        }
        case 3: {
          var hitomiComic = await HiNetwork().getComicInfo(comic.target);
          downloadLogic = HitomiDownloadingItem(hitomiComic.data,
              comic.coverPath, comic.target, onFinish, onError, updateInfo, id);
        }
        case 4: {
          var htComic = await HtmangaNetwork().getComicInfo(comic.target);
          downloadLogic = DownloadingHtComic(htComic.data, onFinish, onError, updateInfo, id);
        }
        case 6: {
          var nhComic = await NhentaiNetwork().getComicInfo(comic.target);
          downloadLogic = NhentaiDownloadingItem(nhComic.data, onFinish, onError, updateInfo, id);
        }
        default: {
          var comicSource = comic.type.comicSource;
          var comicInfoData = await comicSource.loadComicInfo!(comic.target);
          var downloadedEp = List.generate(comicInfoData.data.chapters?.length ?? 0, (index) => index);
          downloadLogic = CustomDownloadingItem(comicInfoData.data, downloadedEp,
              onFinish, onError, updateInfo, id);
        }
      }
    }
    catch(e, s) {
      Log.error("Download", "$e$s");
      onError?.call();
      return;
    }
    pause();
    DownloadManager().downloading.removeFirst();
    DownloadManager().downloading.addFirst(downloadLogic);
    downloadLogic.start();
  }

  @override
  String get cover => comic.coverPath;

  @override
  Future<Map<int, List<String>>> getLinks() => downloadLogic.getLinks();

  @override
  String get title => comic.name;

  @override
  Map<String, dynamic> toMap() {
    return {
      "comic": comic.toJson(),
      ...toBaseMap()
    };
  }

  FavoriteDownloading.fromMap(super.json,
      DownloadProgressCallback super.whenFinish,
      DownloadProgressCallback super.whenError,
      DownloadProgressCallbackAsync super.updateInfo,
      String id)
      : comic = FavoriteItem.fromJson(json["comic"]),
        super.fromMap();

  @override
  FutureOr<DownloadedItem> toDownloadedItem() =>
      downloadLogic.toDownloadedItem();

  @override
  Stream<DownloadProgress> downloadImage(String link) {
    return downloadLogic.downloadImage(link);
  }
}