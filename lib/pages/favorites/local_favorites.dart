import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/pre_search_page.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/pages/download_page.dart';
import 'main_favorites_page.dart';
import 'network_to_local.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/components/components.dart';
import 'dart:io';
import '../../foundation/app.dart';
import '../../network/eh_network/eh_main_network.dart';
import '../../network/hitomi_network/hitomi_main_network.dart';
import '../../network/htmanga_network/htmanga_main_network.dart';
import '../../network/jm_network/jm_network.dart';
import '../../network/nhentai_network/nhentai_main_network.dart';
import '../../network/picacg_network/methods.dart';
import '../../tools/io_tools.dart';

extension LocalFavoritesExt on FavoriteItem {
  void addDownload() {
    if (DownloadManager().isExists(toDownloadId())) {
      return;
    }
    try {
      DownloadManager().addFavoriteDownload(this);
    } catch (e) {
      log("Failed to add a download.\n Missing comic source config file.",
          "Download", LogLevel.error);
    }
  }

  Future<bool> updateInfo(String folder) async {
    if (type == FavoriteType.picacg) {
      var res = await PicacgNetwork().getComicInfo(target);
      if (res.error) return false;
      name = res.data.title;
      author = res.data.author;
      tags = res.data.tags;
      coverPath = res.data.cover;
    } else if (type == FavoriteType.ehentai) {
      var res = await EhNetwork().getGalleryInfo(target);
      if (res.error) return false;
      name = res.data.title;
      coverPath = res.data.cover;
    } else if (type == FavoriteType.jm) {
      var res = await JmNetwork().getComicInfo(target);
      if (res.error) return false;
      name = res.data.title;
      author = res.data.author.firstOrNull ?? '';
      tags = res.data.tags;
      coverPath = res.data.cover;
    } else if (type == FavoriteType.nhentai) {
      var res = await NhentaiNetwork().getComicInfo(target);
      if (res.error) return false;
      name = res.data.title;
      coverPath = res.data.cover;
    } else if (type == FavoriteType.htManga) {
      var res = await HtmangaNetwork().getComicInfo(target);
      if (res.error) return false;
      name = res.data.title;
      author = res.data.uploader;
      coverPath = res.data.cover;
    } else if (type == FavoriteType.hitomi) {
      var res = await HiNetwork().getComicInfo(target);
      if (res.error) return false;
      name = res.data.title;
      author = res.data.subTitle;
      coverPath = res.data.cover;
    } else {
      var comicSource = type.comicSource;
      var res = await comicSource.loadComicInfo!(target);
      if (res.error) return false;
      name = res.data.title;
      author = res.data.subTitle ?? '';
      coverPath = res.data.cover;
    }
    LocalFavoritesManager().updateInfo(folder, this);
    return true;
  }
}

class UpdateFavoritesInfoDialog extends StatefulWidget {
  const UpdateFavoritesInfoDialog(
      {super.key, required this.comics, required this.folder});

  final List<FavoriteItem> comics;

  final String folder;

  static show(List<FavoriteItem> comics, String folder) {
    showDialog(
      context: App.globalContext!,
      builder: (context) =>
          UpdateFavoritesInfoDialog(comics: comics, folder: folder),
    );
  }

  @override
  State<UpdateFavoritesInfoDialog> createState() =>
      _UpdateFavoritesInfoDialogState();
}

class _UpdateFavoritesInfoDialogState extends State<UpdateFavoritesInfoDialog> {
  int finished = 0;

  int get total => widget.comics.length;

  bool cancel = false;

  void load() async {
    for (var comic in widget.comics) {
      if (cancel) return;
      if (await comic.updateInfo(widget.folder)) {
        finished++;
      }
      if (!cancel) {
        setState(() {});
      }
    }
    if (mounted) {
      StateController.findOrNull<SimpleController>(
              tag: "ComicsPageView ${widget.folder}")
          ?.refresh();
      context.pop();
    }
  }

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  void dispose() {
    cancel = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: "更新漫画信息".tl,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: finished / total,
          ),
          const SizedBox(
            height: 8,
          ),
          Text("$finished/$total").toAlign(Alignment.centerRight),
        ],
      ).paddingHorizontal(24).paddingVertical(12),
      actions: [
        Button.filled(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("取消".tl),
        ),
      ],
    );
  }
}

class CreateFolderDialog extends StatelessWidget {
  const CreateFolderDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return SimpleDialog(
      title: Text("创建收藏夹".tl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextField(
            controller: controller,
            onEditingComplete: () {
              try {
                LocalFavoritesManager().createFolder(controller.text);
                App.globalBack();
              } catch (e) {
                showToast(message: e.toString());
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "名称".tl,
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        SizedBox(
          width: 260,
          child: Row(
            children: [
              const Spacer(),
              TextButton(
                child: Text("从文件导入".tl),
                onPressed: () async {
                  context.pop();
                  var data = await getDataFromUserSelectedFile(["json"]);
                  if (data == null) {
                    return;
                  }
                  var (error, message) =
                      LocalFavoritesManager().loadFolderData(data);
                  if (error) {
                    showToast(message: message);
                  } else {
                    StateController.find(tag: "me page").update();
                  }
                },
              ),
              const Spacer(),
              TextButton(
                child: Text("从网络导入".tl),
                onPressed: () async {
                  App.globalBack();
                  await Future.delayed(const Duration(milliseconds: 200));
                  networkToLocal();
                },
              ),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        SizedBox(
            height: 35,
            child: Center(
              child: FilledButton(
                  onPressed: () {
                    try {
                      LocalFavoritesManager().createFolder(controller.text);
                      App.globalBack();
                    } catch (e) {
                      showToast(message: e.toString());
                    }
                  },
                  child: Text("提交".tl)),
            ))
      ],
    );
  }
}

class RenameFolderDialog extends StatelessWidget {
  const RenameFolderDialog(this.before, {super.key});

  final String before;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return SimpleDialog(
      title: Text("重命名".tl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextField(
            controller: controller,
            onEditingComplete: () {
              try {
                LocalFavoritesManager().rename(before, controller.text);
                context.pop();
              } catch (e) {
                showToast(message: e.toString());
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "名称".tl,
            ),
          ),
        ),
        const SizedBox(
          width: 200,
          height: 10,
        ),
        SizedBox(
            height: 35,
            child: Center(
              child: TextButton(
                  onPressed: () {
                    try {
                      LocalFavoritesManager().rename(before, controller.text);
                      context.pop();
                    } catch (e) {
                      showToast(message: e.toString());
                    }
                  },
                  child: Text("提交".tl)),
            ))
      ],
    );
  }
}

class LocalFavoriteTile extends ComicTile {
  const LocalFavoriteTile(
      this.comic, this.folderName, this.onDelete, this._enableLongPressed,
      {this.showFolderInfo = false, this.onLongPressed, this.onTap, super.key});

  final FavoriteItem comic;

  final String folderName;

  final void Function() onDelete;

  /// return true to disable default action
  final bool Function()? onTap;

  final bool _enableLongPressed;

  final void Function()? onLongPressed;

  final bool showFolderInfo;

  static Map<String, File> cache = {};

  @override
  String? get badge =>
      DownloadManager().isExists(comic.toDownloadId()) ? "已下载".tl : null;

  @override
  bool get enableLongPressed => _enableLongPressed;

  @override
  String get description => "${comic.time} | ${comic.type.name}";

  @override
  bool get showFavorite => false;

  @override
  Widget get image => () {
        if (DownloadManager().isExists(comic.toDownloadId())) {
          return Image.file(
            DownloadManager().getCover(comic.toDownloadId()),
            fit: BoxFit.cover,
            height: double.infinity,
            filterQuality: FilterQuality.medium,
          );
        } else if (cache[comic.target] == null) {
          return FutureBuilder<File>(
            future: LocalFavoritesManager().getCover(comic),
            builder: (context, file) {
              Widget child;
              if (file.hasError) {
                LogManager.addLog(
                    LogLevel.error, "Network", file.stackTrace.toString());
                child = const Center(
                  child: Icon(Icons.error),
                );
              } else if (file.data == null) {
                child = ColoredBox(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: const SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                    ));
              } else {
                cache[comic.target] = file.data!;
                child = Image.file(
                  file.data!,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  filterQuality: FilterQuality.medium,
                );
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: child,
              );
            },
          );
        } else {
          return Image.file(
            cache[comic.target]!,
            fit: BoxFit.cover,
            height: double.infinity,
            filterQuality: FilterQuality.medium,
          );
        }
      }();

  BuildContext get context => App.mainNavigatorKey!.currentContext!;

  void showInfo() {
    context.to(
      () => ComicPage(
          sourceKey: comic.type.comicSource.key,
          id: comic.target,
          cover: comic.coverPath),
    );
  }

  @override
  String get subTitle => comic.author;

  @override
  String get title => comic.name;

  List<String> _generateTags(List<String> tags) {
    if (App.locale.languageCode != "zh") {
      return tags;
    }
    List<String> res = [];
    List<String> res2 = [];
    for (var tag in tags) {
      if (tag.contains(":")) {
        var splits = tag.split(":");
        var lowLevelKey = ["character", "artist", "cosplayer", "group"];
        if (lowLevelKey.contains(splits[0])) {
          res2.add(splits[1].translateTagsToCN);
        } else {
          res.add(splits[1].translateTagsToCN);
        }
      } else {
        var name = tag;
        if (name.contains('♀')) {
          name = "${name.replaceFirst(" ♀", "").translateTagsToCN}♀";
        } else if (name.contains('♂')) {
          name = "${name.replaceFirst(" ♂", "").translateTagsToCN}♂";
        } else {
          name = name.translateTagsToCN;
        }
        res.add(name);
      }
    }
    return res + res2;
  }

  @override
  List<String>? get tags => _generateTags(comic.tags);

  @override
  void onSecondaryTap_(TapDownDetails details) {
    showDesktopMenu(
      App.globalContext!,
      Offset(details.globalPosition.dx, details.globalPosition.dy),
      [
        DesktopMenuEntry(
          text: "查看".tl,
          onClick: () =>
              Future.delayed(const Duration(milliseconds: 200), showInfo),
        ),
        DesktopMenuEntry(
          text: "阅读".tl,
          onClick: () =>
              Future.delayed(const Duration(milliseconds: 200), read),
        ),
        DesktopMenuEntry(
          text: "搜索".tl,
          onClick: () => Future.delayed(
            const Duration(milliseconds: 200),
            () {
              if (context.mounted) {
                context.to(
                  () => PreSearchPage(
                    initialValue: title,
                  ),
                );
              }
            },
          ),
        ),
        DesktopMenuEntry(
          text: "取消收藏".tl,
          onClick: () {
            LocalFavoritesManager().deleteComic(folderName, comic);
            onDelete();
          },
        ),
        DesktopMenuEntry(
          text: "复制到".tl,
          onClick: copyTo,
        ),
        DesktopMenuEntry(
          text: "编辑标签".tl,
          onClick: editTags,
        ),
        DesktopMenuEntry(
          text: "下载".tl,
          onClick: () {
            comic.addDownload();
            showToast(message: "已添加下载任务".tl);
          },
        ),
        DesktopMenuEntry(
          text: "更新漫画信息".tl,
          onClick: () {
            UpdateFavoritesInfoDialog.show([comic], folderName);
          },
        ),
      ],
    );
  }

  @override
  void onLongTap_() {
    if (onLongPressed != null) {
      onLongPressed!();
    } else {
      showMenu();
    }
  }

  void showMenu() {
    showDialog(
        context: App.globalContext!,
        builder: (context) => Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: SelectableText(
                        title.replaceAll("\n", ""),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.article),
                      title: Text("查看详情".tl),
                      onTap: () {
                        App.back(context);
                        showInfo();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.bookmark_remove),
                      title: Text("取消收藏".tl),
                      onTap: () {
                        App.globalBack();
                        LocalFavoritesManager().deleteComic(folderName, comic);
                        onDelete();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.chrome_reader_mode_rounded),
                      title: Text("阅读".tl),
                      onTap: () {
                        App.globalBack();
                        read();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.copy),
                      title: Text("复制到".tl),
                      onTap: () {
                        App.globalBack();
                        copyTo();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_note),
                      title: Text("编辑标签".tl),
                      onTap: () {
                        App.globalBack();
                        editTags();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: Text("下载".tl),
                      onTap: () {
                        App.globalBack();
                        comic.addDownload();
                        showToast(message: "已添加下载任务".tl);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.update),
                      title: Text("更新漫画信息".tl),
                      onTap: () {
                        App.globalBack();
                        UpdateFavoritesInfoDialog.show([comic], folderName);
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                  ],
                ),
              ),
            ));
  }

  void readComic() async {
    if (DownloadManager().isExists(comic.toDownloadId())) {
      var download =
          await DownloadManager().getComicOrNull(comic.toDownloadId());
      if (download != null) {
        download.read();
        return;
      }
    }
    bool cancel = false;
    var controller = showLoadingDialog(
      App.globalContext!,
      onCancel: () => cancel = true,
      barrierDismissible: false,
    );
    switch (comic.type.comicType) {
      case ComicType.picacg:
        {
          var res = await network.getEps(comic.target);
          if (cancel) return;
          controller.close();
          if (res.error) {
            showToast(message: res.errorMessage ?? "Error");
          } else {
            var history = await HistoryManager().find(comic.target);
            if (history == null) {
              history = History(
                HistoryType.picacg,
                DateTime.now(),
                comic.name,
                comic.author,
                comic.coverPath,
                0,
                0,
                comic.target,
              );
              await HistoryManager().addHistory(history);
            }
            App.globalTo(
              () => ComicReadingPage.picacg(
                comic.target,
                history!.ep,
                res.data,
                comic.name,
                initialPage: history.page,
              ),
            );
          }
        }
      case ComicType.ehentai:
        {
          var res = await EhNetwork().getGalleryInfo(comic.target);
          if (cancel) return;
          controller.close();
          if (res.error) {
            showToast(message: res.errorMessage ?? "Error");
          } else {
            var history = await History.findOrCreate(res.data);
            App.globalTo(
              () => ComicReadingPage.ehentai(
                res.data,
                initialPage: history.page,
              ),
            );
          }
        }
      case ComicType.jm:
        {
          var res = await JmNetwork().getComicInfo(comic.target);
          if (cancel) return;
          controller.close();
          if (res.error) {
            showToast(message: res.errorMessage ?? "Error");
          } else {
            var history = await History.findOrCreate(res.data);
            App.globalTo(
              () => ComicReadingPage.jmComic(
                res.data,
                history.ep,
                initialPage: history.page,
              ),
            );
          }
        }
      case ComicType.hitomi:
        {
          var res = await HiNetwork().getComicInfo(comic.target);
          if (cancel) return;
          controller.close();
          if (res.error) {
            showToast(message: res.errorMessage ?? "Error");
          } else {
            var history = await History.findOrCreate(res.data);
            App.globalTo(
              () => ComicReadingPage.hitomi(
                res.data,
                comic.target,
                initialPage: history.page,
              ),
            );
          }
        }
      case ComicType.htManga:
        {
          var res = await HtmangaNetwork().getComicInfo(comic.target);
          if (cancel) return;
          controller.close();
          if (res.error) {
            showToast(message: res.errorMessage ?? "Error");
          } else {
            var history = await History.findOrCreate(res.data);
            App.globalTo(
              () => ComicReadingPage.htmanga(
                res.data.id,
                comic.name,
                initialPage: history.page,
              ),
            );
          }
        }
      case ComicType.nhentai:
        {
          var res = await NhentaiNetwork().getComicInfo(comic.target);
          if (cancel) return;
          controller.close();
          if (res.error) {
            showToast(message: res.errorMessage ?? "Error");
          } else {
            var history = await History.findOrCreate(res.data);
            App.globalTo(
              () => ComicReadingPage.nhentai(
                res.data.id,
                res.data.title,
                initialPage: history.page,
              ),
            );
          }
        }
      default:
        {
          var res = await comic.type.comicSource.loadComicInfo!(comic.target);
          if (cancel) return;
          controller.close();
          if (res.error) {
            showToast(message: res.errorMessage ?? "Error");
          } else {
            var history = await History.findOrCreate(res.data);
            App.globalTo(
              () => ComicReadingPage(
                CustomReadingData(
                  res.data.target,
                  res.data.title,
                  comic.type.comicSource,
                  res.data.chapters,
                ),
                history.page,
                history.ep,
              ),
            );
          }
        }
    }
  }

  @override
  ActionFunc get read => readComic;

  void copyTo() {
    String? folder;
    showDialog(
        context: App.globalContext!,
        builder: (context) => SimpleDialog(
              title: Text("复制到".tl),
              children: [
                SizedBox(
                  width: 280,
                  height: 132,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("收藏夹".tl),
                        trailing: Select(
                          outline: true,
                          width: 156,
                          values: LocalFavoritesManager().folderNames,
                          initialValue: null,
                          onChange: (i) =>
                              folder = LocalFavoritesManager().folderNames[i],
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: FilledButton(
                          child: Text("确认".tl),
                          onPressed: () {
                            LocalFavoritesManager().addComic(folder!, comic);
                            App.globalBack();
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                    ],
                  ),
                )
              ],
            ));
  }

  @override
  void onTap_() {
    if (onTap != null) {
      var res = onTap!();
      if (res) return;
    }
    if (!comic.available) {
      showToast(message: "无效的漫画".tl);
      return;
    }
    if (appdata.settings[60] == "0") {
      showInfo();
    } else {
      read();
    }
  }

  @override
  String get comicID => comic.target;

  void editTags() {
    showDialog(
        context: App.globalContext!,
        builder: (context) {
          var tags = comic.tags;
          var controller = TextEditingController();
          return SimpleDialog(
            elevation: 1,
            title: Text("编辑标签".tl),
            children: [
              StatefulBuilder(
                  builder: (context, setState) => SizedBox(
                        width: 400,
                        child: Column(
                          children: [
                            Wrap(
                              children: tags
                                  .map((e) => Container(
                                        margin: const EdgeInsets.all(4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(e),
                                            const SizedBox(
                                              width: 4,
                                            ),
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: const Icon(
                                                Icons.close,
                                                size: 20,
                                              ),
                                              onTap: () {
                                                tags.remove(e);
                                                setState(() {});
                                              },
                                            )
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            SizedBox(
                              height: 56,
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  border: const UnderlineInputBorder(),
                                  suffix: IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      var value = controller.text;
                                      if (value.isNotEmpty) {
                                        controller.clear();
                                        tags.add(value);
                                        setState(() {});
                                      }
                                    },
                                  ).paddingTop(8),
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    tags.add(value);
                                    controller.clear();
                                    setState(() {});
                                  }
                                },
                              ),
                            ).paddingHorizontal(36),
                            const SizedBox(
                              height: 16,
                            ),
                            Center(
                              child: FilledButton(
                                  onPressed: () {
                                    LocalFavoritesManager().editTags(
                                        comic.target, folderName, tags);
                                    App.globalBack();
                                    StateController.findOrNull<
                                            FavoritesPageController>()
                                        ?.update();
                                    StateController.findOrNull(
                                            tag: "local_search_page")
                                        ?.update();
                                  },
                                  child: Text("提交".tl)),
                            )
                          ],
                        ),
                      ))
            ],
          );
        });
  }
}

void copyAllTo(String source, List<FavoriteItem> comics) {
  String? folder;
  showDialog(
      context: App.globalContext!,
      builder: (context) => SimpleDialog(
            title: Text("复制到".tl),
            children: [
              SizedBox(
                width: 280,
                height: 132,
                child: Column(
                  children: [
                    ListTile(
                      title: Text("收藏夹".tl),
                      trailing: Select(
                        outline: true,
                        width: 156,
                        values: LocalFavoritesManager().folderNames,
                        initialValue: null,
                        onChange: (i) =>
                            folder = LocalFavoritesManager().folderNames[i],
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: FilledButton(
                        child: Text("确认".tl),
                        onPressed: () {
                          for (var comic in comics) {
                            LocalFavoritesManager().addComic(
                                folder!,
                                LocalFavoritesManager().getComic(
                                    source, comic.target, comic.type));
                          }
                          App.globalBack();
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                  ],
                ),
              )
            ],
          ));
}

class LocalFavoritesFolder extends StatefulWidget {
  const LocalFavoritesFolder(this.name, {super.key});

  final String name;

  @override
  State<LocalFavoritesFolder> createState() => _LocalFavoritesFolderState();
}

class _LocalFavoritesFolderState extends State<LocalFavoritesFolder> {
  final _key = GlobalKey();
  var reorderWidgetKey = UniqueKey();
  final _scrollController = ScrollController();
  late var comics = LocalFavoritesManager().getAllComics(widget.name);
  double? width;
  bool changed = false;

  Color lightenColor(Color color, double lightenValue) {
    int red = (color.red + ((255 - color.red) * lightenValue)).round();
    int green = (color.green + ((255 - color.green) * lightenValue)).round();
    int blue = (color.blue + ((255 - color.blue) * lightenValue)).round();

    return Color.fromARGB(color.alpha, red, green, blue);
  }

  @override
  void initState() {
    width = MediaQuery.of(App.globalContext!).size.width;
    super.initState();
  }

  @override
  void dispose() {
    if (changed) {
      LocalFavoritesManager().reorder(comics, widget.name);
    }
    LocalFavoriteTile.cache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tiles = List.generate(
        comics.length,
        (index) => LocalFavoriteTile(
              comics[index],
              widget.name,
              () {
                changed = true;
                setState(() {
                  comics = LocalFavoritesManager().getAllComics(widget.name);
                });
              },
              false,
              key: Key(comics[index].target),
            ));
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          Expanded(
            child: ReorderableBuilder(
              key: reorderWidgetKey,
              scrollController: _scrollController,
              longPressDelay: App.isDesktop
                  ? const Duration(milliseconds: 100)
                  : const Duration(milliseconds: 500),
              onReorder: (reorderFunc) {
                changed = true;
                setState(() {
                  comics = reorderFunc(comics) as List<FavoriteItem>;
                });
              },
              dragChildBoxDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: lightenColor(
                      Theme.of(context).splashColor.withOpacity(1), 0.2)),
              builder: (children) {
                return GridView(
                  key: _key,
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithComics(),
                  children: children,
                );
              },
              children: tiles,
            ),
          )
        ],
      ),
    );
  }
}

/// Check the availability of comics in folder
Future<void> checkFolder(String name) async {
  var comics = LocalFavoritesManager().getAllComics(name);
  int unavailableNum = 0;
  int networkError = 0;
  int checked = 0;

  Stream<(int current, int total)> check() async* {
    for (var comic in comics) {
      bool available = true;
      switch (comic.type.comicType) {
        case ComicType.picacg:
          var res = await PicacgNetwork().getComicInfo(comic.target);
          if (res.error && !res.errorMessageWithoutNull.contains("404")) {
            networkError++;
          } else if (res.error) {
            available = false;
          }
        case ComicType.ehentai:
          var res = await EhNetwork().getGalleryInfo(comic.target);
          if (res.error && !res.errorMessageWithoutNull.contains("404")) {
            networkError++;
          } else if (res.error) {
            available = false;
          }
        case ComicType.jm:
          var res = await JmNetwork().getComicInfo(comic.target);
          if (res.error && !res.errorMessageWithoutNull.contains("404")) {
            networkError++;
          } else if (res.error) {
            available = false;
          }
        case ComicType.hitomi:
          var res = await HiNetwork().getComicInfo(comic.target);
          if (res.error && !res.errorMessageWithoutNull.contains("404")) {
            networkError++;
          } else if (res.error) {
            available = false;
          }
        case ComicType.htManga:
          var res = await HtmangaNetwork().getComicInfo(comic.target);
          if (res.error && !res.errorMessageWithoutNull.contains("404")) {
            networkError++;
          } else if (res.error) {
            available = false;
          }
        case ComicType.nhentai:
          var res = await NhentaiNetwork().getComicInfo(comic.target);
          if (res.error && !res.errorMessageWithoutNull.contains("404")) {
            networkError++;
          } else if (res.error) {
            available = false;
          }
        default:
          var res = await comic.type.comicSource.loadComicInfo!(comic.target);
          if (res.error && !res.errorMessageWithoutNull.contains("404")) {
            networkError++;
          } else if (res.error) {
            available = false;
          }
      }
      if (!available) {
        unavailableNum++;
        if (!comic.tags.contains("Unavailable")) {
          LocalFavoritesManager().addTagTo(name, comic.target, "Unavailable");
        }
      }
      checked++;
      yield (checked, comics.length);
    }
  }

  await showDialog(
      context: App.globalContext!,
      builder: (context) {
        return Dialog(
          child: StreamBuilder(
              stream: check(),
              builder: (context, snapshot) {
                if (checked == comics.length) {
                  return SizedBox(
                    height: 200,
                    width: 200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 54,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text("Unavailable: $unavailableNum"),
                          Text("Network Error: $networkError"),
                        ],
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 200,
                  width: 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(
                          height: 12,
                        ),
                        Text("$checked/${comics.length}")
                      ],
                    ),
                  ),
                );
              }),
        );
      });
}
