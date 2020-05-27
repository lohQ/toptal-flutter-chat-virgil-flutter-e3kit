import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_state.dart';

class E2eeWrapper extends StatelessWidget{
  final Widget child;
  final Function errorCallback;
  final Function errorWidget;
  E2eeWrapper({this.child, this.errorCallback, this.errorWidget});

  @override
  Widget build(BuildContext context) {
    if(errorCallback != null){
      return blocListenerWrapper(context, e2eeBlocBuilder(context));
    }else{
      return e2eeBlocBuilder(context);
    } 
  }

  Widget blocListenerWrapper(BuildContext context, Widget child){
    return BlocListener(
      bloc: BlocProvider.of<E2eeBloc>(context),
      listener: (context, E2eeState state){
        errorCallback(state);
      },
      child: child
    );
  }

  Widget e2eeBlocBuilder(BuildContext context){
    return BlocBuilder(
      bloc: BlocProvider.of<E2eeBloc>(context),
      builder: (context, E2eeState state){
        if(state.isLoading) {
          return Center(child: CircularProgressIndicator());
        }else if (state.error) {
          if(errorWidget != null){
            return errorWidget(state);
          }else{
            return Center(child: Text(state.errorDetails.message, style: TextStyle(fontSize: 16)));
          }
        }else { 
          return child;
        }},
    );
  }

}
