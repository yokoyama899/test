// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, avoid_print, avoid_function_literals_in_foreach_calls, non_constant_identifier_names, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_interpolation_to_compose_strings

import 'dart:core';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/*
 * getDisplayMedia sample
 */
class GetDisplayMediaSample extends StatefulWidget {
  static String tag = 'get_display_media_sample';

  @override
  _GetDisplayMediaSampleState createState() => _GetDisplayMediaSampleState();
}

class _GetDisplayMediaSampleState extends State<GetDisplayMediaSample> {
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  DesktopCapturerSource? selected_source_;

  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_inCalling) {
      _stop();
    }
    _localRenderer.dispose();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
  }

  Future<void> selectScreenSourceDialog(BuildContext context) async {
    if (WebRTC.platformIsMacOS || WebRTC.platformIsWindows) {
      final source = await showDialog<DesktopCapturerSource>(
        context: context,
        builder: (context) => ScreenSelectDialog(),
      );
      if (source != null) {
        await _makeCall(source);
      }
    } else {
      await _makeCall(null);
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _makeCall(DesktopCapturerSource? source) async {
    setState(() {
      selected_source_ = source;
    });

    try {
      var stream =
          await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
        'video': selected_source_ == null
            ? true
            : {
                'deviceId': {'exact': selected_source_!.id},
                'mandatory': {'frameRate': 30.0}
              }
      });
      stream.getVideoTracks()[0].onEnded = () {
        print(
            'By adding a listener on onEnded you can: 1) catch stop video sharing on Web');
      };

      _localStream = stream;
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      print(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _inCalling = true;
    });
  }

  Future<void> _stop() async {
    try {
      if (kIsWeb) {
        _localStream?.getTracks().forEach((track) => track.stop());
      }
      await _localStream?.dispose();
      _localStream = null;
      _localRenderer.srcObject = null;
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _hangUp() async {
    await _stop();
    setState(() {
      _inCalling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GetDisplayMedia source: ' +
            (selected_source_ != null ? selected_source_!.name : '')),
        actions: [],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
              child: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white10,
            child: Stack(children: <Widget>[
              if (_inCalling)
                Container(
                  margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(color: Colors.black54),
                  child: RTCVideoView(_localRenderer),
                )
            ]),
          ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _inCalling ? _hangUp() : selectScreenSourceDialog(context);
        },
        tooltip: _inCalling ? 'Hangup' : 'Call',
        child: Icon(_inCalling ? Icons.call_end : Icons.phone),
      ),
    );
  }
}

class ThumbnailWidget extends StatefulWidget {
  const ThumbnailWidget(
      {Key? key,
      required this.source,
      required this.selected,
      required this.onTap})
      : super(key: key);
  final DesktopCapturerSource source;
  final bool selected;
  final Function(DesktopCapturerSource) onTap;

  @override
  _ThumbnailWidgetState createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions.add(widget.source.onThumbnailChanged.stream.listen((event) {
      setState(() {});
    }));
    _subscriptions.add(widget.source.onNameChanged.stream.listen((event) {
      setState(() {});
    }));
  }

  @override
  void deactivate() {
    _subscriptions.forEach((element) {
      element.cancel();
    });
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: Container(
          decoration: widget.selected
              ? BoxDecoration(
                  border: Border.all(width: 2, color: Colors.blueAccent))
              : null,
          child: InkWell(
            onTap: () {
              print('Selected source id => ${widget.source.id}');
              widget.onTap(widget.source);
            },
            child: widget.source.thumbnail != null
                ? Image.memory(
                    widget.source.thumbnail!,
                    gaplessPlayback: true,
                    alignment: Alignment.center,
                  )
                : Container(),
          ),
        )),
        Text(
          widget.source.name,
          style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight:
                  widget.selected ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}

// ignore: must_be_immutable
class ScreenSelectDialog extends Dialog {
  ScreenSelectDialog() {
    Future.delayed(Duration(milliseconds: 100), () {
      _getSources();
    });
    _subscriptions.add(desktopCapturer.onAdded.stream.listen((source) {
      _sources[source.id] = source;
      _stateSetter?.call(() {});
    }));

    _subscriptions.add(desktopCapturer.onRemoved.stream.listen((source) {
      _sources.remove(source.id);
      _stateSetter?.call(() {});
    }));

    _subscriptions
        .add(desktopCapturer.onThumbnailChanged.stream.listen((source) {
      _stateSetter?.call(() {});
    }));
  }
  final Map<String, DesktopCapturerSource> _sources = {};
  SourceType _sourceType = SourceType.Screen;
  DesktopCapturerSource? _selected_source;
  final List<StreamSubscription<DesktopCapturerSource>> _subscriptions = [];
  StateSetter? _stateSetter;
  Timer? _timer;

  void _ok(context) async {
    _timer?.cancel();
    _subscriptions.forEach((element) {
      element.cancel();
    });
    Navigator.pop<DesktopCapturerSource>(context, _selected_source);
  }

  void _cancel(context) async {
    _timer?.cancel();
    _subscriptions.forEach((element) {
      element.cancel();
    });
    Navigator.pop<DesktopCapturerSource>(context, null);
  }

  Future<void> _getSources() async {
    try {
      var sources = await desktopCapturer.getSources(types: [_sourceType]);
      sources.forEach((element) {
        print(
            'name: ${element.name}, id: ${element.id}, type: ${element.type}');
      });
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 3), (timer) {
        desktopCapturer.updateSources(types: [_sourceType]);
      });
      _sources.clear();
      sources.forEach((element) {
        _sources[element.id] = element;
      });
      _stateSetter?.call(() {});
      return;
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
          child: Container(
        width: 640,
        height: 560,
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10),
              child: Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Choose what to share',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      child: Icon(Icons.close),
                      onTap: () => _cancel(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    _stateSetter = setState;
                    return DefaultTabController(
                      length: 2,
                      child: Column(
                        children: <Widget>[
                          Container(
                            constraints: BoxConstraints.expand(height: 24),
                            child: TabBar(
                                onTap: (value) => Future.delayed(
                                        Duration(milliseconds: 300), () {
                                      _sourceType = value == 0
                                          ? SourceType.Screen
                                          : SourceType.Window;
                                      _getSources();
                                    }),
                                tabs: [
                                  Tab(
                                      child: Text(
                                    'Entire Screen',
                                    style: TextStyle(color: Colors.black54),
                                  )),
                                  Tab(
                                      child: Text(
                                    'Window',
                                    style: TextStyle(color: Colors.black54),
                                  )),
                                ]),
                          ),
                          SizedBox(
                            height: 2,
                          ),
                          Expanded(
                            child: Container(
                              child: TabBarView(children: [
                                Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      child: GridView.count(
                                        crossAxisSpacing: 8,
                                        crossAxisCount: 2,
                                        children: _sources.entries
                                            .where((element) =>
                                                element.value.type ==
                                                SourceType.Screen)
                                            .map((e) => ThumbnailWidget(
                                                  onTap: (source) {
                                                    setState(() {
                                                      _selected_source = source;
                                                    });
                                                  },
                                                  source: e.value,
                                                  selected:
                                                      _selected_source?.id ==
                                                          e.value.id,
                                                ))
                                            .toList(),
                                      ),
                                    )),
                                Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      child: GridView.count(
                                        crossAxisSpacing: 8,
                                        crossAxisCount: 3,
                                        children: _sources.entries
                                            .where((element) =>
                                                element.value.type ==
                                                SourceType.Window)
                                            .map((e) => ThumbnailWidget(
                                                  onTap: (source) {
                                                    setState(() {
                                                      _selected_source = source;
                                                    });
                                                  },
                                                  source: e.value,
                                                  selected:
                                                      _selected_source?.id ==
                                                          e.value.id,
                                                ))
                                            .toList(),
                                      ),
                                    )),
                              ]),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ButtonBar(
                children: <Widget>[
                  MaterialButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black54),
                    ),
                    onPressed: () {
                      _cancel(context);
                    },
                  ),
                  MaterialButton(
                    color: Theme.of(context).primaryColor,
                    child: Text(
                      'Share',
                    ),
                    onPressed: () {
                      _ok(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
