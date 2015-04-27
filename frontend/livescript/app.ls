require! 'angular'
require! 'angular-route'
require! 'angular-local-storage'
require! 'numeral'
require! 'fabric'

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


app.controller 'IndexController', require './controllers/index.ls'
app.controller 'AuthenticationController', require './controllers/authentication.ls'
app.controller 'TopchatImageController', require './controllers/topchat/image.ls'
app.controller 'TopchatController', require './controllers/topchat.ls'

app.directive 'topchat', require './directives/topchat.ls'