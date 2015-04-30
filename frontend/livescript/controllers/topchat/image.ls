{ reverse, take, sort-with } = require 'prelude-ls'


module.exports = [
  '$scope', '$rootScope', '$location', 'topchatThreads',
  ($scope, $root-scope, $location, topchat-threads) !->
    $scope.threads = topchat-threads.get! |> sort-with (.message_count) |> reverse
    $scope.back = !-> $location.path('/topchat')
]