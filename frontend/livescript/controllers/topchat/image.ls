{ reverse, take, sort-with } = require 'prelude-ls'


module.exports = [
  '$scope', '$rootScope', 'topchatThreads',
  ($scope, $root-scope, topchat-threads) ->
    $scope.threads = topchat-threads.get! |> sort-with (.message_count) |> reverse |> take (10)
    console.log($scope.threads)
]