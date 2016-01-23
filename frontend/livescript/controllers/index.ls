module.exports = [
  '$scope', '$rootScope', '$http', '$location'
  ($scope , $root-scope, $http, $location) ->
    $scope.loading = 1
    $scope.init = ->
      $http.get('/get').then((response) ->
        $scope.loading = 0
        if response.data and response.data.next
          # ayyyyy gambiarra                         ??????????????????
          $root-scope.route-data[response.data.next] = response.data.data
          $location.path(response.data.next)
      )
    return
]