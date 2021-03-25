import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

/// Message route arguments.
class MessageArguments {
  /// The RemoteMessage
  final RemoteMessage message;

  /// Whether this message caused the application to open.
  final bool openedApplication;

  // ignore: public_member_api_docs
  MessageArguments(this.message, this.openedApplication)
      : assert(message != null);
}

/// Displays information about a [RemoteMessage].
class MessageView extends StatelessWidget {
  /// A single data row.
  Widget row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        Text('$title: '),
        Text(value ?? 'N/A'),
      ]),
    );
  }

  List<Widget> dataList(context, Map<String, dynamic> data) {
    List<Widget> list = [];
    data.forEach((key, value) {
      list.add(Card(
        child: Container(
          padding: EdgeInsets.all(6.0),
          child: Column(
            children: [Text(key), Divider(), Text(value)],
          ),
        ),
      ));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final MessageArguments args = ModalRoute.of(context).settings.arguments;
    RemoteMessage message = args.message;
    RemoteNotification notification = message.notification;

    return Scaffold(
      appBar: AppBar(
        title: Text(message.notification.title),
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(10.0),
            child: Container(
              padding: EdgeInsets.all(5.0),
              child: Column(
                children: [
                  row('Title', notification.title),
                  row('Body', notification.body),
                  row('Sent Time', message.sentTime?.toString()),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            padding: EdgeInsets.all(5.0),
            child: Column(
              children: dataList(context, message.data),
            ),
          ),
          message.data.containsKey("url")
              ? OutlinedButton(
                  onPressed: () async {
                    if (await canLaunch(message.data["url"])) {
                      await launch(message.data["url"]);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Invalid Url.")));
                    }
                  },
                  child: Text("open url"),
                )
              : null
        ],
      ),
    );
  }
}
