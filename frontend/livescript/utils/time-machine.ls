#TODO: TODO

export class TimeMachine
  (@canvas) ->
    @state = []
    @index = -1
    @on-top = no

    mod = (action, e) ~~>
      @index++

      object = e.target
      object.saveState!

      @state[@index] = {
        state: JSON.stringify object.originalState.{top, left, id}
        object: object
      }

      
      @on-top = yes

    @canvas.on 'object:added', mod 'added'
    @canvas.on 'object:modified', mod 'modified'

  clear: ->
    @state = []
    @index = -1

  undo: ->
    return if @index < 0
    
    if @on-top and @index >= 1
      @index--

    current = @state[@index]

    old-state = JSON.parse current.state

    current.object.setOptions old-state

    current.object.setCoords!

    @canvas.renderAll!