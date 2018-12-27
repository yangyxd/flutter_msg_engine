import 'dart:async';
import 'dart:collection';

typedef MsgProcHandlerCallBack<T>(MsgPack<T> msg);

/// 消息包接口
abstract class MsgPack<T> {
  const MsgPack();

  /// 消息ID
  int get msgId;

  /// 消息发送者
  get sender;

  String toString();

  T get data;
}

/// 消息处理器接口
abstract class MsgProcHandler<T> {
  /// 处理消息
  void processMsg(MsgPack<T> msg);
}

/// 消息处理器接口
abstract class MsgHandler extends MsgProcHandler {
  /// 已经注册过的消息ID
  List<int> get msgIds;

  /// 发送消息
  void sendMsg(MsgPack msg);
}

/// 消息包抽象类
abstract class MsgPackBase<T> implements MsgPack<T> {
  /// 消息ID
  final int msgId;

  /// 消息发送者
  final sender;

  const MsgPackBase({this.msgId, this.sender});

  String toString() {
    return "msgId: $msgId, sender: $sender";
  }
}

/// 消息包基类
class MsgBase<T> extends MsgPackBase<T> {
  const MsgBase({int msgId, sender}) : super(msgId: msgId, sender: sender);

  T get data => getData();

  T getData() {
    return null;
  }
}

/// 文本消息基础类
class MsgTextBase extends MsgBase<String> {
  const MsgTextBase({this.text, int msgId, sender})
      : super(msgId: msgId, sender: sender);

  /// 文本内容
  final String text;

  @override
  String toString() {
    return "msgId: $msgId, sender: $sender, text: $text";
  }

  @override
  String getData() {
    return text;
  }
}

/// 消息数据包
class MsgPackData<T> extends MsgBase<T> {
  const MsgPackData({this.data, int msgId, sender})
      : super(msgId: msgId, sender: sender);

  final T data;

  @override
  T getData() {
    return data;
  }

  @override
  String toString() {
    return "msgId: $msgId, sender: $sender, data: $data";
  }
}

/// 消息处理器
class MsgHandlerBase implements MsgHandler {
  /// 已注册的消息ID列表
  List<int> _msgIds;

  List<int> get msgIds => _msgIds;

  /// 所有者
  final owner;

  /// 消息处理回调
  final MsgProcHandler onProcessMsg;

  MsgHandlerBase({this.owner, List<int> msgIds, this.onProcessMsg}) {
    this._msgIds = msgIds;
    if (this._msgIds == null) this._msgIds = new List<int>();
  }

  /// 处理消息
  void processMsg(MsgPack msg) async {
    if (onProcessMsg != null) onProcessMsg.processMsg(msg);
  }

  /// 异步发送消息
  void sendMsg(MsgPack msg) {
    if (msg == null) return;
    MsgEngine.instance.sendMsg(msg);
  }

  /// 同步发送消息
  void sendMsgSync(MsgPack msg) {
    if (msg == null) return;
    MsgEngine.instance.sendMsgSync(msg);
  }

  /// 释放资源
  void dispose() {
    if (_msgIds != null && (MsgEngine._instance != null)) {
      MsgEngine._instance.unRegisterHandler(this);
      _msgIds.clear();
    }
  }

  /// 添加消息ID
  void addMsgId(int msgId) {
    if (_msgIds.contains(msgId)) return;
    _msgIds.add(msgId);
    MsgEngine.instance.register(this, msgId);
  }

  /// 添加消息id列表
  void addMsgIds(List<int> msgId) {
    if (msgId == null || msgId.length == 0) return;
    if (_msgIds.length == 0) {
      for (int i = 0; i < msgId.length; i++) {
        int id = msgId[i];
        _msgIds.add(id);
        MsgEngine.instance.register(this, id);
      }
    } else {
      for (int i = 0; i < msgId.length; i++) {
        int id = msgId[i];
        if (_msgIds.contains(id)) continue;
        _msgIds.add(id);
        MsgEngine.instance.register(this, id);
      }
    }
  }

  /// 移除一个消息id
  void removeMsgId(int msgId) {
    if (_msgIds.remove(msgId)) {
      MsgEngine.instance.unRegister(msgId);
    }
  }

  /// 清空消息id
  void clearMsgId() {
    MsgEngine.instance.unRegisterHandler(this);
    _msgIds.clear();
  }
}

/// 消息处理器 （回调方式）
class MsgHandlerEvent extends MsgHandlerBase {
  final Map<int, MsgProcHandlerCallBack> _eventList =
  new Map<int, MsgProcHandlerCallBack>();

  MsgHandlerEvent({owner, List<int> msgIds})
      : super(owner: owner, msgIds: msgIds);

  @override
  void processMsg(MsgPack msg) {
    MsgProcHandlerCallBack callback = _eventList[msg.msgId];
    if (callback != null) callback(msg);
  }
}

/// 日志输出事件
typedef MsgEngineLogEvent(MsgEngine engine, String text);

/// 消息引擎
class MsgEngine {
  factory MsgEngine() {
    return _getInstance();
  }

  MsgEngine._internal();

  /// 单例的消息引擎
  static MsgEngine get instance => _getInstance();

  static MsgEngine _instance;

  static MsgEngine _getInstance() {
    if (_instance == null) {
      _instance = new MsgEngine._internal();
    }
    return _instance;
  }

  final Map<int, List<MsgProcHandler>> _msgHandlerMap =
  new Map<int, List<MsgProcHandler>>();
  final Queue<MsgPack> _msgQueue = new Queue<MsgPack>();

  /// 是否暂停
  bool isPause = false;

  /// 是否正在释放
  bool isDestroying = false;

  /// 消息分发速率。此值越大，消息分发速度越快，越容易卡界面
  int speedRatio = 250;

  /// 引擎自带的消息处理器
  MsgHandlerEvent msgHandler;

  /// 日志输出事件
  MsgEngineLogEvent onLog;

  bool _messageQueueRuning = false;
  int _lastStartMsgQueue = 0;

  /// 消息队列是否为空
  bool get isEmpty => _msgQueue.isEmpty;

  /// 消息队列长度
  int get msgQueueLength => _msgQueue.length;

  /// 开始消息引擎
  void start() async {
    if (_messageQueueRuning == false ||
        currentTimeMillis() - _lastStartMsgQueue > 5000) {
      _messageQueueRuning = false;
      isPause = false;
      _startMessageQueue();
    }
  }

  /// 暂停消息引擎
  void pause([bool value = true]) {
    isPause = value;
  }

  /// 停止消息引擎
  void stop() {
    isDestroying = true;
  }

  void _startMessageQueue() {
    if (_messageQueueRuning || isDestroying) return;
    _messageQueueRuning = true;
    _lastStartMsgQueue = currentTimeMillis();
    _messageQueueProcess();
  }

  bool __messageQueueProcessing = false;

  // 处理消息队列
  _messageQueueProcess() async {
    if (__messageQueueProcessing) return;
    __messageQueueProcessing = true;
    try {
      int _ref = 0;
      while (true) {
        //print("msg process.");
        if (isPause || _msgQueue.isEmpty) {
          return;
        } else {
          _ref++;
          if (_ref > speedRatio) {
            if (!isDestroying) {
              await Future.delayed(Duration(milliseconds: 20));
              if (isDestroying || _msgQueue.isEmpty) {
                __messageQueueProcessing = false;
                return;
              }
              _ref = 0;
            }
          }

          MsgPack msg = _msgQueue.first;
          try {
            _msgQueue.removeFirst();
            List<MsgProcHandler> o = _msgHandlerMap[msg.msgId];
            if (o != null && o.length > 0) sendMsgToHandler(o, msg);
          } catch (e) {
            _log(e.toString());
          }
        }
      }
    } catch (e) {
      _log(e.toString());
    } finally {
      __messageQueueProcessing = false;
    }
  }

  static int currentTimeMillis() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  void _log(String msg) {
    if (onLog != null) onLog(this, msg);
  }

  void sendMsgToHandler(List<MsgProcHandler> handler, MsgPack msg) async {
    for (int i = 0; i < handler.length; i++) {
      try {
        handler[i].processMsg(msg);
      } catch (e) {
        _log("sendMsg: ${e.toString()}");
      }
    }
  }

  /// 发送消息
  void sendMsg(MsgPack msg) async {
    _msgQueue.add(msg);
    if (_messageQueueRuning && !isDestroying)
      _messageQueueProcess();
  }

  /// 同步发送消息
  void sendMsgSync(MsgPack msg) {
    sendMsgToHandler(getHandlerList(msg.msgId), msg);
  }

  /// 获取指定MsgID的消息处理器链表
  List<MsgProcHandler> getHandlerList(int msgId) {
    return _msgHandlerMap[msgId];
  }

  bool existHandler(List<MsgProcHandler> handlers, MsgProcHandler value) {
    return handlers.contains(value);
  }

  /// 消息处理器注册
  void register(MsgProcHandler msgHandler, int msgId) {
    if (msgHandler == null || msgId == 0) return;
    print('register: $msgId');
    List<MsgProcHandler> items = getHandlerList(msgId);
    if (items == null) {
      items = new List<MsgProcHandler>();
      items.add(msgHandler);
      _msgHandlerMap[msgId] = items;
    } else {
      if (!existHandler(items, msgHandler)) {
        items.add(msgHandler);
      }
    }
  }

  /// 消息处理器注册
  void registers(MsgProcHandler msgHandler, List<int> msgIds) {
    if (msgHandler == null || msgIds == null || msgIds.length == 0) return;
    for (int i=0; i<msgIds.length; i++) {
      int msgId = msgIds[i];
      if (msgId == 0) continue;
      register(msgHandler, msgId);
    }
  }

  /// 反注册消息处理器
  void unRegisterHandler(MsgProcHandler msgHandler) {
    if (msgHandler == null) return;
    if (msgHandler is MsgHandler) {
      List<int> keys = msgHandler.msgIds;
      if (keys == null || keys.length == 0) return;
      for (int i = 0; i < keys.length; i++) {
        int id = keys[i];
        List<MsgHandler> items = _msgHandlerMap[id];
        if (items != null) items.remove(msgHandler);
      }
    } else {
      List<int> keys = _msgHandlerMap.keys.toList();
      for (int i=0; i< keys.length; i++) {
        List<MsgProcHandler> items = _msgHandlerMap[keys[i]];
        if (items == null) continue;
        items.remove(msgHandler);
      }
    }
  }

  /// 反注册消息ID
  void unRegister(int msgId) {
    print('unRegister: $msgId, id count: ${_msgHandlerMap.length}');
    _msgHandlerMap.remove(msgId);
  }

  /// 解除所有已经注册的消息处理器
  void clearRegister() {
    _msgHandlerMap.clear();
  }

  /// 注册消息
  void regMsg(int msgId, MsgProcHandlerCallBack msgProcess) {
    if (msgHandler == null) msgHandler = new MsgHandlerEvent(owner: this);
    msgHandler._eventList[msgId] = msgProcess;
    msgHandler.addMsgId(msgId);
  }

  /// 取消注册的消息ID
  void unRegMsg(int msgId) {
    if (msgHandler == null) return;
    msgHandler.removeMsgId(msgId);
    msgHandler._eventList.remove(msgId);
  }
}
