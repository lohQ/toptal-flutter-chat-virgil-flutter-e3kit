// import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/services.dart';

class E2eeState {
  final bool isLoading;
  final bool error;
  final PlatformException errorDetails;

  E2eeState._internal(this.isLoading, {this.error = false, this.errorDetails});

  factory E2eeState.initial() => E2eeState._internal(false);
  factory E2eeState.error(PlatformException errorDetails)
     => E2eeState._internal(false, error: true, errorDetails: errorDetails);
  factory E2eeState.loading(bool isLoading) => E2eeState._internal(isLoading);
}