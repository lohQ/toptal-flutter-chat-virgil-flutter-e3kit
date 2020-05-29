import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toptal_chat/model/chatroon_repo.dart';
import 'package:toptal_chat/util/constants.dart';

import 'create_chatroom_event.dart';
import 'create_chatroom_state.dart';
import 'create_chatroom_view.dart';
import '../model/chat_repo.dart';
import '../model/user.dart';
import '../model/user_repo.dart';

class CreateChatroomBloc
    extends Bloc<CreateChatroomEvent, CreateChatroomState> {
  User currentUser;
  StreamSubscription<List<User>> chatUserSubscription;
  StreamSubscription<List<String>> requestStartChatUserSubscription;

  CreateChatroomBloc();

  void dispatchCancelEvent() {
    add(CancelCreateChatroomEvent());
  }

  void resetState() {
    dispatchCancelEvent();
  }

  @override
  CreateChatroomState get initialState {
    _initialize();
    return CreateChatroomState.initial();
  }

  void _initialize() async {
    currentUser = await UserRepo.getInstance().getCurrentUser();
    chatUserSubscription = ChatRepo.getInstance().getChatUsers().listen((users) {
      List<User> processedListOfUsers = users.where((user) => user.uid != currentUser.uid).toList();
      add(ChatroomUserListUpdatedEvent(processedListOfUsers));
    });
    requestStartChatUserSubscription = Firestore.instance.collection("users")
      .document(currentUser.uid).snapshots()
      .map((snapshot){
        final requestingUids = List<String>();
        if(snapshot.data.containsKey("requestStartChat")){
          final Iterable<String> requestStartChatData = snapshot.data["requestStartChat"].cast<String>();
          requestingUids.addAll(requestStartChatData);
        }
        return requestingUids;
      })
      .listen((uids){
        add(ChatroomRequestListUpdatedEvent(uids));
      });
  }

  void sendRequsetToStartChat(User user) async {
    final List<String> requestList = (await Firestore.instance.collection(FirestorePaths.USERS_COLLECTION)
      .document(user.uid).get()).data["requestStartChat"].cast<String>();
    if(!requestList.contains(currentUser.uid)){
      requestList.add(currentUser.uid);
    }
    await Firestore.instance.collection(FirestorePaths.USERS_COLLECTION)
      .document(user.uid).setData(
        {"requestStartChat" : requestList},
        merge: true
      );
    print("request sent");
  }

  void startChatUponRequest(User user, CreateChatroomWidget view) async {
    final requestList = state.requestStartChatUids;
    requestList.remove(user.uid);
    await Firestore.instance.collection("users")
      .document(currentUser.uid).setData(
        {"requestStartChat" : requestList},
        merge: true
      );
    print("request to start chat handled");
    startChat(user, view);
  }

  bool unableToStartChat(User user){
    return ChatroomRepo.instance.deletionPendingForUser(user.uid);
  }

  void startChat(User user, CreateChatroomWidget view) async {
    add(CreateChatroomRequestedEvent());
    assert(currentUser != null);
    assert(currentUser != user);

    List<User> chatroomUsers = List<User>(2);
    chatroomUsers[0] = user;
    chatroomUsers[1] = currentUser;
    ChatRepo.getInstance().startChatroomForUsers(chatroomUsers).then((chatroom) {
      view.navigateToSelectedChatroom(chatroom);
    });
  }

  @override
  Stream<CreateChatroomState> mapEventToState(CreateChatroomEvent event) async* {
    if (event is ChatroomUserListUpdatedEvent) {
      yield CreateChatroomState.isLoading(false, CreateChatroomState.users(event.users, state));
    } else if (event is CreateChatroomRequestedEvent) {
      yield CreateChatroomState.isLoading(true, state);
    } else if (event is CancelCreateChatroomEvent) {
      yield CreateChatroomState.canceled(state);
    } else if (event is ChatroomRequestListUpdatedEvent) {
      yield CreateChatroomState.requestingUsers(event.uids, state);
    }
  }

  @override
  Future<void> close() async {
    if (chatUserSubscription != null) {
      chatUserSubscription.cancel();
    }
    if (requestStartChatUserSubscription != null) {
      requestStartChatUserSubscription.cancel();
    }
    super.close();
  }
}
