{ each, filter, first, sort, sort-by, reverse, last } = require 'prelude-ls'

module.exports = [
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