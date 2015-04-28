{ fabric } = require 'fabric'


module.exports = [->
  return {
    template-url: 'templates/directives/topchat.html',
    scope: {
      'threads': '='
    },
    link: (scope, element) ->
      el = element[0]
      container = el.getElementsByClassName('topchat-container')[0]
      canvas-el = el.getElementsByClassName('the-canvas')[0]

      canvas = new fabric.Canvas(canvas-el, {
        backgroundColor: 'transparent',
        selectionColor: 'blue',
        selectionLineWidth: 0,
        width: container.offsetWidth - 150,
        height: 500
      })

      for thread in scope.threads
        group = new fabric.Group([], {
          left: 100,
          top: 100,
          width: 150,
          height: 50,
          originX: 'center',
          originY: 'center'
        })

        text = new fabric.Text(thread.target.name, { 
          left: -30,
          top: -10,
          fontSize: 14,
          fontFamily: 'Roboto',
          width: 75
        })
        text.hasControls = false
        group.hasControls = false
        text.clip-to = (ctx) ->
          ctx.rect(-15, -10, 150, 50)

        group.add(text)
        canvas.add(group)
  }

]