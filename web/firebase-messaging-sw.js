importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "1:848711152963:web:4b4c831a8d7853c2a26bf6",
  authDomain: "desginland-5ca7a.firebaseapp.com",
  projectId: "desginland-5ca7a",
  storageBucket: "desginland-5ca7a.appspot.com",
  messagingSenderId: "848711152963",
  appId: "1:848711152963:web:4b4c831a8d7853c2a26bf6"
});

const messaging = firebase.messaging();

// استقبال الإشعارات في الخلفية للويب
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});