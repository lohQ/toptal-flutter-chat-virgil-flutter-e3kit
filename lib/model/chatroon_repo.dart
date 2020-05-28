import 'package:shared_preferences/shared_preferences.dart';

class ChatroomRepo {
  final deletedChatrooms = List<String>();
  final activeChatrooms = List<String>();
  static const DELETED_CHATROOMS_KEY = "deleted_chatrooms";
  static const ACTIVE_CHATROOMS_KEY = "active_chatrooms";
  
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
    final activeChatroomsStrList = sharedPreference.getStringList(ACTIVE_CHATROOMS_KEY);
    print("activeChatroomList: $activeChatroomsStrList");
    if(activeChatroomsStrList != null){
      activeChatrooms.addAll(activeChatroomsStrList);
    }
    print("chatroom repo initialized");
  }

  void addDeletedChatroom(String pendingDeletionUserId) {
    deletedChatrooms.add(pendingDeletionUserId);
    // print("added deletedChatrooms");
  }

  void removeDeletedChatroom(String pendingDeletionUserId) {
    deletedChatrooms.remove(pendingDeletionUserId);
    // print("removed deletedChatrooms");
  }

  bool deletionPendingForUser(String oppId){
    return deletedChatrooms.contains(oppId);
  }

  void removeActiveChatroom(String userId) {
    activeChatrooms.remove(userId);
    // print("removed activeChatrooms");
  }

  void setActiveChatroom(List<String> userIds) {
    activeChatrooms.clear();
    activeChatrooms.addAll(userIds);
    // print("updated activeChatrooms");
  }

  Future<void> save() async {
    await sharedPreference.setStringList(DELETED_CHATROOMS_KEY, deletedChatrooms);
    await sharedPreference.setStringList(ACTIVE_CHATROOMS_KEY, activeChatrooms);
    print("chatroom repo saved");
  }

}