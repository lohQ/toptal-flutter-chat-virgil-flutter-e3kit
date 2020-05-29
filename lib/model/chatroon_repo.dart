import 'package:shared_preferences/shared_preferences.dart';

class ChatroomRepo {
  final deletedChatrooms = List<String>();
  static const DELETED_CHATROOMS_KEY = "deleted_chatrooms";
  
  SharedPreferences sharedPreference;

  static final ChatroomRepo instance = ChatroomRepo._internal();
  ChatroomRepo._internal();

  Future<void> init() async {
    sharedPreference = await SharedPreferences.getInstance();
    final deletedChatroomsStrList = sharedPreference.getStringList(DELETED_CHATROOMS_KEY);
    print("deletedChatroomList: $deletedChatroomsStrList");
    if(deletedChatroomsStrList != null){
      deletedChatrooms.addAll(deletedChatroomsStrList);
    }
    print("chatroom repo initialized");
  }

  void addDeletedChatroom(String oppUserId) {
    deletedChatrooms.add(oppUserId);
    // print("added deletedChatrooms");
  }

  void removeDeletedChatroom(String oppUserId) {
    deletedChatrooms.remove(oppUserId);
    // print("removed deletedChatrooms");
  }

  bool deletionPendingForUser(String oppUserId){
    return deletedChatrooms.contains(oppUserId);
  }

 Future<void> save() async {
    await sharedPreference.setStringList(DELETED_CHATROOMS_KEY, deletedChatrooms);
    print("chatroom repo saved");
  }

}