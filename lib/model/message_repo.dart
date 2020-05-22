import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:toptal_chat/model/message.dart';

class MessageToSave {
  final int id;
  final String value;
  final int outgoing;

  MessageToSave(this.id, this.value, bool outgoingBool)
    : outgoing = (outgoingBool ? 1 : 0);

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'value': value,
      'outgoing': outgoing,
    };
  }
}

class MessageRepo {
  static MessageRepo _instance = MessageRepo();
  Database database;

  MessageRepo get instance => _instance;

  static init() async {
    try{
      _instance.database = await openDatabase(
        join((await getDatabasesPath())+"chat_messages.db"),
      );
      print("message repo opened database");
    }catch(e){
      print("error opening database: $e");
    }
  }

  static dismiss() async {
    try{
      await _instance.database.close();
      print("message repo database closed");
    }catch(e){
      print("error closing database: $e");
    }
  }  

  createTable(String chatroomId) async {
    try{
      await database.execute(
        "CREATE TABLE IF NOT EXISTS $chatroomId(id INTEGER PRIMARY KEY ASC, value TEXT, outgoing INTEGER)"
      );
      print("table for chatroom $chatroomId created if not exists");
    }catch(e){
      print("error creating table: $e");
    }
  }

  deleteTable(String chatroomId) async {
    final deleteTarget = chatroomId;
    try{
      await database.delete(deleteTarget);
      print("table for chatroom $chatroomId deleted");
    }catch(e){
      print("error deleting table: $e");
    }
  }

  Future<List<MessageToDisplay>> readMessages(String chatroomId) async {
    try{
      List<Map<String,dynamic>> messagesMap = await database.query(chatroomId);
      List<MessageToDisplay> messages = List.generate(
        messagesMap.length, 
        (i)=>MessageToDisplay.fromMap(messagesMap[i]));
      print("saved messages from chatroom $chatroomId retrieved");
      return messages;
    }catch(e){
      print("error reading table: $e");
    }
  }

  saveMessage(MessageToDisplay m, String chatroomId) async {
    try{
      final id = await _getNextMsgId(chatroomId);
      final mToSave = MessageToSave(id, m.value, m.outgoing);
      await database.insert(chatroomId, mToSave.toMap());
      print("messageId is $id, message '${m.value}' saved");
    }catch(e){
      print("error saving message: $e");
    }
  }

  Future<int> _getNextMsgId(String chatroomId) async {
    try{
      return Sqflite
      .firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM $chatroomId'));
    }catch(e){
      print("error counting rows: $e");
    }
  }

}