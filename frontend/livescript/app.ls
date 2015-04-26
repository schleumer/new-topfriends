require! 'angular'
require! 'angular-route'
require! 'angular-local-storage'

app = angular.module('TopFriends', ['ngRoute', 'LocalStorageModule'])

window.__facebookLoaded = false;

app.config ['$routeProvider', ($routeProvider) ->
  $routeProvider.when('/', {
    templateUrl: '/templates/index.html',
    controller: 'IndexController'
  })
]

app.run ['$rootScope', 'localStorageService', ($rootScope, localStorageService) ->
  $rootScope.facebookLoaded = window.__facebookLoaded
  window.__facebookInitiaded = ->
    $rootScope.$apply ->
      $rootScope.facebookLoaded = true


  $rootScope.deleteUser = ->
    FB.api('/me/permissions', 'delete', (x) -> 
      localStorageService.clearAll!
      location.reload!
    )
]

app.service 'fb', 

app.controller 'IndexController', [
'$scope', '$rootScope', 'localStorageService',
($scope, $rootScope, localStorageService) ->
  $scope.loading = 1
  $scope.logged-in = false
  $scope.checking-login = true

  #if localStorage.loginInfo
  #  $scope.checking-login = false
  #  $scope.logged-in = true
  #  $scope.fetch-user!
  #else
  FB.getLoginStatus (response) ->
    $scope.$apply ->
      $scope.checking-login = false
      $scope.logged-in = response.status == \connected
      if response.status == \connected
        localStorageService.set('loginInfo', response)
        $scope.fetch-user!

  $scope.fetch-user = ->
    storage = localStorageService.get('user')
    if storage
      $rootScope.user = storage
      return
    FB.api("/me", (response) ->
      $scope.$apply ->
        localStorageService.set('user', response)
        $rootScope.user = response)

  $scope.auth = ->
    $scope.loading = 1;
    FB.login(((result) -> $scope.fetch-user!), { scope: 'publish_actions', display: 'iframe' })
]