require! 'angular'
require! 'angular-route'

app = angular.module('TopFriends', ['ngRoute'])

window.__facebookLoaded = false;

app.config ['$routeProvider', ($routeProvider) ->
  $routeProvider.when('/', {
    templateUrl: '/templates/index.html',
    controller: 'IndexController'
  })
]

app.run ['$rootScope', ($rootScope) ->
  $rootScope.facebookLoaded = window.__facebookLoaded
  window.__facebookInitiaded = ->
    $rootScope.$apply ->
      $rootScope.facebookLoaded = true


  $rootScope.deleteUser = ->
    FB.api('/me/permissions', 'delete', (x) -> 
      console.log(x)
      location.reload!
    )
]

app.controller 'IndexController', ['$scope', '$rootScope', ($scope, $rootScope) ->
  $scope.loading = 1
  $scope.logged-in = false
  $scope.checking-login = true

  FB.getLoginStatus (response) ->
    $scope.$apply ->
      $scope.checking-login = false
      $scope.logged-in = response.status == \connected
      $scope.fetch-user! if $scope.logged-in

  $scope.fetch-user = ->
    FB.api("/me", (response) ->
      $scope.$apply ->
        $rootScope.user = response)

  $scope.auth = ->
    $scope.loading = 1;
    FB.login(((result) -> $scope.fetch-user!), { scope: 'publish_actions', display: 'iframe' })
]