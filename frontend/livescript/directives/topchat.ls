{ fabric } = require 'fabric'


module.exports = [->
  return {

    link: (scope, element) ->
      canvas = new fabric.Canvas(element[0], {
        backgroundColor: 'rgb(100,100,200)',
        selectionColor: 'blue',
        selectionLineWidth: 2
      })
  }

]