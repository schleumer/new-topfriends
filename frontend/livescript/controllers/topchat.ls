{ each, filter, first, sort, sort-by, reverse, last, map, flatten, count-by, obj-to-pairs, sort-by } = require 'prelude-ls'

module.exports = [
  '$scope', '$rootScope', '$location', '$http', 'topchatThreads',
  ($scope, $root-scope, $location, $http, topchat-threads) ->
    $scope.message = null
    $scope.deleted-threads = []
    $scope.max-friends = 15

    if not $root-scope.route-data['/topchat']
      $scope.message = 'Você precisa utilizar a extensão antes'
    else
      $scope.data = $root-scope.route-data['/topchat']
      if $scope.data.length < 3
        $scope.data = null
        $scope.fatalError = 'Você precisa no minimo ter 3 conversas :('
      else
        $scope.me = $scope.data 
          |> map (.real-participants) 
          |> flatten 
          |> count-by (.fbid)
          |> obj-to-pairs
          |> sort-by (.1)
          |> reverse
          |> first
          |> first

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
      topchat-threads.set($scope.threads, $scope.max-friends)
      $location.path('/topchat/image')

    $scope.undo-remove = (thread) ->
      $scope.threads = $scope.threads ++ thread

      $scope.deleted-threads = $scope.deleted-threads 
        |> filter (!= thread)
]