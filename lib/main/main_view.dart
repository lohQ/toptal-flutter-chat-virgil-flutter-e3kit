import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_state.dart';
import 'package:toptal_chat/e2ee/e2ee_wrapper.dart';
import 'package:toptal_chat/model/chatroon_repo.dart';
import 'package:toptal_chat/model/message_repo.dart';

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
    // dangerous without await 
    MessageRepo.init();
    ChatroomRepo.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<E2eeBloc>(
      create: (context)=>_e2eeBloc,
      child: E2eeWrapper(
        child: BlocProvider<MainBloc>(
          create: (context) => MainBloc(),
          child: MainWidget(parentContext: context)
        ),
        errorCallback: null,
        errorWidget: (E2eeState error){return mapWidgetToError(error);},
      )
    );
  }

  Widget mapWidgetToError(E2eeState e){
    return Center(
      child: Text(
        "Error initializing eThree: ${e.errorDetails} \n(Suggestion: unregister from virgil cloud and re-register again\nWarning: You will not able to access your previous chatrooms after this operation)", 
        style: TextStyle(fontSize: 16))
    );
  }

  @override
  void dispose(){
    _e2eeBloc.close();
    // dangerous without await 
    MessageRepo.dismiss();
    ChatroomRepo.instance.save();
    super.dispose();
  }

}

class MainWidget extends StatelessWidget {
  MainWidget(
    {Key key, 
    // @required this.widget, 
    @required this.parentContext}) : super(key: key);

  final BuildContext parentContext;
  List<String> chatroomIds = List<String>();

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
              BlocProvider.of<MainBloc>(context).logout();
            },
          )
        ],
      ),
      body: BlocListener(
          bloc: BlocProvider.of<MainBloc>(context),
          listener: (context, MainState state) {
            if (state.loggedIn == false) {
              navigateToLogin(context);
            }
          },
          child: BlocBuilder(
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
                chatroomIds = List.generate(state.chatrooms.length, (i)=>state.chatrooms[i].id);
                content = ListView.builder(
                  padding: EdgeInsets.all(UIConstants.SMALLER_PADDING),
                  itemBuilder: (context, index) {
                    return InkWell(
                        child: _buildItem(state.chatrooms[index]),
                        onTap: () {
                          BlocProvider.of<MainBloc>(context).retrieveChatroomForParticipant(
                              state.chatrooms[index].participants.first, this);
                        },
                        onLongPress: () {
                          bool confirmDelete = false;
                          showDialog( 
                            context: context,
                            builder: (context){
                              return AlertDialog(
                                title: Text("Delete Chatroom"),
                                content: Text("Confirm delete chatroom with ${state.chatrooms[index].participants.first.displayName}?"),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text("Cancel"), 
                                    onPressed: (){
                                      confirmDelete = false;
                                      Navigator.pop(context);}),
                                  FlatButton(
                                    child: Text("Confirm delete"), 
                                    onPressed: (){
                                      confirmDelete = true;
                                      Navigator.pop(context);}),
                                ]);
                            })
                            .whenComplete((){
                              if(confirmDelete){
                                BlocProvider.of<MainBloc>(context).deleteChatroom(
                                    state.chatrooms[index].id, state.chatrooms[index].participants.first.uid, context);}
                            });
                        },
                    );
                  },
                  itemCount: state.chatrooms.length,
                );
              }
              return _wrapContentWithFab(context, content);
            })),
      bottomNavigationBar: RaisedButton(
        child: Text("Click to Unregister on virgil cloud"),
        onPressed: () async {
          bool confirmReregister = false;
          await showDialog(context: context, child: AlertDialog(
            title: Text("Unregister on virgil cloud"),
            content: Text("Unregistering means giving up previous allocated identity on virgil cloud, and you would not be able to access previous chatrooms afterwards. "),
            actions: <Widget>[
              FlatButton(child: Text("Cancel"),
                onPressed: (){
                  confirmReregister = false;
                  Navigator.pop(context);}),
              FlatButton(child: Text("Confirm Unregister"),
                onPressed: (){
                  confirmReregister = true;
                  Navigator.pop(context);}),
            ],
          )).whenComplete((){
            if(confirmReregister){
              BlocProvider.of<E2eeBloc>(context).onUnregister(chatroomIds);
            }
          });
        },
      ),
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

  void navigateToLogin(BuildContext context) {
    NavigationHelper.navigateToLogin(context);
  }

  void navigateToChatroom(SelectedChatroom chatroom) async {
    NavigationHelper.navigateToInstantMessaging(
      parentContext, chatroom, false, addToBackStack: true);
  }
}
