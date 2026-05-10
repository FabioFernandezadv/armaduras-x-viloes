/* Service Worker — Armaduras X Vilões PWA
   Estratégia: Cache-First com network fallback. Após primeira visita,
   o jogo funciona 100% offline. */

const CACHE = 'axv-v3';

// Recursos críticos para pré-cache (carregados ao instalar)
const CORE_ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './assets/menu-bg.png',
  './assets/icon-192.png',
  './assets/icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(CORE_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  // Limpa caches antigos quando esta versão activa
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  // Só processa GET (POST não cacheable)
  if (event.request.method !== 'GET') return;
  // Só same-origin (evita interferir com fontes externas)
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) {
        // Cache-first: serve do cache, mas re-popula em background
        fetch(event.request).then((res) => {
          if (res && res.status === 200) {
            caches.open(CACHE).then((c) => c.put(event.request, res));
          }
        }).catch(() => {});
        return cached;
      }
      // Não está em cache: vai à network e guarda
      return fetch(event.request).then((res) => {
        if (res && res.status === 200) {
          const clone = res.clone();
          caches.open(CACHE).then((c) => c.put(event.request, clone));
        }
        return res;
      }).catch(() => {
        // Sem network e sem cache: devolve fallback se for HTML
        if (event.request.headers.get('accept')?.includes('text/html')) {
          return caches.match('./index.html');
        }
      });
    })
  );
});
