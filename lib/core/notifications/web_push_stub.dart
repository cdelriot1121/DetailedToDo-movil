import 'package:dio/dio.dart';

Future<bool> enableWebPush(Dio dio) async => false;
Future<void> disableWebPush(Dio dio) async {}
Future<void> prepareWebPush() async {}
bool get webPushEnabled => false;
