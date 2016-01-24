{ reverse, take, sort-by } = require 'prelude-ls'


module.exports = [
  '$scope', '$rootScope', '$location', 'topchatThreads',
  ($scope, $root-scope, $location, topchat-threads) !->
    threads = topchat-threads.get!

    if not threads.items.length
      $location.path("/topchat")

    $scope.threads = threads.items |> sort-by (.message_count) |> reverse
    $scope.me = threads.me

    $scope.back = !-> $location.path('/topchat')
]