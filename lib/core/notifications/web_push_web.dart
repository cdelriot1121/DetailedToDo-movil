import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../app/config/app_config.dart';
import 'package:web/web.dart' as web;

const _pushEnabledKey = 'detailedtodo.webpush.enabled';
web.ServiceWorkerRegistration? _preparedRegistration;
web.PushSubscription? _preparedSubscription;

bool get webPushEnabled {
  try {
    return web.window.localStorage.getItem(_pushEnabledKey) == 'true';
  } catch (_) {
    return false;
  }
}

Future<void> prepareWebPush() async {
  try {
    if (!web.window.isSecureContext) return;
    final base = Uri.parse(web.document.baseURI);
    _preparedRegistration = await web.window.navigator.serviceWorker
        .register(
          base.resolve('push/push-sw.js').toString().toJS,
          web.RegistrationOptions(scope: base.resolve('push/').toString()),
        )
        .toDart;
    _preparedSubscription = await _preparedRegistration!.pushManager
        .getSubscription()
        .toDart;
  } catch (_) {}
}

Future<bool> enableWebPush(Dio dio) async {
  try {
    if (!web.window.isSecureContext) return false;
    if (web.Notification.permission != 'granted') return false;
    final key = AppConfig.webPushVapidPublicKey;
    if (key.isEmpty) return false;
    final base = Uri.parse(web.document.baseURI);
    final scope = base.resolve('push/').toString();
    final registration =
        _preparedRegistration ??
        await web.window.navigator.serviceWorker.getRegistration(scope).toDart;
    if (registration == null) return false;
    final existing =
        _preparedSubscription ??
        await registration.pushManager.getSubscription().toDart;
    final subscription =
        existing ??
        await registration.pushManager
            .subscribe(
              web.PushSubscriptionOptionsInit(
                userVisibleOnly: true,
                applicationServerKey: _decodeKey(key).toJS,
              ),
            )
            .toDart;
    _preparedRegistration = registration;
    _preparedSubscription = subscription;
    final json = subscription.toJSON().dartify() as Map;
    final keys = json['keys'] as Map?;
    if (json['endpoint'] == null ||
        keys?['p256dh'] == null ||
        keys?['auth'] == null) {
      return false;
    }
    await dio.post(
      'push/subscriptions',
      data: {
        'endpoint': json['endpoint'],
        'p256dh': keys!['p256dh'],
        'auth': keys['auth'],
      },
    );
    web.window.localStorage.setItem(_pushEnabledKey, 'true');
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> disableWebPush(Dio dio) async {
  try {
    web.window.localStorage.removeItem(_pushEnabledKey);
    _preparedSubscription = null;
    final base = Uri.parse(web.document.baseURI);
    final registration = await web.window.navigator.serviceWorker
        .getRegistration(base.resolve('push/').toString())
        .toDart;
    if (registration == null) return;
    final subscription = await registration.pushManager
        .getSubscription()
        .toDart;
    if (subscription == null) return;
    final json = subscription.toJSON().dartify() as Map;
    final endpoint = json['endpoint'] as String?;
    if (endpoint != null) {
      await dio.delete(
        'push/subscriptions',
        queryParameters: {'endpoint': endpoint},
      );
    }
    await subscription.unsubscribe().toDart;
  } catch (_) {}
}

Uint8List _decodeKey(String value) {
  final normalized = value.replaceAll('-', '+').replaceAll('_', '/');
  return Uint8List.fromList(
    base64.decode(normalized.padRight((normalized.length + 3) ~/ 4 * 4, '=')),
  );
}
