import 'package:flutter/material.dart';

import 'components.dart';

class CommentTile extends StatelessWidget {
  const CommentTile(
      {super.key,
      required this.avatarUrl,
      this.frameUrl,
      required this.name,
      required this.content,
      this.onTap,
      this.slogan,
      this.level,
      this.time,
      this.tailing,
      this.likes,
      this.liked,
      this.comments,
      this.leading,
      this.like});
  final String? avatarUrl;
  final String? frameUrl;
  final String name;
  final String content;
  final String? slogan;
  final String? time;
  final int? likes;
  final bool? liked;
  final int? comments;
  final int? level;
  final void Function()? onTap;
  final Widget? tailing;
  final void Function()? like;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(avatarUrl != null)
                Avatar(
                  size: 58,
                  avatarUrl: avatarUrl,
                  frame: frameUrl,
                  slogan: slogan,
                  name: name,
                  couldBeShown: level != null,
                  level: level ?? 0,
                ),
              if(leading != null)
                leading!,
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SelectableText(content, style: const TextStyle(fontSize: 15),),
                    const SizedBox(
                      height: 4,
                    ),
                    Row(
                      children: [
                        if (time != null)
                          Text(
                            time!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        const Spacer(),
                        if(like != null)
                          InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            onTap: like,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(3, 5, 3, 5),
                              child: SizedBox(
                                width: 50,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    liked!?Icon(
                                      Icons.favorite,
                                      size: 15,
                                      color: Theme.of(context).colorScheme.primary,
                                    ):const Icon(
                                      Icons.favorite_outline,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 5,),
                                    Text(likes.toString())
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if(like != null)
                          const SizedBox(width: 16,),
                        if(comments != null)
                          InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            onTap: onTap,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(3, 6, 3, 5),
                              child: SizedBox(
                                width: 50,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.mode_comment_outlined,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 5,),
                                    Text(comments.toString())
                                  ],
                                ),
                              ),
                            ),
                          )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
