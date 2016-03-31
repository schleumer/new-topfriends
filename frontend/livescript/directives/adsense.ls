# EVIL, SUPA EVIL

module.exports = ['$location', '$route', '$rootScope', '$http', '$timeout'
($location, $route, $root-scope, $http, $timeout) ->
  return {
    template-url: '/templates/directives/omg.html'
    restrict: 'E'
    scope: {
      client: '@',
      slot: '@'
    }
    replace: true
    link: (scope, elem) ->
      s = document.createElement('script')
      s.async = 1
      s.src = '//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'
      document.body.appendChild(s);
      (window.adsbygoogle = window.adsbygoogle || []).push({});
  }
]
