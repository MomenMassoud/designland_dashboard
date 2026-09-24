importScripts(
  "https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js"
);

importScripts(
  "https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyD727CeckI2brOtT5ycefqAZTkOrhyiwvg",
  authDomain: "desginland-5ca7a.firebaseapp.com",
  projectId: "desginland-5ca7a",
  storageBucket: "desginland-5ca7a.firebasestorage.app",
  messagingSenderId: "848711152963",
  appId: "1:848711152963:web:4b4c831a8d7853c2a26bf6"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[firebase-messaging-sw.js] Background message:',
    payload
  );

  const notification = payload.notification || {};

  const title =
      notification.title ||
      payload.data?.title ||
      'إشعار جديد 🔔';

  const body =
      notification.body ||
      payload.data?.body ||
      '';

  self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  });
});

// Activate the newest service worker immediately.
self.addEventListener('install', () => {
  self.skipWaiting();
});

// Take control of existing pages immediately.
self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});