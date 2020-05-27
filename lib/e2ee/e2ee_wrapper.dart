import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_state.dart';

class E2eeWrapper extends StatelessWidget{
  final Widget child;
  final Function errorCallback;
  E2eeWrapper(this.child, this.errorCallback);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: BlocProvider.of<E2eeBloc>(context),
      builder: (context, E2eeState state){
        if(state.isLoading) {
          return Center(child: CircularProgressIndicator());
        }else if (state.error) {
          errorCallback(state.errorDetails);
          return Center(child: Text(state.errorDetails.message));
          // return child;
        }else { 
          return child;
        }
      },
    );
  }
}
