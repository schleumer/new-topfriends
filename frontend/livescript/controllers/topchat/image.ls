{ reverse, take, sort-with } = require 'prelude-ls'


module.exports = [
  '$scope', '$rootScope', '$location', 'topchatThreads',
  ($scope, $root-scope, $location, topchat-threads) !->
    threads = topchat-threads.get!

    $scope.threads = threads.items |> sort-with (.message_count) |> reverse
    $scope.me = threads.me

    $scope.back = !-> $location.path('/topchat')
]