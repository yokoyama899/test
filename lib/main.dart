// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, prefer_typing_uninitialized_variables, library_prefixes

import 'package:flutter/material.dart';

import 'package:agora_uikit/agora_uikit.dart';

import 'dart:core';

// import 'package:flutter/foundation.dart'
//     show debugDefaultTargetPlatformOverride;
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import 'package:http/http.dart' as http;

// import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

const appId = "1a2ea8f7a5c04b0a88116183654bb71c";
const token =
    "007eJxTYFCuYu9NST3S1SftYcVv5nJ+5vWbjhumXn2yy8VgYfDiG1wKDIaJRqmJFmnmiabJBiZJBokWFoaGZoYWxmamJklJ5obJUnzqybPiNZJ3HbzCxMgAgSA+C0NpXnY+AwMAAFwfjA==";
const channel = "unko";
// const channel =
//     "253Aed56e161f6c1c5f364b630c7de4c50a0c6b46affe80c75b6310f60ccb538fff9";
// const channel =
//     "007eJxTYBCfKD5BXNz5uZXrluxSfyv9/KjvUccCS6d6apceevhKSkSBwTDRKDXRIs080TTZwCTJINHCwtDQzNDC2MzUJCnJ3DA55Kda8mUvjeSZdn6sjAwQCOKzMJTmZeczMAAAiLMeKA==";
//
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("start ---------------------------------------------------");
  print("Handling a background message: ${message.messageId}");
  print("--------------------------------------------------- end");
  showCallkitIncoming(const Uuid().v4());
}

Future<void> showCallkitIncoming(String uuid) async {
  var params = <String, dynamic>{
    'id': uuid,
    'nameCaller': 'Hien Nguyen',
    'appName': 'Callkit',
    'avatar': 'https://i.pravatar.cc/100',
    'handle': '0123456789',
    'type': 0,
    'duration': 30000,
    'textAccept': 'Accept',
    'textDecline': 'Decline',
    'textMissedCall': 'Missed call',
    'textCallback': 'Call back',
    'extra': <String, dynamic>{'userId': '1a2b3c4d'},
    'headers': <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
    'android': <String, dynamic>{
      'isCustomNotification': true,
      'isShowLogo': false,
      'isShowCallback': false,
      'ringtonePath': 'system_ringtone_default',
      'backgroundColor': '#0955fa',
      'backgroundUrl': 'https://i.pravatar.cc/500',
      'actionColor': '#4CAF50'
    },
    'ios': <String, dynamic>{
      'iconName': 'CallKitLogo',
      'handleType': '',
      'supportsVideo': true,
      'maximumCallGroups': 2,
      'maximumCallsPerCallGroup': 1,
      'audioSessionMode': 'default',
      'audioSessionActive': true,
      'audioSessionPreferredSampleRate': 44100.0,
      'audioSessionPreferredIOBufferDuration': 0.005,
      'supportsDTMF': true,
      'supportsHolding': true,
      'supportsGrouping': false,
      'supportsUngrouping': false,
      'ringtonePath': 'system_ringtone_default'
    }
  };
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

Future<bool> startForegroundService() async {
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'Title of the notification',
    notificationText: 'Text of the notification',
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
      name: 'background_icon',
      defType: 'drawable',
    ), // Default is ic_launcher from folder mipmap
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  return FlutterBackground.enableBackgroundExecution();
}

void main() async {
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  var _uuid;
  var _currentUuid;

  bool _localUserJoined = false;
  int? _remoteUid;
  // RtcStats _stats = RtcStats();

  String token = 'Non token';

  late RtcEngine _engine;

  late final FirebaseMessaging _firebaseMessaging;

  @override
  void initState() {
    _uuid = Uuid();

    initFirebase();
    initForAgora();

    WidgetsBinding.instance.addObserver(this);
    checkAndNavigationCallingPage();

    super.initState();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print(state);
    if (state == AppLifecycleState.resumed) {
      //Check call when open app from background
      checkAndNavigationCallingPage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  getCurrentCall() async {
    //check current call from pushkit if possible
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        print('DATA: $calls');
        _currentUuid = calls[0]['id'];
        return calls[0];
      } else {
        _currentUuid = "";
        return null;
      }
    }
  }

  initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _firebaseMessaging = FirebaseMessaging.instance;

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: false,
      announcement: false,
      badge: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      // print('User granted provisional permission');
    } else {
      // print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // print(
      //     'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
      _currentUuid = _uuid.v4();

      //コール画面表示
      showCallkitIncoming(_currentUuid);
    });

    _firebaseMessaging.getToken().then((token) {
      print('Device Token FCM: $token');
    });
  }

  Future<void> initForAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    // create the engine for communicating with agora
    _engine = await RtcEngine.create(appId);

    // set up event handling for the engine
    _engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        print(
            '----                  $uid successfully joined channel: $channel ');
        setState(() {
          _remoteUid = uid;
          _localUserJoined = true;
        });
      },
      userJoined: (int uid, int elapsed) {
        print('----                  remote user $uid joined channel');
        setState(() {
          _remoteUid = uid;
          _localUserJoined = true;
        });
      },
      userOffline: (int uid, UserOfflineReason reason) {
        print('----                  remote user $uid left channel');
        setState(() {
          _remoteUid = null;
          _localUserJoined = false;
        });
      },
      leaveChannel: (stats) {
        print('--                   leaveChannel                      ---');
        _remoteUid = null;
        _localUserJoined = false;
      },
      // rtcStats: (stats) {
      //   //updates every two seconds
      //   print(stats.toJson());
      //   // if (_showStats) {
      //   //   setState(() {});
      //   // }
      // },
      error: (err) {
        print(err);
      },
    ));
    // enable video
    await _engine.enableVideo();

    // await _engine.joinChannel(token, 'firstchannel', null, 0);
  }

  checkAndNavigationCallingPage() async {
    var currentCall = await getCurrentCall();
    //ここから着信処理 着信取る
    print(
        "checkAndNavigationCallingPage ---------------------------------------------------");
    print(currentCall);
    print("--------------------------------------------------- end");
    if (currentCall != null) {
      // NavigationService.instance
      //     .pushNamedIfNotCurrent(AppRoute.callingPage, args: currentCall);

      await _engine.joinChannel(token, channel, null, 0);

      await FlutterCallkitIncoming.endCall(currentCall);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.cyan,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Uid: $_remoteUid'),
          actions: [
            IconButton(
              icon: Icon(Icons.token),
              onPressed: () async {
                // https: //us-central1-tks-notice-stg.cloudfunctions.net/genetateTokenSample
                var response = await http.post(Uri.https(
                  'us-central1-tks-notice-stg.cloudfunctions.net',
                  '/genetateTokenSample',
                  {
                    'uid': _remoteUid,
                    'role': 'publisher',
                  },
                ));

                print('@@@                 response                      @@@');
                print(response.body);
              },
            ),
            IconButton(
              icon: Icon(Icons.call_end),
              onPressed: () async {
                await _engine.disableAudio();
                await _engine.leaveChannel();

                setState(() {
                  _remoteUid = null;
                  _localUserJoined = false;
                });
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Center(
              child: _remoteVideo(),
            ),
            if (_localUserJoined)
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 200,
                  height: 150,
                  child: Center(
                    child: RtcLocalView.SurfaceView(),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: _remoteUid == null
            ? FloatingActionButton.extended(
                label: Text('Connect'),
                icon: Icon(Icons.call_sharp),
                onPressed: () async {
                  var response = await http.post(Uri.https(
                    'us-central1-tks-notice-stg.cloudfunctions.net',
                    '/genetateTokenSample',
                    {
                      'uid': _remoteUid,
                      'role': 'publisher',
                    },
                  ));

                  print(
                      '@@@                 response                      @@@');
                  print(response.body);

                  await _engine.joinChannel(response.body, channel, null, 0);
                },
              )
            : FloatingActionButton.extended(
                label: Text('Unconnect'),
                icon: Icon(Icons.call_end),
                onPressed: () async {
                  await _engine.disableAudio();
                  await _engine.leaveChannel();

                  setState(() {
                    _remoteUid = null;
                    _localUserJoined = false;
                  });
                },
              ),
      ),
    );
  }

// Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return RtcRemoteView.SurfaceView(
        uid: _remoteUid!,
        channelId: channel,
      );
    } else {
      return Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }
}
