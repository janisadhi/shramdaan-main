importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD6MtDj_RJpLHguvnJMtXDIvAmIkGhaxtc',
  appId: '1:541706128340:web:83bffbcaa469f43a7a6441',
  messagingSenderId: '541706128340',
  projectId: 'shram-daan-72a9b',
  authDomain: 'shram-daan-72a9b.firebaseapp.com',
  storageBucket: 'shram-daan-72a9b.firebasestorage.app',
  measurementId: 'G-YD3HXE9Z00',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const data = payload.data || {};
  const title = notification.title || data.title || 'Shramdaan';
  const options = {
    body: notification.body || data.body || 'You have a new update.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data,
  };

  self.registration.showNotification(title, options);
});
