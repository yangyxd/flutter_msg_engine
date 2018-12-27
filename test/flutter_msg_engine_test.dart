import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_msg_engine/flutter_msg_engine.dart';

void main() {
  int sMsgId = 999;
  int sMsgRef = 0;

  test('adds one to input values', () {
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

    MsgEngine.instance.sendMsg(MsgPackData<String>(msgId: sMsgId - 1, data: "message id is $sMsgRef"));
    MsgEngine.instance.sendMsg(MsgPackData<String>(msgId: sMsgId, data: "message id is $sMsgRef"));

    sMsgRef++;
  });
}
