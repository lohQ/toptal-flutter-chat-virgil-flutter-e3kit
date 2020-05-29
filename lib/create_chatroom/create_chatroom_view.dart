import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../util/constants.dart';
import '../navigation_helper.dart';
import '../model/user.dart';
import '../model/chatroom.dart';
import '../main/main_user_item.dart';
import 'create_chatroom_bloc.dart';
import 'create_chatroom_state.dart';

class CreateChatroomScreen extends StatefulWidget {
  CreateChatroomScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CreateChatroomState();
}

class _CreateChatroomState extends State<CreateChatroomScreen> {

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateChatroomBloc>(
      create: (context) => CreateChatroomBloc(),
      child: CreateChatroomWidget(parentContext:context)
    );
  }

}

class CreateChatroomWidget extends StatelessWidget {
  final parentContext;
  const CreateChatroomWidget({Key key, @required this.parentContext}) : super(key: key); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Select user"),
        ),
        body: BlocBuilder(
            bloc: BlocProvider.of<CreateChatroomBloc>(context),
            builder: (context, CreateChatroomState state) {
              if (state.canceled) {
                return Center(
                  child: Text(
                    "unable to create chatroom now: opp user ratchet channel deletion still pending",
                    style: TextStyle(fontSize: 16)),
                );
              }
              if (state.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 4.0,
                  ),
                );
              }
              return ListView.builder(
                itemBuilder: (context, index) {
                  final unableToStartChat = BlocProvider.of<CreateChatroomBloc>(context).unableToStartChat(state.users[index]);
                  final requestedToStartChat = state.requestStartChatUids.contains(state.users[index].uid);
                  return InkWell(
                      child: _buildItem(state.users[index], unableToStartChat, requestedToStartChat),
                      onTap: unableToStartChat
                      ? () {
                        showDialog(
                          context: context, child: _buildDialog(context, state.users[index]));
                        }
                      : () async {
                          requestedToStartChat
                          ? BlocProvider.of<CreateChatroomBloc>(context).startChatUponRequest(state.users[index], this)
                          : BlocProvider.of<CreateChatroomBloc>(context).startChat(state.users[index], this);
                        }
                  );
                },
                itemCount: state.users.length,
                padding: EdgeInsets.all(UIConstants.SMALLER_PADDING),
              ); 
            }));
  }

  Widget _buildItem(User user, bool unableToStartChat, bool requestedToStartChat) {
    return UserItem(user: user, unableToStartChat: unableToStartChat, requestedToStartChat: requestedToStartChat);
  }

  AlertDialog _buildDialog(BuildContext context, User user){
    return AlertDialog(
      title: Text("Unable to Start Chatroom"),
      content: Text("You have deleted the chatroom with this user previously. To create a new chatroom, you have to ask the other user to create it. "),
      actions: <Widget>[
        FlatButton(
          child: Text("Cancel"),
          onPressed: (){
            Navigator.pop(context);
          }),
        FlatButton(
          child: Text("Ask to create"),
          onPressed: (){
            BlocProvider.of<CreateChatroomBloc>(context).sendRequsetToStartChat(user);
            Navigator.pop(context);
          },
        )
      ],
    );
  }

  void navigateToSelectedChatroom(SelectedChatroom chatroom) {
    NavigationHelper.navigateToInstantMessaging(
      parentContext, chatroom, true);
  }
}
