import 'dart:html' as html;

Future<void> showBrowserNotification({
  required String title,
  required String body,
}) async {
  if (!html.Notification.supported) {
    return;
  }

  if (html.Notification.permission != 'granted') {
    return;
  }

  html.Notification(
    title,
    body: body,
    icon: '/icons/Icon-192.png',
  );
}
