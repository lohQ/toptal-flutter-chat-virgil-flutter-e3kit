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
  }

  void startChat(User user, CreateChatroomWidget view) async {
    add(CreateChatroomRequestedEvent());
    assert(currentUser != null);
    assert(currentUser != user);

    if(ChatroomRepo.instance.deletionPendingForUser(user.uid)){
      final doc = await Firestore.instance.collection(FirestorePaths.DELETED_CHATROOMS_COLLECTION)
        .document("${currentUser.uid}_${user.uid}").get();
      if(doc?.data != null){
        print("unable to create chatroom now: opp user ratchet channel deletion still pending");
        add(CancelCreateChatroomEvent());
        return;
      }else{
        ChatroomRepo.instance.removeDeletedChatroom(user.uid);
        print("chatroom deleted at opp side, local record deleted");
      }
    }

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
      yield CreateChatroomState.canceled();
    }
  }

  @override
  Future<void> close() async {
    if (chatUserSubscription != null) {
      chatUserSubscription.cancel();
    }
    super.close();
  }
}
