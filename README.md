# flutter_msg_engine

Flutter Message Engine.
Flutter 消息引擎。

注册一个消息，在任何地方响应并处理。详细用法参考 example.

Wellcome to star.

> Supported  Platforms
> * Android
> * IOS

## How to Use

```yaml
# add this line to your dependencies
flutter_picker:
  git: git://github.com/yangyxd/flutter_msg_engine.git
```

```dart

import 'package:flutter_msg_engine/flutter_msg_engine.dart';

// add implements MsgProcessHandler
class MyApp extends StatefulWidget implements MsgProcessHandler<String> {
    ...
    @override
    _MyAppState createState() {
        MsgEngine.instance.register(this, 150);
        return new _MyAppState();
    }

    @override
    void processMsg(MsgPack<String> msg) {
        print("MyApp: " + msg.data);
    }
    ...
}

// register message
MsgEngine.instance.register(this, _msgid);

// unregister message
MsgEngine.instance.unRegister(_msgid);

// start engine
MsgEngine.instance.start();

// stop engine
MsgEngine.instance.stop();

// send message
MsgEngine.instance.sendMsg(MsgPackData<String>(msgId: _msgId, data: "message id is $_msgId"));

```

## LICENSE MIT
