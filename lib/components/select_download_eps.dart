import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';

class SelectDownloadChapter extends StatefulWidget {
  const SelectDownloadChapter(this.eps, this.finishSelect, this.downloadedEps,
      {super.key});
  final List<String> eps;
  final void Function(List<int>) finishSelect;
  final List<int> downloadedEps;

  @override
  State<SelectDownloadChapter> createState() => _SelectDownloadChapterState();
}

class _SelectDownloadChapterState extends State<SelectDownloadChapter> {
  List<int> selected = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            child: Text(
              "下载漫画".tl,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 4,
              ),
              itemBuilder: (BuildContext context, int i) {
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    onTap: widget.downloadedEps.contains(i)
                        ? null
                        : () {
                            setState(() {
                              if (selected.contains(i)) {
                                selected.remove(i);
                              } else {
                                selected.add(i);
                              }
                            });
                          },
                    child: AnimatedContainer(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        color: (selected.contains(i) ||
                                widget.downloadedEps.contains(i))
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      ),
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: Text(
                              widget.eps[i],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selected.contains(i)) const Icon(Icons.done),
                          if (widget.downloadedEps.contains(i))
                            const Icon(Icons.download_done),
                          const SizedBox(
                            width: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              itemCount: widget.eps.length,
            ),
          ),
          SizedBox(
            height: 50,
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: FilledButton.tonal(
                      onPressed: () {
                        var res = <int>[];
                        for (int i = 0; i < widget.eps.length; i++) {
                          if (!widget.downloadedEps.contains(i)) {
                            res.add(i);
                          }
                        }
                        widget.finishSelect(res);
                      },
                      child: Text("下载全部".tl)),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: FilledButton.tonal(
                      onPressed: () {
                        widget.finishSelect(selected);
                      },
                      child: Text("下载选择".tl)),
                ),
                const SizedBox(
                  width: 16,
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 4,
          )
        ],
      ),
    );
  }
}
