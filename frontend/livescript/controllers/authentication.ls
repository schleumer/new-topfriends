{ each, filter, first, sort, sort-by, reverse, last } = require 'prelude-ls'

module.exports = [
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