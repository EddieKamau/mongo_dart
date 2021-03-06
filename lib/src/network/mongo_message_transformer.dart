part of mongo_dart;

class MongoMessageHandler {
  final _log = Logger('MongoMessageTransformer');
  final converter = PacketConverter();

  void handleData(List<int> data, EventSink<MongoResponseMessage> sink) {
    converter.addPacket(data);
    while (!converter.messages.isEmpty) {
      var buffer = BsonBinary.from(converter.messages.removeFirst());
      int opcodeFromWire = MongoResponseMessage.extractOpcode(buffer);
      MongoResponseMessage reply;
      if (opcodeFromWire == MongoMessage.Reply) {
        reply = MongoReplyMessage()..deserialize(buffer);
      } else {
        reply = MongoModernMessage.fromBuffer(buffer);
      }
      _log.fine(() => reply.toString());
      sink.add(reply);
    }
  }

  void handleDone(EventSink<MongoResponseMessage> sink) {
    if (!converter.isClear) {
      _log.warning(
          'Invalid state of PacketConverter in handleDone: $converter');
    }
    sink.close();
  }

  StreamTransformer<List<int>, MongoResponseMessage> get transformer =>
      StreamTransformer<List<int>, MongoResponseMessage>.fromHandlers(
          handleData: handleData, handleDone: handleDone);
}
