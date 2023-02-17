import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_player_new/constant.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

Future<void> main() async {
  await JustAudioBackground.init(
    androidShowNotificationBadge: true,
    preloadArtwork: true,
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const MyHomePage(title: 'My Music Gallery'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // bg color
  //Color bgColor = const Color(0XFF2A2A2A); //Colors.black;
  Color bgColor = Colors.white;

  //define on audio plugin
  final OnAudioQuery _audioQuery = OnAudioQuery();

  //today
  //player
  var _player = AudioPlayer();

  //more variables
  List<SongModel> songs = [];
  String currentSongTitle = '';
  int currentIndex = 0;

  bool isPlayerViewVisible = false;

  //define a method to set the player view visibility
  void _changePlayerViewVisibility() {
    setState(() {
      isPlayerViewVisible = !isPlayerViewVisible;
    });
  }

  //duration state stream
  Stream<DurationState> get _durationStateStream =>
      Rx.combineLatest2<Duration, Duration?, DurationState>(
          _player.positionStream,
          _player.durationStream,
          (position, duration) => DurationState(
              position: position, total: duration ?? Duration.zero));

  //request permission from initStateMethod
  @override
  void initState() {
    super.initState();
    requestStoragePermission();

    _player = AudioPlayer();
    //update the current playing song index listener
    _player.currentIndexStream.listen((index) {
      if (index != null) {
        _updateCurrentPlayingSongDetails(index);
      }
    });
  }

  //dispose the player when done
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isPlayerViewVisible) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.only(top: 56.0, right: 20.0, left: 20.0),
            decoration: BoxDecoration(color: Colors.white24),
            child: Column(
              children: <Widget>[
                //exit button and the song title
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: _changePlayerViewVisibility,
                        //hides the player view
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: getDecoration(
                              BoxShape.circle, const Offset(1, 1), 1.0, 0.0),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Flexible(
                      child: Text(
                        currentSongTitle,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      flex: 5,
                    ),
                  ],
                ),

                //artwork container
                Container(
                  width: 300,
                  height: 300,
                  decoration: getDecoration(
                      BoxShape.circle, const Offset(1, 1), 0.0, 0.0),
                  margin: const EdgeInsets.only(top: 30, bottom: 30),
                  child: QueryArtworkWidget(
                    artworkBorder: BorderRadius.circular(200),
                    id: songs[currentIndex].id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.deepOrange,
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                //slider , position and duration widgets
                Column(
                  children: [
                    //slider bar container
                    Container(
                      padding: EdgeInsets.zero,
                      margin: const EdgeInsets.only(bottom: 4.0),
                      decoration: getRectDecoration(BorderRadius.circular(20.0),
                          const Offset(1, 1), 1.0, 0.0),

                      //slider bar duration state stream
                      child: StreamBuilder<DurationState>(
                        stream: _durationStateStream,
                        builder: (context, snapshot) {
                          final durationState = snapshot.data;
                          final progress =
                              durationState?.position ?? Duration.zero;
                          final total = durationState?.total ?? Duration.zero;

                          return ProgressBar(
                            progress: progress,
                            total: total,
                            barHeight: 20.0,
                            baseBarColor: bgColor,
                            progressBarColor: const Color(0xEE9E9E9E),
                            thumbColor: Colors.white24.withBlue(99),
                            timeLabelTextStyle: const TextStyle(
                              fontSize: 0,
                            ),
                            onSeek: (duration) {
                              _player.seek(duration);
                            },
                          );
                        },
                      ),
                    ),

                    //position /progress and total text
                    StreamBuilder<DurationState>(
                      stream: _durationStateStream,
                      builder: (context, snapshot) {
                        final durationState = snapshot.data;
                        final progress =
                            durationState?.position ?? Duration.zero;
                        final total = durationState?.total ?? Duration.zero;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              child: Text(
                                progress.toString().split(".")[0],
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                total.toString().split(".")[0],
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                //prev, play/pause & seek next control buttons
                Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      //skip to previous
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            if (_player.hasPrevious) {
                              _player.seekToPrevious();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(1, 1), 1.0, 0.0),
                            child: const Icon(
                              Icons.skip_previous,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      //play pause
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            if (_player.playing) {
                              _player.pause();
                            } else {
                              if (_player.currentIndex != null) {
                                _player.play();
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            margin:
                                const EdgeInsets.only(right: 20.0, left: 20.0),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(1, 1), 1.0, 0.0),
                            child: StreamBuilder<bool>(
                              stream: _player.playingStream,
                              builder: (context, snapshot) {
                                bool? playingState = snapshot.data;
                                if (playingState != null && playingState) {
                                  return const Icon(
                                    Icons.pause,
                                    size: 30,
                                    color: Colors.black87,
                                  );
                                }
                                return const Icon(
                                  Icons.play_arrow,
                                  size: 30,
                                  color: Colors.black87,
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      //skip to next
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            if (_player.hasNext) {
                              _player.seekToNext();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(1, 1), 1.0, 0.0),
                            child: const Icon(
                              Icons.skip_next,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //go to playlist, shuffle , repeat all and repeat one control buttons
                Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      //go to playlist btn
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            _changePlayerViewVisibility();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(1, 1), 1.0, 0.0),
                            child: const Icon(
                              Icons.list_alt,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      //shuffle playlist
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            _player.setShuffleModeEnabled(true);
                            toast(context, "Shuffling enabled");
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            margin:
                                const EdgeInsets.only(right: 30.0, left: 30.0),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(1, 1), 1.0, 0.0),
                            child: const Icon(
                              Icons.shuffle,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      //repeat mode
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            _player.loopMode == LoopMode.one
                                ? _player.setLoopMode(LoopMode.all)
                                : _player.setLoopMode(LoopMode.one);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(1, 1), 1.0, 0.0),
                            child: StreamBuilder<LoopMode>(
                              stream: _player.loopModeStream,
                              builder: (context, snapshot) {
                                final loopMode = snapshot.data;
                                if (LoopMode.one == loopMode) {
                                  return const Icon(
                                    Icons.repeat_one,
                                    color: Colors.black87,
                                  );
                                }
                                return const Icon(
                                  Icons.repeat,
                                  color: Colors.black87,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 20,
      ),
      backgroundColor: bgColor,
      body: FutureBuilder<List<SongModel>>(
        //default values
        future: _audioQuery.querySongs(
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        ),
        builder: (context, item) {
          //loading content indicator
          if (item.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          //no songs found
          if (item.data!.isEmpty) {
            return const Center(
              child: Text("No Songs Found"),
            );
          }

          songs.clear();
          songs = item.data!;
          return ListView.builder(
              itemCount: item.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    item.data![index].title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.data![index].album.toString(),
                    style: const TextStyle(color: Colors.black, fontSize: 13),
                  ),
                  leading: QueryArtworkWidget(
                    artworkHeight: 40,
                    artworkWidth: 40,
                    id: item.data![index].id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.deepOrange,
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: () async {
                    //show the player view
                    _changePlayerViewVisibility();

                    var value = await getFilePath(item.data![index].id)
                        .then((value) => value);
                    await _player.setAudioSource(
                        createPlaylist(item.data!, value),
                        initialIndex: index);
                    await _player.play();
                  },
                );
              });
        },
      ),
    );
  }

  //define a toast method
  void toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
    ));
  }

  void requestStoragePermission() async {
    //only if the platform is not web, coz web have no permissions
    if (!kIsWeb) {
      bool permissionStatus = await _audioQuery.permissionsStatus();
      if (!permissionStatus) {
        await _audioQuery.permissionsRequest();
      }
      //ensure build method is called
      setState(() {});
    }
  }

  Future<String> getFilePath(int id) async {
    var asdasd = await _audioQuery.queryArtwork(id, ArtworkType.AUDIO);
    //print(asdasd);
    if (asdasd != null) {
      Uint8List? imageInUnit8List = asdasd; // store unit8List image here ;

      final tempDir = await getTemporaryDirectory();
      File file = await File('${tempDir.path}/${id}.png').create();
      print(imageInUnit8List);
      file.writeAsBytesSync(imageInUnit8List);

      print('filepath');
      print(file.path);
      return file.path;
    } else {
      return 'null';
    }
  }

  //create playlist
  ConcatenatingAudioSource createPlaylist(
      List<SongModel> songs, String artWork) {
    List<AudioSource> sources = [];
    for (var song in songs) {
      //  var artWork;
      // getFilePath(song.id).then((String result){
      //   artWork = result;
      //  print('artweork');
      //  print(artWork);
      //
      //  if(artWork == "null"){
      //    Uri.parse("https://png.pngtree.com/element_pic/17/04/20/1078f8837992bf1289fe1df5eeb1ee0c.jpg")
      //  }
      // });

      sources.add(AudioSource.uri(Uri.parse(song.uri!),
          tag: MediaItem(
            // Specify a unique ID for each media item:
            id: song.id.toString(),
            // Metadata to display in the notification:
            album: song.album.toString(),
            title: song.title.toString(),
            artist: song.artist.toString(),
            artUri: getUriFromString(artWork),
          )));
    }
    return ConcatenatingAudioSource(children: sources);
  }

  Uri getUriFromString(String string) {
    if (UrlParser.validUrl(string)) {
      return Uri.parse(string);
    } else {
      return Uri.file(string);
    }
  }

  //update playing song details
  void _updateCurrentPlayingSongDetails(int index) {
    setState(() {
      if (songs.isNotEmpty) {
        currentSongTitle = songs[index].title;
        currentIndex = index;
        setAudioSource(index);
      }
    });
  }

  void setAudioSource(int index) async {
    var value = await getFilePath(songs[index].id).then((value) => value);
    await _player.setAudioSource(createPlaylist(songs, value),
        initialIndex: index);
  }

  BoxDecoration getDecoration(
      BoxShape shape, Offset offset, double blurRadius, double spreadRadius) {
    return BoxDecoration(
      color: bgColor,
      shape: shape,
      boxShadow: [
        BoxShadow(
          offset: -offset,
          color: Colors.white24,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
        BoxShadow(
          offset: offset,
          color: Colors.black87,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        )
      ],
    );
  }

  BoxDecoration getRectDecoration(BorderRadius borderRadius, Offset offset,
      double blurRadius, double spreadRadius) {
    return BoxDecoration(
      borderRadius: borderRadius,
      color: bgColor,
      boxShadow: [
        BoxShadow(
          offset: -offset,
          color: Colors.white24,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
        BoxShadow(
          offset: offset,
          color: Colors.black,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        )
      ],
    );
  }
}

//duration class
class DurationState {
  DurationState({this.position = Duration.zero, this.total = Duration.zero});

  Duration position, total;
}
