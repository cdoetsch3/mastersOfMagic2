// Kill-switch service worker.
//
// Early builds shipped Flutter's offline-first service worker, which cached
// the app shell so aggressively that new deploys never reached returning
// players. Builds now use --pwa-strategy=none (no service worker), and this
// file replaces the old worker at its registered URL: when a stale client
// checks for updates it installs this, which purges all caches, unregisters
// itself, and reloads the page onto the fresh build.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((key) => caches.delete(key)));
    await self.registration.unregister();
    const clients = await self.clients.matchAll({ type: 'window' });
    clients.forEach((client) => client.navigate(client.url));
  })());
});
