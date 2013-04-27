$ ->
   # $("pre").click ->
        console.log "edit", this, $("pre")
        for pre in $("pre")
            setup(pre)

setup = (pre) ->
    code = $(pre).find("code")
    text = code.text()
    $textarea = $("<textarea>#{text}</textarea>")
    $textarea2 = $("<textarea>....</textarea>")

    $(pre).replaceWith($textarea)

    $textarea.after($textarea2)

    console.log $textarea.get(0)

    cm1 = CodeMirror.fromTextArea $textarea.get(0),
        lineNumbers: true,
        viewportMargin: Infinity
        lineWrapping: true

    cm2 = CodeMirror.fromTextArea $textarea2.get(0),
        lineNumbers: true,
        viewportMargin: Infinity
        readOnly: true,
        lineWrapping: true
        mode: "html"

    recompile = ->
        coffeescript = cm1.getValue()

        HEADER = """
{html, body, ol, render, div, span, table, thead, tbody, tr, td, th, text, textarea, button, hr, iframe,
 raw, a, br, b, img, label, form, input, ul, li, h1, h2, h4, select, option, p} = window.onecup

"""

        FOOTER = """
window.output = window.onecup.render()
"""

        javascript = CoffeeScript.compile(HEADER + coffeescript + FOOTER)

        console.log "change", javascript


        eval(javascript)

        console.log "html", window.output


        cm2.setValue(window.output)


    recompile()

    cm1.on "change", ->
        recompile()

