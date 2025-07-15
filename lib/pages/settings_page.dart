import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Dans le build ou le widget approprié :
FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
    .collection('familles')
    .doc(familleId)
    .collection('notificationsActives')
    .doc(userId)
    .get(),
  builder: (context, snapshot) {
    bool notificationsActives = snapshot.data?.get('active') ?? false;
    return SwitchListTile(
      title: Text('Notifications pour cette famille'),
      value: notificationsActives,
      onChanged: (val) async {
        String? token = await FirebaseMessaging.instance.getToken();
        await FirebaseFirestore.instance
          .collection('familles')
          .doc(familleId)
          .collection('notificationsActives')
          .doc(userId)
          .set({'active': val, 'fcmToken': token});
      },
    );
  },
), 