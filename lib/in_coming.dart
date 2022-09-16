// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';
// import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

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

class Hogeeeeeeee {
  late Uuid _uuid;
  var _currentUuid;

  late final FirebaseMessaging _firebaseMessaging;

  void init() async {
    _uuid = const Uuid();
    await initFirebase();
    // WidgetsBinding.instance.addObserver(this);
    //Check call when open app from terminated
    await checkAndNavigationCallingPage();
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

  checkAndNavigationCallingPage() async {
    var currentCall = await getCurrentCall();
    //ここから着信処理
    print(
        "checkAndNavigationCallingPage ---------------------------------------------------");
    print(currentCall);
    print("--------------------------------------------------- end");
    if (currentCall != null) {
      // NavigationService.instance
      //     .pushNamedIfNotCurrent(AppRoute.callingPage, args: currentCall);

      //ここから着信処理
      print("start ---------------------------------------------------");
      print(currentCall);
      print("--------------------------------------------------- end");
    }
  }

  initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _firebaseMessaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
          'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
      _currentUuid = _uuid.v4();
      showCallkitIncoming(_currentUuid);
    });
    _firebaseMessaging.getToken().then((token) {
      print('Device Token FCM: $token');
    });
  }

  Future<void> getDevicePushTokenVoIP() async {
    var devicePushTokenVoIP =
        await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    print('*****   devicePushTokenVoIP  :     $devicePushTokenVoIP');
  }
}

// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//   var _uuid;
//   var _currentUuid;

//   late final FirebaseMessaging _firebaseMessaging;

//   @override
//   void initState() {
//     super.initState();
//     _uuid = Uuid();
//     initFirebase();
//     WidgetsBinding.instance.addObserver(this);
//     //Check call when open app from terminated
//     checkAndNavigationCallingPage();
//   }

//   getCurrentCall() async {
//     //check current call from pushkit if possible
//     var calls = await FlutterCallkitIncoming.activeCalls();
//     if (calls is List) {
//       if (calls.isNotEmpty) {
//         print('DATA: $calls');
//         this._currentUuid = calls[0]['id'];
//         return calls[0];
//       } else {
//         this._currentUuid = "";
//         return null;
//       }
//     }
//   }

//   checkAndNavigationCallingPage() async {
//     var currentCall = await getCurrentCall();
//     if (currentCall != null) {
//       // NavigationService.instance
//       //     .pushNamedIfNotCurrent(AppRoute.callingPage, args: currentCall);
//     }
//   }

//   @override
//   Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
//     print(state);
//     if (state == AppLifecycleState.resumed) {
//       //Check call when open app from background
//       checkAndNavigationCallingPage();
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   initFirebase() async {
//     await Firebase.initializeApp();
//     _firebaseMessaging = FirebaseMessaging.instance;
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       print(
//           'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
//       this._currentUuid = _uuid.v4();
//       showCallkitIncoming(this._currentUuid);
//     });
//     _firebaseMessaging.getToken().then((token) {
//       print('Device Token FCM: $token');
//     });
//   }

//   Future<void> getDevicePushTokenVoIP() async {
//     var devicePushTokenVoIP =
//         await FlutterCallkitIncoming.getDevicePushTokenVoIP();
//     print(devicePushTokenVoIP);
//   }
// }
