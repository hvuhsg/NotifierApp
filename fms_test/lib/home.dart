import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'message.dart';
import 'message_list.dart';
import 'permissions.dart';
import 'token_monitor.dart';

class Application extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final AndroidNotificationChannel channel;
  Application(this.flutterLocalNotificationsPlugin, this.channel);

  @override
  State<StatefulWidget> createState() => _Application();
}

class _Application extends State<Application> {
  //String _token;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  bool _enableNotifications = true;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      if (message != null) {
        Navigator.pushNamed(context, '/message',
            arguments: MessageArguments(message, true));
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;

      if (notification != null &&
          android != null &&
          this._enableNotifications) {
        widget.flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                widget.channel.id,
                widget.channel.name,
                widget.channel.description,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: '@mipmap/launcher_icon',
              ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      Navigator.pushNamed(context, '/message',
          arguments: MessageArguments(message, true));
    });
  }

  bool changeNotificationStatus(bool status) {
    setState(() {
      _enableNotifications = status;
      if (status == false) {
        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: false, badge: false, sound: false);
        FirebaseMessaging.instance.setAutoInitEnabled(false);
      } else {
        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
        FirebaseMessaging.instance.setAutoInitEnabled(true);
      }
    });
    return _enableNotifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QwhaleNotifier'),
        actions: <Widget>[
          Switch(
              value: _enableNotifications,
              onChanged: (bool value) {
                changeNotificationStatus(value);
                if (value == true) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Notifications enabled"),
                    duration: Duration(milliseconds: 500),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Notifications disabled"),
                    duration: Duration(milliseconds: 500),
                  ));
                }
              })
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          Platform.isAndroid == false
              ? MetaCard('Permissions', Permissions())
              : SizedBox(),
          MetaCard('Notifications Token', TokenMonitor((token) {
            //_token = token;
            return token == null
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      Text(token, style: const TextStyle(fontSize: 14)),
                      IconButton(
                        icon: Icon(Icons.copy_outlined),
                        onPressed: () {
                          Clipboard.setData(new ClipboardData(text: token));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Copyed to clipboard"),
                            duration: Duration(seconds: 1),
                          ));
                        },
                      ),
                    ],
                  );
          })),
          MetaCard('Message Stream', MessageList()),
        ]),
      ),
    );
  }
}

/// UI Widget for displaying metadata.
class MetaCard extends StatelessWidget {
  final String _title;
  final Widget _children;

  // ignore: public_member_api_docs
  MetaCard(this._title, this._children);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
        child: Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child:
                          Text(_title, style: const TextStyle(fontSize: 18))),
                  _children,
                ]))));
  }
}
