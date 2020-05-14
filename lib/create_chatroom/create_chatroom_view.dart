import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_state.dart';

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
      child: BlocProvider(
        create: (context) => E2eeBloc(),
        child: E2eeChatroomWidget(parentContext:context)
      ));
  }

}

class E2eeChatroomWidget extends StatelessWidget{
  final BuildContext parentContext;
  E2eeChatroomWidget({this.parentContext});
  @override
  Widget build(BuildContext context){
    return BlocBuilder(
      bloc: BlocProvider.of<E2eeBloc>(context),
      builder: (context, E2eeState state){
        if(state.isLoading){
          return Center(child: CircularProgressIndicator(
            strokeWidth: 4.0,
          ));
        }else if(state.error){
          return Center(child: Text("error finding virgil card"));
        }else{
          return CreateChatroomWidget(parentContext: parentContext);
        }
      }
    );
  }
}

class CreateChatroomWidget extends StatelessWidget {
  // const CreateChatroomWidget({Key key, @required this.widget, @required this.widgetState}) : super(key: key);

  // final CreateChatroomScreen widget;
  // final _CreateChatroomState widgetState;

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
              if (state.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 4.0,
                  ),
                );
              }
              return ListView.builder(
                itemBuilder: (context, index) {
                  return InkWell(
                      child: _buildItem(state.users[index]),
                      onTap: () async {
                        BlocProvider.of<E2eeBloc>(context).onStartChat([state.users[index].uid]);
                        BlocProvider.of<CreateChatroomBloc>(context).startChat(state.users[index], this);
                      }
                  );
                },
                itemCount: state.users.length,
                padding: EdgeInsets.all(UIConstants.SMALLER_PADDING),
              ); 
            }));
  }

  Widget _buildItem(User user) {
    return UserItem(user: user);
  }

  void navigateToSelectedChatroom(SelectedChatroom chatroom) {
    NavigationHelper.navigateToInstantMessaging(parentContext, chatroom.displayName, chatroom.id);
  }
}
