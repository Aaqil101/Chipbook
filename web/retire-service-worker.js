// Kill switch for the service worker the app used before it moved to /app/.
//
// That worker was registered at scope "/", so browsers that installed it can
// still serve the old cached shell for /app/. The deploy copies this file to
// the site root as flutter_service_worker.js; the browser's update check fetches
// it, it unregisters itself, clears the old caches, and reloads open pages once.

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    (async function () {
      try {
        await self.registration.unregister();
      } catch (error) {
        // Nothing to do: the registration is already gone.
      }

      try {
        var keys = await caches.keys();
        await Promise.all(
          keys.map(function (key) {
            return caches.delete(key);
          }),
        );
      } catch (error) {
        // Cache storage may be unavailable; the unregister is what matters.
      }

      var clients = await self.clients.matchAll({ type: 'window' });
      clients.forEach(function (client) {
        client.navigate(client.url);
      });
    })(),
  );
});
