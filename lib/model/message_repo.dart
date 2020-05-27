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

  String getTableNameForChatroom(String chatroomId){
    return "Chatroom_$chatroomId";
  }

  Future createTable(String chatroomId) async {
    final String tableName = getTableNameForChatroom(chatroomId);
    try{
      await database.execute(
        "CREATE TABLE IF NOT EXISTS $tableName(id INTEGER PRIMARY KEY ASC, value TEXT, outgoing INTEGER)"
      );
      print("table for chatroom $chatroomId created if not exists");
    }catch(e){
      print("error creating table: $e");
    }
  }

  deleteTable(String chatroomId) async {
    final deleteTarget = getTableNameForChatroom(chatroomId);
    try{
      await database.delete(deleteTarget);
      print("table for chatroom $chatroomId deleted");
    } on DatabaseException catch (e){
      if(e.isNoSuchTableError()){
        print("error deleting table: table does not exist");
      }else if(e.isDatabaseClosedError()){
        print("error deleting table: database closed");
      }else{
        print("error deleting table: $e");
      }
    } catch (e){
      print("error deleting table: $e");
    }
  }

  Future<List<MessageToDisplay>> readMessages(String chatroomId) async {
    final readTarget = getTableNameForChatroom(chatroomId);
    try{
      List<Map<String,dynamic>> messagesMap = await database.query(readTarget);
      List<MessageToDisplay> messages = List.generate(
        messagesMap.length, 
        (i)=>MessageToDisplay.fromMap(messagesMap[i]));
      print("saved messages from chatroom $chatroomId retrieved");
      return messages;
    }catch(e){
      print("error reading table: $e");
      return null;
    }
  }

  saveMessage(MessageToDisplay m, String chatroomId) async {
    final saveTarget = getTableNameForChatroom(chatroomId);
    try{
      final id = await _getNextMsgId(saveTarget);
      final mToSave = MessageToSave(id, m.value, m.outgoing);
      await database.insert(saveTarget, mToSave.toMap());
      print("messageId is $id, message '${m.value}' saved");
    }catch(e){
      print("error saving message: $e");
    }
  }

  Future<int> _getNextMsgId(String table) async {
    try{
      return Sqflite
      .firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM $table'));
    }catch(e){
      print("error counting rows: $e");
      return null;
    }
  }

}