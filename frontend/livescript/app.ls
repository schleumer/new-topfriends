require! \angular
require! \angular-route
require! \angular-local-storage
require! \numeral
require! \fabric

{ each, filter, first, sort, sort-by, reverse, last, take } = require \prelude-ls

{ sprintf } = require \sprintf-js

user-is-ok = (user) -> user is not null

app = angular.module \TopFriends <[ ngRoute LocalStorageModule ]>

window.__facebook-loaded = no;

app.config [\$routeProvider, ($route-provider) ->
  $route-provider
  .when "/authentication", {
    template-url: "/templates/authentication.html",
    controller: \AuthenticationController
  }
  .when "/topchat", {
    template-url: "/templates/topchat.html",
    controller: \TopchatController
  }
  .when "/topchat/image", {
    template-url: "/templates/topchat-image.html",
    controller: \TopchatImageController
  }
  .when "/topchat/old-image", {
    template-url: "/templates/topchat-old-image.html",
    controller: \TopchatOldImageController
  }
  .when "/", {
    template-url: "/templates/index.html",
    controller: \IndexController
  }
  .when "/privacy", {
    template-url: "/templates/privacy.html",
    controller: \PrivacyController
  }
  .when "/:test", {
    template-url: "/templates/index.html",
    controller: \IndexController
  }
  .otherwise(
    redirectTo: "/"
  )
]

app.filter \plural [\$rootScope, ($root-scope) ->
  (input, args) ->
    sprintf (if input > 1 then last args else first args),
      (if $root-scope.short-numbers then numeral input .format \"0a" else input)
]

app.service \topchatThreads ->
  items = []
  me = null
  get: -> { items, me }
  set-items: (t, max-friends = 10) -> items := t |> take (max-friends)
  set-me: (_) -> me := _

# SHEEEEEEEEEEIT
# 😸😸😸😸😸😂😂😂😂😂👏👏👏👏👏👏👌👌👌👌
parse-bool = (str) ->
  str is 'true'

app.run [
  \$rootScope \localStorageService \$location \$route \$timeout, 
  ($root-scope, local-storage, $location, $route, $timeout) ->
    if (local-storage.get \short-numbers) is null
      $root-scope.short-numbers = true
      local-storage.set \short-numbers $root-scope.short-numbers
    else
      $root-scope.short-numbers = parse-bool local-storage.get \short-numbers

    $root-scope.toggle-short-numbers = ->
      $root-scope.short-numbers = !$root-scope.short-numbers
      local-storage.set \short-numbers $root-scope.short-numbers
      # wait switcher's animation ends :D
      $timeout (-> $route.reload!), 400

    #$root-scope.facebookLoaded = window.__facebookLoaded
  
    $root-scope.user = null
    $root-scope.route-data = {}
  
    #window.__facebook-initiaded = ->
    #  $root-scope.$apply ->
    #    $root-scope.facebookLoaded = yes
  
  
    $root-scope.deleteUser = ->
      local-storage.clear-all!
      location.reload!
    
    $root-scope.$on \$routeChangeStart (event, next, current) !->
      ga 'send', 'pageview', location.href.replace("#{location.protocol}//#{location.host}", '')
      # looks like gambiarra
      # I agree (note by 'Celão)
      if next.$$route.auth
        if !next.$$route.auth $root-scope.user
          $location.path "/authentication"
]

app.controller \IndexController require "./controllers/index.ls"
app.controller \AuthenticationController require "./controllers/authentication.ls"
app.controller \TopchatImageController require "./controllers/topchat/image.ls"
app.controller \TopchatOldImageController require "./controllers/topchat/old-image.ls"
app.controller \TopchatController require "./controllers/topchat.ls"
app.controller \PrivacyController require "./controllers/privacy.ls"

app.directive \topchat require "./directives/topchat.ls"
app.directive \adsense require "./directives/adsense.ls"