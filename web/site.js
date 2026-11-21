// Chipbook site behaviour. Kept small: no framework, no build step.
(function () {
  // Google sign-in returns to the Site URL, which is this landing page. Forward
  // the result to the app so a session is never stranded on the marketing page.
  var search = window.location.search || '';
  var hash = window.location.hash || '';
  var isAuth =
    /[?&](code|error|error_code|error_description)=/.test(search) ||
    /(access_token|refresh_token|error_description|code)=/.test(hash);

  if (isAuth) {
    window.location.replace('/app/' + search + hash);
    return;
  }

  // Before the split, Flutter registered a service worker at scope "/". It can
  // still serve the old cached shell for /app/, so retire any root-scoped
  // worker. The app's own worker lives under /app/ and must be left alone.
  if ('serviceWorker' in navigator) {
    var rootScope = new URL('/', window.location.origin).href;
    navigator.serviceWorker
      .getRegistrations()
      .then(function (registrations) {
        var stale = registrations.filter(function (registration) {
          return registration.scope === rootScope;
        });

        if (stale.length === 0) {
          return;
        }

        stale.forEach(function (registration) {
          registration.unregister();
        });

        // Unregistering leaves the worker's caches behind, and they still hold
        // the old shell. Drop them so nothing can serve it again.
        if (window.caches) {
          caches
            .keys()
            .then(function (keys) {
              keys.forEach(function (key) {
                caches.delete(key);
              });
            })
            .catch(function () {});
        }
      })
      .catch(function () {});
  }

  var header = document.getElementById('header');
  if (header) {
    var onScroll = function () {
      header.classList.toggle('scrolled', window.scrollY > 8);
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }
})();
