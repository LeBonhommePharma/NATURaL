(function () {
  'use strict';
  var supported = ['en','fr','es','ja','zh','ko','ru','de','ar','it','pt'];
  function match(tags) {
    for (var tag of tags) {
      var code = String(tag).toLowerCase().replace(/_/g, '-').split('-')[0];
      if (supported.indexOf(code) !== -1) return code;
    }
    return 'en';
  }
  var current = document.documentElement.lang;
  var section = document.documentElement.dataset.section;
  function route(code) { return '/NATURaL/' + (code === 'en' ? '' : code + '/') + (section ? section + '/' : ''); }
  var query = new URLSearchParams(location.search).get('lang');
  var stored;
  try { stored = localStorage.getItem('natural-language'); } catch (_) {}
  var desired = query ? match([query]) : stored && supported.includes(stored) ? stored : match(navigator.languages || [navigator.language]);
  // Explicit localized paths are stable deep links. Root paths negotiate the OS language.
  if ((query || current === 'en') && desired !== current) {
    location.replace(route(desired) + (query ? '?lang=' + desired : '') + location.hash);
    return;
  }
  if (query) {
    document.querySelectorAll('a[href^="/NATURaL/"]').forEach(function (link) {
      var target = new URL(link.href);
      target.searchParams.set('lang', current);
      link.href = target.href;
    });
  }
  document.getElementById('language').addEventListener('change', function () {
    var code = match([this.value]);
    try { localStorage.setItem('natural-language', code); } catch (_) {}
    // The query preserves an explicit English choice even when storage is unavailable.
    location.assign(route(code) + '?lang=' + code + location.hash);
  });
})();
