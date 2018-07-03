import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_msg_engine/flutter_msg_engine.dart';

void main() => runApp(new MyApp());

int SMsgId = 999;
int SMsgRef = 0;

// Use MsgProcessHandler process message.
class MyApp extends StatefulWidget implements MsgProcessHandler<String> {

  @override
  _MyAppState createState() {
    MsgEngine.instance.register(this, 150);
    return new _MyAppState();
  }

  @override
  void processMsg(MsgPack<String> msg) {
    print("MyApp: " + msg.data);
  }
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    // message start.
    MsgEngine.instance.start();
    // setting message log callback.
    MsgEngine.instance.onLog = ((MsgEngine engine, String text) {
      print(text);
    });
  }

  @override
  void dispose() {
    super.dispose();
    // stop message engine.
    MsgEngine.instance.stop();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      routes: <String, WidgetBuilder>{
        "/main": (BuildContext context) => new MyHomePage(),
      },
      home: new MyHomePage(title: "HomePage"),
    );
  }

  static _test() {
    MsgEngine.instance.regMsg(111, (MsgPack msg) {
      print(msg.toString());
    });
    MsgEngine.instance.regMsg(115, (MsgPack msg) {
      print("115: ${msg.toString()}");
    });

    MsgEngine.instance.regMsg(118, (MsgPack msg) {
      print("118: ${msg.data}");
    });

    print(MsgEngine().toString());
    MsgPack msg = const MsgBase(msgId: 123, sender: null);
    print("${msg.toString()}");

    MsgEngine.instance.sendMsgSync(const MsgTextBase(msgId: 111, text: "Hello MsgEngine."));
    MsgEngine.instance.sendMsg(const MsgTextBase(msgId: 112, text: "empty"));
    MsgEngine.instance.sendMsg(const MsgTextBase(msgId: 111, text: "Hello MsgEngine 2."));
    MsgEngine.instance.sendMsg(const MsgTextBase(msgId: 113, text: "..."));
    MsgEngine.instance.sendMsg(const MsgTextBase(msgId: 115, text: "Hello MsgEngine 3."));
    MsgEngine.instance.sendMsg(const MsgTextBase(msgId: 150, text: "message 150."));

    MsgEngine.instance.sendMsg(const MsgPackData<int>(msgId: 150, data: 150));
    MsgEngine.instance.sendMsg(const MsgPackData<int>(msgId: 118, data: 520));

    MsgEngine.instance.sendMsg(MsgPackData<String>(msgId: SMsgId - 1, data: "message id is $SMsgRef"));
    MsgEngine.instance.sendMsg(MsgPackData<String>(msgId: SMsgId, data: "message id is $SMsgRef"));

    SMsgRef++;
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> implements MsgProcessHandler<String> {
  int _msgid;
  String _msg;

  @override
  void initState() {
    super.initState();
    _msgid = SMsgId;
    SMsgId++;
    MsgEngine.instance.register(this, _msgid);
  }

  @override
  void dispose() {
    super.dispose();
    MsgEngine.instance.unRegister(_msgid);
  }

  @override
  void processMsg(MsgPack<String> msg) {
    print(msg.data);
    setState(() {
      _msg = msg.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text(widget.title ?? "New Page")),
      body: new Padding(padding: const EdgeInsets.all(8.0), child: new Wrap(
        direction: Axis.vertical,
        spacing: 8.0,
        children: <Widget>[
          new Text("msgId: $_msgid, Data: $_msg"),
          new FlatButton(onPressed: () {
            _MyAppState._test();
          }, color: Colors.blue, splashColor: Colors.yellow, child: new Text("Test MsgEngine")),
          new MaterialButton(onPressed: () {
            Navigator.pushNamed(context, "/main");
            new Timer(const Duration(milliseconds: 1000), () {
              MsgEngine.instance.sendMsg(MsgPackData<String>(msgId: _msgid, data: "start new page."));
            });
          }, color: Colors.grey, child: new Text("Open New Page"))
        ],
      )),
    );
  }
}