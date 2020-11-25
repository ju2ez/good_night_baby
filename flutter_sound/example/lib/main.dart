/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:example/widgetUI/demo_util/demo_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'demo/demo.dart';
import 'classes/about_us.dart';
import 'widgetUI/widgetUIDemo.dart';
import 'recordToStream/recordToStreamExample.dart';
import 'livePlaybackWithBackPressure/livePlaybackWithBackPressure.dart';
import 'livePlaybackWithoutBackPressure/livePlaybackWithoutBackPressure.dart';
import 'soundEffect/soundEffect.dart';
import 'streamLoop/streamLoop.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noise_meter/noise_meter.dart';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';


/*
  This App is called Google Night Baby.
*/

void main() {
  runApp(ExamplesApp());
}

class Button
{
    final String title;
    final String subTitle;
    final WidgetBuilder route;

    /* ctor */ Button({ this.title, this.subTitle, this.route}){}

    void go(BuildContext context) => Navigator.push(context, MaterialPageRoute<void>( builder: route));
}

final List<Button> buttonTable =
    [
      Button(title: 'Select Audio', subTitle: 'Select or Create the Audio File you want to play.', route: (BuildContext) => Demo()
      ),
      Button(title: 'About', subTitle: 'More Information about Good Night Baby.', route: (BuildContext) => AboutUs()),

];


double db_threshold= 150;

class ExamplesApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Good Night Baby',
      theme: ThemeData(
        textTheme: GoogleFonts.ptSansTextTheme(
          Theme.of(context).textTheme,
        ),
      ),

        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        // primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        // visualDensity: VisualDensity.adaptivePlatformDensity,


      //),
      home: AppHomePage(title: 'Good Night Baby'),
    );
  }
}

class AppHomePage extends StatefulWidget {
  AppHomePage({Key key, this.title}) : super(key: key);


  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;


  @override
  _ExamplesHomePageState createState() => _ExamplesHomePageState();
}



const int SAMPLE_RATE = 8000;
const int BLOCK_SIZE = 4096;

class _ExamplesHomePageState extends State<AppHomePage> {
  Button selectedButton;
  bool _isRecording = false;
  StreamSubscription<NoiseReading> _noiseSubscription;
  NoiseMeter _noiseMeter = new NoiseMeter();
  double current_db = 0;


  StreamSubscription _recorderSubscription;
  StreamSubscription _playerSubscription;
  StreamSubscription _recordingDataSubscription;

  FlutterSoundPlayer playerModule = FlutterSoundPlayer();
  Media _media = Media.remoteExampleFile;
  Codec _codec = Codec.aacADTS;
  String _playerTxt = '00:00:00';
  double _dbLevel;


  final exampleAudioFilePath =
      "https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3";
  final albumArtPath =
      "https://file-examples-com.github.io/uploads/2017/10/file_example_PNG_500kB.png";

  List<String> _path = [
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
  ];
  // Whether the user wants to use the audio player features
  bool _isAudioPlayer = true;
  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;


  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription.cancel();
      _playerSubscription = null;
    }
  }


  void _addListeners() {
    cancelPlayerSubscriptions();
    _playerSubscription = playerModule.onProgress.listen((e) {
      if (e != null) {
        maxDuration = e.duration.inMilliseconds.toDouble();
        if (maxDuration <= 0) maxDuration = 0.0;

        sliderCurrentPosition =
            min(e.position.inMilliseconds.toDouble(), maxDuration);
        if (sliderCurrentPosition < 0.0) {
          sliderCurrentPosition = 0.0;
        }

        DateTime date = new DateTime.fromMillisecondsSinceEpoch(
            e.position.inMilliseconds,
            isUtc: true);
        String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
        this.setState(() {
          this._playerTxt = txt.substring(0, 8);
        });
      }
    });
  }

  Future<void> copyAssets() async {
    Uint8List dataBuffer =
    (await rootBundle.load("assets/canardo.png")).buffer.asUint8List();
    String path = await playerModule.getResourcePath() + "/assets";
    if (!await Directory(path).exists()) {
      await Directory(path).create(recursive: true);
    }
    await File(path + '/canardo.png').writeAsBytes(dataBuffer);
  }


  String path = "this is a test";



  void Function() onStartPlayerPressed() {
    _path[_codec.index] = path;
    if (playerModule == null) return null;
    if (_media == Media.file || _media == Media.stream ||
        _media == Media.buffer) // A file must be already recorded to play it
        {
      if (_path[_codec.index] == null) return null;
    }
    if (_media == Media.remoteExampleFile &&
        _codec != Codec.mp3) // in this example we use just a remote mp3 file
      return null;

    if (_media == Media.stream && _codec != Codec.pcm16)
      return null;

    if (_media == Media.stream && _isAudioPlayer )
      return null;

    // Disable the button if the selected codec is not supported
    //if (!(_decoderSupported || _codec == Codec.pcm16))
      //return null;

    return (playerModule.isStopped) ? startPlayer : null;
  }
  Future<void> startPlayer() async {
    try {
      Uint8List dataBuffer;
      String audioFilePath;
      Codec codec = _codec;
      if (_media == Media.asset) {
        dataBuffer = (await rootBundle.load(assetSample[codec.index]))
            .buffer
            .asUint8List();
      } else if (_media == Media.file || _media == Media.stream) {
        // Do we want to play from buffer or from file ?
        if (await fileExists(_path[codec.index]))
          audioFilePath = this._path[codec.index];
      } else if (_media == Media.buffer) {
        // Do we want to play from buffer or from file ?
        if (await fileExists(_path[codec.index])) {
          dataBuffer = await makeBuffer(this._path[codec.index]);
          if (dataBuffer == null) {
            throw Exception('Unable to create the buffer');
          }
        }
      } else if (_media == Media.remoteExampleFile) {
        // We have to play an example audio file loaded via a URL
        audioFilePath = exampleAudioFilePath;
      }

      // Check whether the user wants to use the audio player features
      if (_isAudioPlayer) {
        String albumArtUrl;
        String albumArtAsset;
        String albumArtFile;
        if (_media == Media.remoteExampleFile)
          albumArtUrl = albumArtPath;
        else {
          albumArtFile =
              await playerModule.getResourcePath() + "/assets/canardo.png";
          print(albumArtFile);
        }

        final track = Track(
          trackPath: audioFilePath,
          codec: _codec,
          dataBuffer: dataBuffer,
          trackTitle: "This is a record",
          trackAuthor: "from flutter_sound",
          albumArtUrl: albumArtUrl,
          albumArtAsset: albumArtAsset,
          albumArtFile: albumArtFile,
        );
        await playerModule.startPlayerFromTrack(track,
            defaultPauseResume: false,
            removeUIWhenStopped: true,
            whenFinished: () {
              print('I hope you enjoyed listening to this song');
              setState(() {});
            }, onSkipBackward: () {
              print('Skip backward');
              stopPlayer();
              startPlayer();
            }, onSkipForward: () {
              print('Skip forward');
              stopPlayer();
              startPlayer();
            }, onPaused: (bool b) {
              if (b)
                playerModule.pausePlayer();
              else
                playerModule.resumePlayer();
            });
      } else
      if (_media == Media.stream){
        await playerModule.startPlayerFromStream(
          codec: _codec,
          numChannels: 1,
          sampleRate: SAMPLE_RATE,
        );
        _addListeners();
        setState(() {});
        await feedHim(audioFilePath);
        //await finishPlayer();
        await stopPlayer();
        return;

      } else {
        if (audioFilePath != null) {

          await playerModule.startPlayer(
              fromURI: audioFilePath,
              codec: codec,
              sampleRate:  SAMPLE_RATE,
              whenFinished: () {
                print('Play finished');
                setState(() {});
              });
        } else if (dataBuffer != null) {
          if (codec == Codec.pcm16) {
            dataBuffer = await flutterSoundHelper.pcmToWaveBuffer(
              inputBuffer: dataBuffer,
              numChannels: 1,
              sampleRate: (_codec == Codec.pcm16 && _media == Media.asset)? 48000 : SAMPLE_RATE,
            );
            codec = Codec.pcm16WAV;
          }
          await playerModule.startPlayer(
              fromDataBuffer: dataBuffer,
              sampleRate:   SAMPLE_RATE,

              codec: codec,
              whenFinished: () {
                print('Play finished');
                setState(() {});
              });
        }
      }
      _addListeners();
      setState(() {});
      print('<--- startPlayer');
    } catch (err) {
      print('error: $err');
    }
  }

  Future<void> stopPlayer() async {
    try {
      await playerModule.stopPlayer();
      print('stopPlayer');
      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }
      sliderCurrentPosition = 0.0;
    } catch (err) {
      print('error: $err');
    }
    this.setState(() {
    });
  }

  Future<void> feedHim(String path) async
  {
    Uint8List data = await _readFileByte(path);
    return playerModule.feedFromStream(data);
  }

  Future<Uint8List> _readFileByte(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    File audioFile = new File.fromUri(myUri);

    Uint8List bytes;
    await audioFile.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
      print('reading of bytes is completed');
    });
    return bytes;
  }



  void check_db() {
    if (current_db > db_threshold){
      print("now play the audio!");
      print(current_db);
      print(db_threshold);
      onStartPlayerPressed();
      startPlayer();

      startTimeout(5000);
      //wait for audio
    }
    }


  
  void onData(NoiseReading noiseReading) {
    setState(() {
      if (!_isRecording) {
        _isRecording = true;
      }
    });
    current_db = noiseReading.meanDecibel.truncateToDouble();
    check_db();

  }

  void start() async {
    try {
      _noiseSubscription = _noiseMeter.noiseStream.listen(onData);
    } catch (err) {
      print(err);
    }
  }

  void stop() async {
    try {
      if (_noiseSubscription != null) {
        await _noiseSubscription.cancel();
        _noiseSubscription = null;
      }
       setState(() {
        _isRecording = false;
      });
    } catch (err) {
      print('stopRecorder error: $err');
    }
  }


  @override
  void initState( ) {
    _isRecording = false;
    selectedButton = buttonTable[0];
    super.initState();
    //_scrollController = ScrollController( );
  }

  @override
  Widget build(BuildContext context) {
    Widget cardBuilder(BuildContext context, int index)
    {
        bool isSelected = (buttonTable[index] == selectedButton);
        return     GestureDetector
        (
            onTap: ( ) => setState( (){selectedButton = buttonTable[index];}),
            onDoubleTap: ( ) => setState( (){selectedButton.go(context);}),
            onSecondaryTap: ( ) => setState( (){selectedButton.go(context);}),

          child: Card(shape: RoundedRectangleBorder(),
              child: Container
              (
                margin: const EdgeInsets.all( 3 ),
                padding: const EdgeInsets.all( 3 ),
                decoration: BoxDecoration
                  (
                  color:  isSelected ? Colors.indigo : Color( 0xFFFAF0E6),
                  border: Border.all( color: Colors.white, width: 3, ),
                ),

                height: 50,


                //color: isSelected ? Colors.indigo : Colors.cyanAccent,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[
                      Text(buttonTable[index].title, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                      Text(buttonTable[index].subTitle, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),

                    ]
                ) ,
              ),

              borderOnForeground: false, elevation: 3.0,
            ),
        );

    }

    Widget recorderSection = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 156.0,
                height: 100.0,
                child: ClipOval(
                  child: FlatButton(
                    padding: EdgeInsets.all(10.0),
                    onPressed: () {
                      if (_isRecording == false)
                       {start();}
                    },
                    child: Image(
                      image: AssetImage('res/icons/ic_play.png'),
                    ),
                  ),
                ),

              ),

              Container(
                width: 66.0,
                height: 100.0,
                child: ClipOval(
                  child: FlatButton(
                    padding: EdgeInsets.all(4.0),
                    onPressed: () {if (_isRecording == true)
                    {stop();} },
                    child: Image(
                      image: AssetImage('res/icons/ic_stop.png'),
                    ),
                  ),
                ),
              ),



            ],
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          Row(
    children: <Widget>[
          Container(
            width: 222.0,
            height: 40.0,
            child: Text(
                  'Press play to start Good Night Baby.'),
                ),

    ] ,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),

          Row(
            children: <Widget>[

                MyStatefulWidget(),


            ] ,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          Row(
            children: <Widget>[
              Container(
                width: 222.0,
                height: 50.0,
                child: Text(
                    'Adjust the decibel threshold.'),
              ),

            ] ,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),

          Row(
            children: <Widget>[
              Container(
                width: 222.0,
                height: 60.0,
                child:
                  Text(current_db.toString() + " dB"),
              ),

            ] ,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),

        ]);


    Widget makeBody()
    {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>
        [
          Expanded(
              child: Container(
              margin: const EdgeInsets.all( 3 ),
              padding: const EdgeInsets.all( 3 ),
              decoration: BoxDecoration
                (
                color:  Color( 0xFFFAF0E6 ),
                border: Border.all( color: Colors.indigo, width: 3, ),
              ),
              child:
              ListView.builder(
                itemCount: buttonTable.length,
                itemBuilder:  cardBuilder,
              ),
              ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all( 3 ),
              padding: const EdgeInsets.all( 3 ),

              decoration: BoxDecoration
                (
                color: Color( 0xFFFAF0E6 ),
                border: Border.all( color: Colors.indigo, width: 3, ),
              ),
              child:
              ListView(
                children: <Widget>[recorderSection],
              ),
            ),
          ),
        ],
      );

    }

    return Scaffold(backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: makeBody(),
            bottomNavigationBar: BottomAppBar
      (
        color: Colors.blue,

      ),

    );
  }
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  MyStatefulWidget({Key key}) : super(key: key);

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  double _currentSliderValue = 20;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _currentSliderValue,
      min: 0,
      max: 200,
      divisions: 20,
      label: _currentSliderValue.round().toString(),
      onChanged: (double value) {
        setState(() {
          _currentSliderValue = value;
          db_threshold = _currentSliderValue;
        });
      },
    );
  }
}


const timeout = const Duration(seconds: 3);
const ms = const Duration(milliseconds: 1);
var start_playing_audio = false;

Timer startTimeout([int milliseconds]) {
  var duration = milliseconds == null ? timeout : ms * milliseconds;
  return new Timer(duration, handleTimeout);
}


void handleTimeout() {
  // callback function
}



