import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../util/constants.dart';
import '../util/serialization_util.dart';
import 'chatroom.dart';
import 'firebase_repo.dart';
import 'user.dart';

class ChatRepo {
  static ChatRepo _instance;

  final Firestore _firestore;

  final _chatUsersSubject = BehaviorSubject<List<User>>();

  ChatRepo._internal(this._firestore);

  factory ChatRepo.getInstance() {
    if (_instance == null) {
      _instance = ChatRepo._internal(FirebaseRepo.getInstance().firestore);
      _instance._getChatUsersInternal();
    }
    return _instance;
  }

  void _getChatUsersInternal() {
    _firestore
        .collection(FirestorePaths.USERS_COLLECTION)
        .orderBy("displayName")
        .snapshots()
        .map((data) => Deserializer.deserializeUsers(data.documents))
        .listen((users) {
      _chatUsersSubject.sink.add(users);
    });
  }

  Stream<List<User>> getChatUsers() {
    return _chatUsersSubject.stream;
  }

  Future<List<String>> getUsersFromChatroom(String chatroomId) async {
    DocumentReference chatroomRef = _firestore.document(FirestorePaths.CHATROOMS_COLLECTION + "/" + chatroomId);
    if (chatroomRef != null) {
      final chatroomDoc = await chatroomRef.get();
      try{
        final participantInstances = chatroomDoc.data["participants"];
        List<String> participantUids = List<String>();
        for(int i = 0; i < participantInstances.length; i++){
          participantUids.add((await participantInstances[i].get()).data["uid"]);
        }
        return participantUids;
      }catch(e){print(e);}
    }
    return null;
  }

  Future<SelectedChatroom> getChatroom(String chatroomId, User currentUser, User otherUser) async {
    DocumentReference chatroomRef = _firestore.document(FirestorePaths.CHATROOMS_COLLECTION + "/" + chatroomId);
    if (chatroomRef != null) {
      List<User> users = List(2);
      users[0] = otherUser;
      users[1] = currentUser;
      try {
        return SelectedChatroom(chatroomId, otherUser.uid, otherUser.displayName);
      } catch (error) {
        print(error);
        return null;
      }
    }
    else {
      return null;
    }
  }

  Stream<List<Chatroom>> getChatroomsForUser(User user) {
    DocumentReference userRef =
        _firestore.document(FirestorePaths.USERS_COLLECTION + "/" + user.uid);
    return _firestore
        .collection(FirestorePaths.CHATROOMS_COLLECTION)
        .where(
          "participants",
          arrayContains: userRef,
        )
        .snapshots()
        .map((data) => Deserializer.deserializeChatrooms(
            data.documents, _chatUsersSubject.value));
  }

  Stream<QuerySnapshot> getMessagesForChatroom(String chatroomId) {
    return _firestore
        .collection(FirestorePaths.CHATROOMS_COLLECTION)
        .document(chatroomId)
        .collection(FirestorePaths.MESSAGES_COLLECTION)
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  Future<SelectedChatroom> startChatroomForUsers(List<User> users) async {
    DocumentReference userRef = _firestore
        .collection(FirestorePaths.USERS_COLLECTION)
        .document(users[1].uid);
    QuerySnapshot queryResults = await _firestore
        .collection(FirestorePaths.CHATROOMS_COLLECTION)
        .where("participants", arrayContains: userRef)
        .getDocuments();
    DocumentReference otherUserRef = _firestore
        .collection(FirestorePaths.USERS_COLLECTION)
        .document(users[0].uid);
    DocumentSnapshot roomSnapshot = queryResults.documents.firstWhere((room) {
      return room.data["participants"].contains(otherUserRef);
    }, orElse: () => null);
    if (roomSnapshot != null) {
      return SelectedChatroom(roomSnapshot.documentID, users[0].uid, users[0].displayName);
    } else {
      Map<String, dynamic> chatroomMap = Map<String, dynamic>();
      List<DocumentReference> participants = List<DocumentReference>(2);
      participants[0] = otherUserRef;
      participants[1] = userRef;
      chatroomMap["participants"] = participants;
      DocumentReference reference = await _firestore
          .collection(FirestorePaths.CHATROOMS_COLLECTION)
          .add(chatroomMap);
      DocumentSnapshot chatroomSnapshot = await reference.get();
      return SelectedChatroom(chatroomSnapshot.documentID, users[0].uid, users[0].displayName);
    }
  }

  Future<bool> sendMessageToChatroom(String chatroomId, User user, String message) async {
    try {
      CollectionReference chatroomRef = _firestore.collection(FirestorePaths.CHATROOMS_COLLECTION).document(chatroomId)
        .collection(FirestorePaths.MESSAGES_COLLECTION);
      Map<String, dynamic> serializedMessage = {
        "author" : user.uid,
        "timestamp" : DateTime.now(),
        "value" : message
      };
      chatroomRef.add(serializedMessage);
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  void dismiss() {
    _chatUsersSubject.close();
  }
}
