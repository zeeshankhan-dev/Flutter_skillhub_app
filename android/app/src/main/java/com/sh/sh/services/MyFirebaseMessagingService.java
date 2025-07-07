//package com.sh.sh.services;
//
//import com.sh.sh.MainActivity;
//
//public class MyFirebaseMessagingService extends FirebaseMessagingService {
//
//    @Override
//    public void onMessageReceived(@NonNull RemoteMessage remoteMessage) {
//        super.onMessageReceived(remoteMessage);
//
//        if (remoteMessage.getNotification() != null) {
//            sendNotification(remoteMessage.getNotification().getTitle(), remoteMessage.getNotification().getBody());
//        }
//    }
//
//    private void sendNotification(String title, String messageBody) {
//        Intent intent = new Intent(this, MainActivity.class);
//        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
//        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_MUTABLE);
//
//        String channelId = "default_channel";
//        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
//        NotificationCompat.Builder notificationBuilder =
//                new NotificationCompat.Builder(this, channelId)
//                        .setSmallIcon(R.drawable.ic_launcher)
//                        .setContentTitle(title)
//                        .setContentText(messageBody)
//                        .setAutoCancel(true)
//                        .setSound(defaultSoundUri)
//                        .setContentIntent(pendingIntent);
//
//        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
//
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            NotificationChannel channel = new NotificationChannel(channelId, "Default Channel", NotificationManager.IMPORTANCE_HIGH);
//            notificationManager.createNotificationChannel(channel);
//        }
//
//        notificationManager.notify(0, notificationBuilder.build());
//    }
//}
