eval(onecup.import())

css "h1", ->
    font_size 20

number = 0

window.body = ->
    h1 ->
        text "Hello world"
    div ->
        button ->
            text "Press this button"
            onclick ->
                console.log "You pressed a button"
                number += 1

    div ->
        for i in [0...number]
            div ->
                margin_top 10
                text "You pressed a button"
