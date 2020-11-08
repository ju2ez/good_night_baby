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

import 'package:flutter/material.dart';
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


/*
  This App is called Goog Night Baby. LOL.
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



class _ExamplesHomePageState extends State<AppHomePage> {
  Button selectedButton;
  bool _isRecording = false;
  StreamSubscription<NoiseReading> _noiseSubscription;
  NoiseMeter _noiseMeter = new NoiseMeter();
  double current_db = 0;
  
  void onData(NoiseReading noiseReading) {
    setState(() {
      if (!_isRecording) {
        _isRecording = true;
      }
    });
    print(noiseReading.toString());
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
                    onPressed: () {if (_isRecording == false)
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
        });
      },
    );
  }
}


