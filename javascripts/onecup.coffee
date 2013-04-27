# Private HTML element reference.
elements =
  # Valid HTML 5 elements requiring a closing tag.
  # Note: the `var` element is out for obvious reasons, please use `tag 'var'`.
  regular: "a abbr address article aside audio b bdi bdo blockquote body button
 canvas caption cite code colgroup datalist dd del details dfn div dl dt em
 fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup
 html i iframe ins kbd label legend li map mark menu meter nav noscript object
 ol optgroup option output p pre progress q rp rt ruby s samp script section
 select small span strong sub summary sup table tbody td textarea tfoot
 th thead time title tr u ul video"

  # Valid self-closing HTML 5 elements.
  void: "area base br col command embed hr img input keygen link meta param
 source track wbr"

  obsolete: "applet acronym bgsound dir frameset noframes isindex listing
 nextid noembed plaintext rb strike xmp big blink center font marquee multicol
 nobr spacer tt"

  obsolete_void: "basefont frame"

# saying
#    input checked: true makes <input checked=checked>
#    input checked: false makes <input>
boolean_attrs = {'selected', 'disabled', 'checked', 'readonly', 'multiple'}


# Create a unique list of element names merging the desired groups.
merge_elements = (args...) ->
    result = []
    for a in args
        for element in elements[a].split(/\W+/)
            result.push element unless element in result
    return result

# Escapes HTML if its potentially harmfull.
escape = (text) ->
    text.toString()
     .replace(/\&/g, "&amp;")
     .replace(/\>/g, "&gt;")
     .replace(/\</g, "&lt;")
     .replace(/\"/g, "&quot;")

class OneCup
    constructor: ->
        # use to add expaed text
        @text = (s) => @_add escape("" + s)
        # use to add raw unescaped text
        @raw = (s) => @_add s

        # add all the normal tags
        for tagName in merge_elements 'regular', 'obsolete'
            do (tagName) =>
                @[tagName] = (args...) => @._tag tagName, args

        # add all the self closing tags
        for tagName in merge_elements 'void', 'obsolete_void'
            do (tagName) =>
                @[tagName] = (args...) => @._closing_tag tagName, args

        # buffer
        @htmlOut = []

    # use this to dump current HTML into a string
    render: =>
        htmlOut = @htmlOut.join("")
        @htmlOut = []
        return htmlOut

    # clear the current html
    reset: (html = '') -> @htmlOut = [html]

    _add: (s) ->
        if s then @htmlOut.push s

    # convert an object of css properties into a string
    # e.g. {'background-color': 'white'} => 'background-color: white'
    _obj_to_css: (obj) ->
        ("#{key}: #{value}" for own key, value of obj).join(';')

    # write an attribute object into the html buffer
    _attrstr: (obj) ->
        attrstr = []
        for name, val of obj
            if name == 'style' and typeof val == 'object'
                val_str = @_obj_to_css(val)
            else if boolean_attrs[name]
                if val
                    val_str = name
                else
                    continue
            else
                val_str = "" + val
            val_esc = val_str.replace(/\"/g,'&quot;')
            attrstr.push " #{name}=\"#{val_esc}\" "
        attrstr.join("")

    _idclass: (args) ->
        inter_symbol = []
        if typeof(args[0]) == 'string' and args[0].length > 1
            classes = []

            if "#" != args[0][0] && "." != args[0][0]
                return ""

            for i in args.shift().split '.'
                if i.length == 0
                    continue
                if "#" == i[0]
                    id = i.slice 1
                else
                    classes.push i
            if id
                inter_symbol.push " id=\"#{id}\" "
            if classes.length > 0
                inter_symbol.push " class=\"#{classes.join(' ')}\" "
        return inter_symbol.join("")

    # render a normal tag
    _tag: (tagName, args) ->
        attrstr = []
        innertext = []
        func = null
        inter_symbol = @_idclass(args)

        for arg in args
            switch typeof arg
                when 'string'
                    if "#" != arg[0] && "." != arg[0] && "" != arg
                       innertext.push escape(arg)
                when 'number'
                    @_add ""+arg
                when 'function'
                    func = arg
                when 'object'
                    attrstr.push @_attrstr arg
                else
                    throw 'OneCup: invalid argument for tag ' + tagName + inter_symbol + ': ' + arg

        @htmlOut.push "<#{tagName}"
        if inter_symbol
            @htmlOut.push inter_symbol
        if attrstr.length != 0
            @htmlOut.push attrstr.join("")
        @htmlOut.push ">"
        @_add innertext.join("")

        if func and tagName isnt 'textarea'
            func?()

        @htmlOut.push "</#{tagName}>"

    # render a self closing tag
    _closing_tag: (tagName, args) ->
        attrstr = []
        inter_symbol = @_idclass(args)
        for arg in args
            if typeof arg is 'object'
                attrstr.push @_attrstr arg
            else
                throw 'OneCup: invalid argument for tag ' + tagName + inter_symbol + ': ' + arg

        @htmlOut.push "<#{tagName}"
        if inter_symbol
            @htmlOut.push inter_symbol
        if attrstr.length != 0
            @htmlOut.push attrstr.join("")
        @htmlOut.push "/>"

# attach one cup to window so that we can use it in other modules
window.onecup = new OneCup()

