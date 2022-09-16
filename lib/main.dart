// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:untitled/in_coming.dart';
import 'package:untitled/test01.dart';

import 'dart:core';

// import 'package:flutter/foundation.dart'
//     show debugDefaultTargetPlatformOverride;
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:untitled/test02.dart';
import 'package:untitled/test04.dart';
import 'package:untitled/test05.dart';

Future<bool> startForegroundService() async {
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'Title of the notification',
    notificationText: 'Text of the notification',
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  return FlutterBackground.enableBackgroundExecution();
}

void main() {
  if (WebRTC.platformIsAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    startForegroundService();
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late List<RouteItem> items;

  @override
  void initState() {
    super.initState();
    _initItems();
  }

  ListBody _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter-WebRTC example'),
        ),
        body: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0.0),
            itemCount: items.length,
            itemBuilder: (context, i) {
              return _buildRow(context, items[i]);
            }),
      ),
    );
  }

  void _initItems() {
    items = <RouteItem>[
      RouteItem(
          title: 'GetUserMedia',
          push: (BuildContext context) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => GetUserMediaSample()),
            );
          }),
      RouteItem(
          title: 'GetDisplayMedia',
          push: (BuildContext context) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => GetDisplayMediaSample()),
            );
          }),
      RouteItem(
          title: 'LoopBack Sample',
          push: (BuildContext context) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => LoopBackSample()),
            );
          }),
      RouteItem(
          title: 'LoopBack Sample (Unified Tracks)',
          push: (BuildContext context) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => LoopBackSample()),
            );
          }),
      RouteItem(
          title: 'DataChannelLoopBackSample',
          push: (BuildContext context) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      DataChannelLoopBackSample()),
            );
          }),
      RouteItem(
          title: 'inComing',
          push: (BuildContext context) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (BuildContext context) => InComing()),
            );
          }),

    ];
  }
}

typedef RouteCallback = void Function(BuildContext context);

class RouteItem {
  RouteItem({
    required this.title,
    this.subtitle,
    this.push,
  });

  final String title;
  final String? subtitle;
  final RouteCallback? push;
}
