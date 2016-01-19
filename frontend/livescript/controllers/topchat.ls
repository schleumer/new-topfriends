{ each, filter, first, sort, sort-by, reverse, last, map, flatten, count-by, obj-to-pairs, sort-by, unique } = require 'prelude-ls'

module.exports = [
  '$scope', '$rootScope', '$location', '$http', '$route', 'topchatThreads'
  ($scope, $root-scope, $location, $http, $route, topchat-threads) ->
    $scope.message = null
    $scope.deleted-threads = []
    $scope.max-friends = 15

    if not $root-scope.route-data['/topchat']
      #$scope.message = 'Você precisa utilizar a extensão antes'
      $location.path("/")
    else
      $scope.data = $root-scope.route-data['/topchat']
      if $scope.data.length < 3
        $scope.data = null
        $scope.fatalError = 'Você precisa no minimo ter 3 conversas :('
      else
        other-users = (
          $scope.data
          |> map (x) -> "fbid:#{x.other_user_fbid}"
        )
        
        $scope.me = ((
          $scope.data
          |> map (.participants)
          |> flatten
          |> unique
          |> filter (x) -> (other-users.index-of x) < 0
          |> first
        ) / ":").1

        console.log($scope.me)

        $scope.threads = $scope.data 
          |> each (->
            it.target = it.real-participants 
              |> filter (.fbid.to-string! != $scope.me) 
              |> first)


    $scope.remove = (thread) ->
      $scope.deleted-threads = $scope.deleted-threads ++ thread
      $scope.threads = $scope.threads 
        |> filter (!= thread)

    $scope.do = ->
      topchat-threads.set-items($scope.threads, $scope.max-friends)
      topchat-threads.set-me($scope.me)
      $location.path('/topchat/image')

    $scope.undo-remove = (thread) ->
      $scope.threads = $scope.threads ++ thread

      $scope.deleted-threads = $scope.deleted-threads 
        |> filter (!= thread)
]