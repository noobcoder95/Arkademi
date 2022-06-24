import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(ignoreSsl: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arkademi Test',
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      theme: ThemeData(
        primarySwatch: const MaterialColor(
          0xFFFFFFFF,
          <int, Color>{
            50: Color(0xFFFFFFFF),
            100: Color(0xFFFFFFFF),
            200: Color(0xFFFFFFFF),
            300: Color(0xFFFFFFFF),
            400: Color(0xFFFFFFFF),
            500: Color(0xFFFFFFFF),
            600: Color(0xFFFFFFFF),
            700: Color(0xFFFFFFFF),
            800: Color(0xFFFFFFFF),
            900: Color(0xFFFFFFFF),
          },
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  VideoPlayerController? _videoPlayerController;
  Map<String, dynamic> _jsonData = <String, dynamic>{};
  List<JsonData> _curriculum = [];
  PageController _pageController = PageController();
  ScrollController _scrollController = ScrollController();
  int _indexPage = 0, _downloadStatus = 0;
  Map<int, int> _downloadProgress = <int, int>{};
  String? _videoPath, _videoTitle;
  final ReceivePort _port = ReceivePort();
  List<TaskInfo>? _tasks;

  @override
  void initState() {
    super.initState();
    fetchJsonData();
    bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    unbindBackgroundIsolate();
    if(_videoPlayerController != null)
    {
      _videoPlayerController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _videoPlayerController != null && _videoPath != null ?
    VisibilityDetector(
        key: ObjectKey(_videoPlayerController),
        onVisibilityChanged: (visibility) {
          if (visibility.visibleFraction == 0 && mounted) {
            _videoPlayerController!.pause();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 5,
            title: const Text('Akuntansi Dasar dan Keuangan',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              iconSize: 25,
              onPressed: (){
                //Insert function/method to back button here
              },
            ),
            actions: [
              SizedBox(
                width: 40,
                height: 15,
                child: CircularPercentIndicator(
                  radius: 15,
                  percent:_jsonData['progress'] != null ? double.parse(_jsonData['progress']) / 100 : 0,
                  fillColor: Colors.white,
                  progressColor: Colors.green,
                  center: Text(
                    _jsonData['progress'] != null ? '${_jsonData['progress']}%' : '0%',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8),
                  ),
                ),
              )
            ],
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        VideoPlayer(_videoPlayerController!),
                        ControlsOverlay(controller: _videoPlayerController!),
                        VideoProgressIndicator(_videoPlayerController!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.green)),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _videoTitle != null ? _videoTitle!.replaceAll('&#8211;', '') : 'Persamaan Dasar Akuntansi',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50.0,
                  alignment: Alignment.center,
                  child: BottomAppBar(
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width / 3,
                          decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: _indexPage == 0 ? Colors.blue : Colors.white, width: _indexPage == 0 ? 2 : 1))
                          ),
                          child: TextButton(
                            child: const Text(
                              'Kurikulum',
                              style: TextStyle(color: Colors.black, fontSize: 12),
                            ),
                            onPressed: (){
                              _pageController.jumpToPage(0);
                              setState((){
                                _indexPage = 0;
                              });
                            },
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width / 3,
                          decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: _indexPage == 1 ? Colors.blue : Colors.white, width: _indexPage == 1 ? 2 : 1))
                          ),
                          child: TextButton(
                            child: const Text(
                              'Ikhtisar',
                              style: TextStyle(color: Colors.black, fontSize: 12),
                            ),
                            onPressed: ()
                            {
                              _pageController.jumpToPage(1);
                              setState((){
                                _indexPage = 1;
                              });
                            },
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width / 3,
                          decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: _indexPage == 2 ? Colors.blue : Colors.white, width: _indexPage == 2 ? 2 : 1))
                          ),
                          child: TextButton(
                            child: const Text(
                              'Lampiran',
                              style: TextStyle(color: Colors.black, fontSize: 12),
                            ),
                            onPressed: ()
                            {
                              _pageController.jumpToPage(2);
                              setState((){
                                _indexPage = 2;
                              });
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                  controller: _pageController,
                  itemBuilder: (context, index){
                    return pageContent(index);
                  },
                  onPageChanged: (index){
                    setState((){
                      _indexPage = index;
                    });
                  },
                )
                )
              ],
            ),
          ),
          bottomNavigationBar: Container(
            width: MediaQuery.of(context).size.width,
            height: 50.0,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 0),
                  blurRadius: 1,
                  spreadRadius: 1,
                  color: Colors.black26,
                ),
              ],
            ),
            child: BottomAppBar(
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width / 2,
                    decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.black12))
                    ),
                    child: TextButton(
                      child: const Text(
                        '<< Sebelumnya',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      onPressed: (){},
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width / 2,
                    decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.black12))
                    ),
                    child: TextButton(
                      child: const Text(
                        'Selanjutnya >>',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      onPressed: (){},
                    ),
                  )
                ],
              ),
            ),
          ),
        )
    ) :
    Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 50,
              arcBackgroundColor: Colors.green,
              arcType: ArcType.FULL,
            ),
            const SizedBox(height: 10),
            const Text('Memuat data...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14))
          ],
        )
      ),
    );
  }

  void bindBackgroundIsolate() {
    final isSuccess = IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      unbindBackgroundIsolate();
      bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      final taskId = (data as List<dynamic>)[0] as String;
      final status = data[1] as DownloadTaskStatus;
      final progress = data[2] as int;
      _downloadStatus = progress;
      if (_tasks != null && _tasks!.isNotEmpty) {
        final task = _tasks!.firstWhere((task) => task.taskId == taskId);
        setState(() {
          task
            ..status = status
            ..progress = progress;
        });
      }
    });
  }

  void unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  void createDownloadTask(String url) async
  {
    String _path = await localPath;
    if(_path != null && _path.isNotEmpty)
    {
      await FlutterDownloader.enqueue(
        url: url,
        savedDir: '$_path/',
        showNotification: true,
        openFileFromNotification: false,
      );
    }
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress,)
  {
    IsolateNameServer.lookupPortByName('downloader_send_port')?.send([id, status, progress]);
  }

  Widget pageContent(int index)
  {
    switch(index)
    {
      case 1:
        return const Center(
          child: Text('Halaman Ikhtisar'),
        );
      case 2:
        return const Center(
          child: Text('Halaman Lampiran'),
        );
      default:
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            itemBuilder: (context, index) => contentList(_curriculum[index]),
            itemCount: _curriculum.length,
            controller: _scrollController,
          )
        );
    }
  }

  Widget contentList(JsonData data)
  {
    if(data.type != null && data.type!.isNotEmpty && data.type == 'section')
    {
      String _nomorBab = '';
      switch(data.key!)
      {
        case 2:
          _nomorBab = '2';
          break;
        case 6:
          _nomorBab = '3';
          break;
        case 9:
          _nomorBab = '4';
          break;
        default:
          _nomorBab = '1';
          break;
      }
      return TextButton(
        onPressed: () {},
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.grey[100]!),
            shape: MaterialStateProperty.all<OutlinedBorder>(
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(0)),
              ),
            )),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Column(
                children: <Widget>[
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                    child: Text(
                        data.title != null ?'Bab ${'$_nomorBab: ${data.title!}'}' : 'Bab :',
                        maxLines: 1,
                        style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                    child: Text(
                      data.duration != null && data.duration! > 60 && data.duration! < 3600  ?
                      '${data.duration! ~/ 60} Menit' : data.duration != null && data.duration! > 3600 ?
                      '${(data.duration! ~/ 60) ~/ 60} Jam' : '0 Menit',
                      maxLines: 1,
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }
    else
    {
      return Container(
        padding: const EdgeInsets.only(left: 10),
        child: TextButton(
          onPressed: () async
          {
            setState((){
              _videoTitle = data.title;
            });

            if(File('$_videoPath/${data.offline_video_link!.split('/').last}').existsSync())
            {
              initVideoLocal(File('$_videoPath/${data.offline_video_link!.split('/').last}'));
            }
            else if(data.online_video_link != null && data.online_video_link!.isNotEmpty)
            {
              initVideoStream(data.online_video_link!);
            }
            else
            {
              snackBar('Online video tidak tersedia, silakan unduh untuk menonton offline');
            }
          },
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  _videoTitle != null && _videoTitle!.isNotEmpty && _videoTitle == data.title ?
                  Colors.green.withOpacity(0.8) : Colors.white),
              shape: MaterialStateProperty.all<OutlinedBorder>(
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
              )),
          child: Row(
            children: <Widget>[
              Icon(
                  data.status != null && data.status == 1 ?
                  Icons.check_circle : Icons.play_circle_filled,
                  color: data.status != null && data.status == 1 ?
                  Colors.green : Colors.grey,
                  size: 16),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(left: 5),
                  child: Column(
                    children: <Widget>[
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(left: 5),
                        child: Text(
                            data.title != null ? data.title!.replaceAll(' &#8211;', '') : '',
                            maxLines: 1,
                            style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(left: 5),
                        child: Text(
                          data.duration != null && data.duration! > 60 && data.duration! < 3600  ?
                          '${data.duration! ~/ 60} Menit' : data.duration != null && data.duration! > 3600 ?
                          '${(data.duration! ~/ 60) ~/ 60} Jam' : '0 Menit',
                          maxLines: 1,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: data.offline_video_link != null && File('$_videoPath/${data.offline_video_link!.split('/').last}').existsSync() == false ?
                Container(
                  height: 25,
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () async
                    {
                      if(data.offline_video_link != null && data.offline_video_link!.isNotEmpty)
                      {
                        setState((){
                          _downloadStatus = 0;
                          _downloadProgress[data.key!] = 0;
                        });
                        createDownloadTask(data.offline_video_link!);
                        Timer.periodic(const Duration(seconds: 1), (Timer t)
                        {
                          if(mounted)
                          {
                            setState((){
                              _downloadProgress[data.key!] = _downloadStatus;
                            });
                            if(_downloadProgress[data.key!]! == 0 || _downloadProgress[data.key!]! == 100)
                            {
                              t.cancel();
                            }
                          }
                          else
                          {
                            t.cancel();
                          }
                        });
                      }
                      else
                      {
                        snackBar('Link download tidak tersedia');
                      }
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                        )),
                    child: const Text('Tonton Offline', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ) :
                data.offline_video_link == null || data.offline_video_link!.isEmpty ?
                Container(
                  height: 25,
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: (){},
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                        )),
                    child: const Text('Null', style: TextStyle(fontSize: 10)),
                  ),
                ) :
                _downloadProgress[data.key!]! > 0 && _downloadProgress[data.key!]! < 100 ?
                Container(
                  height: 25,
                  alignment: Alignment.center,
                  child: CircularPercentIndicator(
                    radius: 10,
                    percent: _downloadProgress[data.key!]!.toDouble() / 100,
                    fillColor: Colors.white,
                    progressColor: Colors.green,
                  ),
                ) :
                Container(
                  height: 25,
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {},
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.grey),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                        )),
                    child: const Text('Tersimpan', style: TextStyle(fontSize: 10)),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  void initVideoStream(String source)
  {
    if(source.isNotEmpty)
    {
      _videoPlayerController?.removeListener(() {
        setState(() {});
      });

      setState((){
        _videoPlayerController = VideoPlayerController.network(source);
      });

      _videoPlayerController!.addListener(() {
        setState(() {});
      });
      _videoPlayerController!.setLooping(false);
      _videoPlayerController!.initialize().then((_) => setState(() {}));
    }
  }

  void initVideoLocal(File source)
  {
    if(source.existsSync())
    {
      _videoPlayerController?.removeListener(() {
        setState(() {});
      });

      setState((){
        _videoPlayerController = VideoPlayerController.file(source);
      });

      _videoPlayerController!.addListener(() {
        setState(() {});
      });
      _videoPlayerController!.setLooping(false);
      _videoPlayerController!.initialize().then((_) => setState(() {}));
    }
  }

  void snackBar(String text)
  {
    final snackBar = SnackBar(
      backgroundColor: Colors.red,
      content: Text(text, style: const TextStyle(color: Colors.white)),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void fetchJsonData() async
  {
    final response = await http.get(Uri.parse('https://engineer-test-eight.vercel.app/course-status.json'));
    _jsonData = json.decode(response.body);
    List _curFromJson = _jsonData['curriculum'];
    if(_curFromJson.isNotEmpty)
    {
      for (var data in _curFromJson)
      {
        _curriculum.add(JsonData.fromJson(data as Map<String, dynamic>));
      }
    }
    List<String> initVideoUrl = [];
    for (var data in _curriculum) {
      if(data.online_video_link != null && data.online_video_link!.isNotEmpty)
      {
        initVideoUrl.add(data.online_video_link!);
      }
      _downloadProgress[data.key!] = 0;
    }

    if(initVideoUrl.isNotEmpty)
    {
      initVideoUrl.shuffle();
    }
    initVideoStream(initVideoUrl[0]);
    _videoPath = await localPath;
    setState((){});
  }
}

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({Key? key, required this.controller}) : super(key: key);
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
            color: Colors.black26,
            child: const Center(
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 70,
                semanticLabel: 'Play',
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
      ],
    );
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }
}

class JsonData {
  JsonData({this.key, this.id, this.type, this.title, this.duration, this.content, this.meta, this.status, this.online_video_link, this.offline_video_link});
  int? key, duration, status;
  String? id, type, title, content, online_video_link, offline_video_link;
  List? meta;

  factory JsonData.fromJson(Map<String, dynamic> data) {
    int? key = data['key'];
    int? duration = data['duration'];
    int? status = data['status'];
    String? id = data['id'].toString();
    String? type = data['type'];
    String? title = data['title'];
    String? content = data['content'];
    String? online_video_link = data['online_video_link'];
    String? offline_video_link = data['offline_video_link'];
    List? meta = data['meta'];

    return JsonData(key: key, id: id, type: type, title: title, duration: duration, content: content, meta: meta, status: status, online_video_link: online_video_link, offline_video_link: offline_video_link);
  }
}

class TaskInfo {
  TaskInfo({this.name, this.link});

  final String? name;
  final String? link;

  String? taskId;
  int? progress = 0;
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;
}

