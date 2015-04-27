require! 'angular'
require! 'angular-route'
require! 'angular-local-storage'
require! 'numeral'

{ each, filter, first, sort, sort-by, reverse, last } = require 'prelude-ls'

{ sprintf } = require 'sprintf-js'

user-is-ok = (user) -> user is not null

app = angular.module('TopFriends', ['ngRoute', 'LocalStorageModule'])

window.__facebook-loaded = false;

app.config ['$routeProvider', ($route-provider) ->
  $route-provider.when('/authentication', {
    template-url: '/templates/authentication.html',
    controller: 'AuthenticationController'
  }).when('/topchat', {
    template-url: '/templates/topchat.html',
    controller: 'TopchatController',
    auth: user-is-ok
  }).when('/topchat/image', {
    template-url: '/templates/topchat-image.html',
    controller: 'TopchatImageController',
    auth: user-is-ok
  }).when('/', {
    template-url: '/templates/index.html',
    controller: 'IndexController',
    auth: user-is-ok
  }).otherwise(
    redirectTo: '/'
  )
]

app.filter 'plural', ->
  return (input, args) ->
    sprintf (if input > 1 then last(args) else first(args)), numeral(input).format("0a")

app.service 'topchatThreads', ->
  threads = []
  return
    get: -> threads
    set: (t) -> threads := t

app.run [
  '$rootScope', 'localStorageService', '$location', 
  ($root-scope, local-storage, $location) ->
    $root-scope.facebookLoaded = window.__facebookLoaded
  
    $root-scope.user = null
    $root-scope.route-data = {}
  
    window.__facebook-initiaded = ->
      $root-scope.$apply ->
        $root-scope.facebookLoaded = true
  
  
    $root-scope.deleteUser = ->
      FB.api('/me/permissions', 'delete', (x) -> 
        local-storage.clearAll!
        location.reload!
      )
    
    $root-scope.$on '$routeChangeStart', (event, next, current) !->
      $root-scope.layout-type = "hermes-panel"
      # looks like gambiarra
      if next.$$route.auth
        if !next.$$route.auth($root-scope.user)
          $location.path("/authentication")
]

app.service 'fb', 

app.controller 'DashboardController', [
  '$scope', '$rootScope',
  ($scope, $root-scope) ->
    return
]

app.controller 'IndexController', [
  '$scope', '$rootScope', '$http', '$location'
  ($scope , $root-scope, $http, $location) ->
    $scope.loading = 1
    $scope.init = ->
      $http.get('/get').then((response) ->
        if response.data and response.data.next
          # ayyyyy gambiarra                         ??????????????????
          $root-scope.route-data[response.data.next] = response.data.data
          $location.path(response.data.next)
      )
    return
]

app.controller 'AuthenticationController', [
  '$scope', '$rootScope', '$location', 'localStorageService',
  ($scope, $root-scope, $location, local-storage) ->
    $scope.loading = 1
    $scope.logged-in = false
    $scope.checking-login = true

    #if localStorage.loginInfo
    #  $scope.checking-login = false
    #  $scope.logged-in = true
    #  $scope.fetch-user!
    #else
    FB.get-login-status (response) ->
      $scope.$apply ->
        $scope.checking-login = false
        $scope.logged-in = response.status == \connected
        if response.status == \connected
          local-storage.set('loginInfo', response)
          $scope.fetch-user!

    $scope.fetch-user = ->
      storage = local-storage.get('user')
      if storage
        $root-scope.user = storage
        $location.path('/')
        return
      FB.api("/me", (response) ->
        $scope.$apply ->
          local-storage.set('user', response)
          $root-scope.user = response
          $location.path('/'))

    $scope.auth = ->
      $scope.loading = 1;
      FB.login(((result) -> $scope.fetch-user!), { scope: 'publish_actions', display: 'iframe' })
]

app.controller 'TopchatImageController', [
  '$scope', '$rootScope', 'topchatThreads',
  ($scope, $root-scope, topchat-threads) ->
    console.log(topchat-threads.get!)
]

app.controller 'TopchatController', [
  '$scope', '$rootScope', '$location', '$http', 'topchatThreads',
  ($scope, $root-scope, $location, $http, topchat-threads) ->
    $scope.message = null
    $scope.deleted-threads = []

    if not $root-scope.route-data['/topchat']
      $scope.message = 'Você precisa utilizar a extensão antes'
    else
      $scope.data = $root-scope.route-data['/topchat']
      
      $scope.threads = $scope.data 
        |> each (->
          it.target = it.real-participants 
            |> filter (.fbid.to-string! != $root-scope.user.id.to-string!) 
            |> first)


    $scope.remove = (thread) ->
      $scope.deleted-threads = $scope.deleted-threads ++ thread
      $scope.threads = $scope.threads 
        |> filter (!= thread)

    $scope.do = ->
      topchat-threads.set($scope.threads)
      $location.path('/topchat/image')

    $scope.undo-remove = (thread) ->
      $scope.threads = $scope.threads ++ thread

      $scope.deleted-threads = $scope.deleted-threads 
        |> filter (!= thread)
]