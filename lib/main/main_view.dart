import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_state.dart';
import 'package:toptal_chat/model/chat_repo.dart';
import 'package:toptal_chat/model/user_repo.dart';

import 'main_bloc.dart';
import 'main_state.dart';
import 'main_user_item.dart';
import '../util/constants.dart';
import '../navigation_helper.dart';
import '../model/chatroom.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MainState();
}

class _MainState extends State<MainScreen> {

  E2eeBloc _e2eeBloc;

  @override
  void initState(){
    super.initState();
    _e2eeBloc = E2eeBloc();
    _e2eeBloc.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<E2eeBloc>(
      create: (context)=>_e2eeBloc,
      child: E2eeWidget(context)
    );    
  }

  @override
  void dispose(){
    _e2eeBloc.close();
    super.dispose();
  }

}

class E2eeWidget extends StatelessWidget{
  final BuildContext parentContext;
  E2eeWidget(this.parentContext);
  @override
  Widget build(BuildContext context){
    return BlocBuilder(
      bloc: BlocProvider.of<E2eeBloc>(context),
      builder: (context, E2eeState state){
        if(state.isLoading){
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 4.0,
            )
          );
        }else if(state.error){
          return Center(
            child: Text("error initializing eThree")
          );
        }else{
          return BlocProvider<MainBloc>(
            create: (context) => MainBloc(),
            child: MainWidget(parentContext: parentContext, contextWithE2ee: context,)
          );
        }
      },
    );
  }
}

class MainWidget extends StatelessWidget {
  final BuildContext contextWithE2ee;
  const MainWidget(
    {Key key, 
    // @required this.widget, 
    @required this.parentContext, 
    this.contextWithE2ee}) : super(key: key);

  // final MainScreen widget;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Toptal Chat'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.lock_open),
            onPressed: () {
              BlocProvider.of<E2eeBloc>(context).onLogout();
              BlocProvider.of<MainBloc>(context).logout(this);
            },
          )
        ],
      ),
      body: BlocBuilder(
          bloc: BlocProvider.of<MainBloc>(context),
          builder: (context, MainState state) {
            Widget content;
            if (state.isLoading) {
              content = Center(
                child: CircularProgressIndicator(
                  strokeWidth: 4.0,
                ),
              );
            } else if (state.chatrooms.isEmpty) {
              content = Center(
                child: Text(
                  "Looks like you don't have any active chatrooms\nLet's start one right now!",
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              content = ListView.builder(
                padding: EdgeInsets.all(UIConstants.SMALLER_PADDING),
                itemBuilder: (context, index) {
                  return InkWell(
                      child: _buildItem(state.chatrooms[index]),
                      onTap: () {
                        BlocProvider.of<MainBloc>(context).retrieveChatroomForParticipant(
                            state.chatrooms[index].participants.first, this);
                      });
                },
                itemCount: state.chatrooms.length,
              );
            }
            return _wrapContentWithFab(context, content);
          }),
    );
  }

  Widget _wrapContentWithFab(BuildContext context, Widget content) {
    return Stack(
      children: <Widget>[
        content,
        Container(
          alignment: Alignment.bottomRight,
          padding: EdgeInsets.all(UIConstants.STANDARD_PADDING),
          child: FloatingActionButton(
              onPressed: _clickAddChat,
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: Colors.blueAccent,
              elevation: UIConstants.STANDARD_ELEVATION),
        )
      ],
    );
  }

  void _clickAddChat() {
    NavigationHelper.navigateToAddChat(parentContext, addToBackStack: true);
  }

  UserItem _buildItem(Chatroom chatroom) {
    return UserItem(user: chatroom.participants.first);
  }

  void navigateToLogin() {
    NavigationHelper.navigateToLogin(parentContext);
  }

  void navigateToChatroom(SelectedChatroom chatroom) async {
    final curUser = await UserRepo.getInstance().getCurrentUser();
    final users = await ChatRepo.getInstance().getUsersFromChatroom(chatroom.id);
    users.remove(curUser.uid);
    await BlocProvider.of<E2eeBloc>(contextWithE2ee).onStartChat([users.first]); // users only has one element
    NavigationHelper.navigateToInstantMessaging(parentContext, chatroom.displayName, chatroom.id, addToBackStack: true);
  }
}
