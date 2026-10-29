/* Web Push worker. Kept separate from Flutter's generated offline worker. */
self.addEventListener('push', (event) => {
  let data = {};
  try { data = event.data ? event.data.json() : {}; } catch (_) {}
  const title = data.title || 'DetailedToDo';
  const options = {
    body: data.body || 'Tienes un recordatorio pendiente.',
    icon: new URL('../icons/Icon-192.png', self.registration.scope).href,
    badge: new URL('../icons/Icon-192.png', self.registration.scope).href,
    tag: data.tag || undefined,
    data: { url: data.url || '../' },
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = new URL(event.notification.data?.url || '../', self.registration.scope).href;
  event.waitUntil((async () => {
    const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const client of clients) {
      if (new URL(client.url).origin === new URL(target).origin) {
        await client.navigate(target);
        return client.focus();
      }
    }
    return self.clients.openWindow(target);
  })());
});
