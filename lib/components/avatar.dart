part of 'components.dart';

class Avatar extends StatelessWidget {
  const Avatar(
      {super.key,
      required this.size,
      this.avatarUrl,
      this.frame,
      this.couldBeShown = false,
      this.name = "",
      this.slogan,
      this.level = 0});
  final double size;
  final String? avatarUrl;
  final String? frame;
  final bool couldBeShown;
  final String name;
  final String? slogan;
  final int level;

  @override
  Widget build(BuildContext context) {
    var avatarUrl = this.avatarUrl;
    if(avatarUrl != null && !avatarUrl.isURL){
      avatarUrl = null;
    }
    return GestureDetector(
      onTap: () {
        if (couldBeShown) {
          showUserInfo(context, avatarUrl, frame, name, slogan, level);
        } else if(avatarUrl != null && avatarUrl != "DEFAULT AVATAR URL"){
          App.globalTo(() => ShowImagePageWithHero(avatarUrl!, "avatar"));
        }
      },
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(size)),
        child: Stack(
          children: [
            Positioned(
              top: size * 0.25 / 2,
              left: size * 0.25 / 2,
              child: Container(
                width: size * 0.75,
                height: size * 0.75,
                clipBehavior: Clip.antiAlias,
                decoration:
                    BoxDecoration(
                        borderRadius: BorderRadius.circular(size),
                      color: Theme.of(context).colorScheme.secondaryContainer
                    ),
                child: (avatarUrl == null || avatarUrl == "DEFAULT AVATAR URL")
                    ? const Image(
                        image: AssetImage("images/avatar_small.png"),
                        fit: BoxFit.cover,
                      )
                    : AnimatedImage(
                        image: CachedImageProvider(avatarUrl,
                            headers: {"User-Agent": webUA}),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium),
              ),
            ),
            if (frame != null && appdata.settings[5] == "1")
              Positioned(
                child: Image(
                  image: CachedImageProvider(
                    frame!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void showUserInfo(BuildContext context, String? avatarUrl, String? frameUrl, String name, String? slogan, int level){
  showDialog(context: context, builder: (dialogContext){
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              Avatar(size: 80, avatarUrl: avatarUrl, frame: frameUrl,),
              Text(name,style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
              Text("Lv${level.toString()}"),
              const SizedBox(height: 10,width: 0,),
              SizedBox(width: 400,child: Align(
                alignment: Alignment.center,
                child: Text(slogan??""),
              ),)
            ],
          ),
        )
      ],
    );
  });
}
