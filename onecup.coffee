# onecup.coffee
# the most crazy reactive html css framework out there

window.onecup = {}

HTML_TAGS = """
    a
    audio
    b
    blockquote
    br
    button
    canvas
    code
    div
    em
    embed
    form
    h1
    h2
    h3
    h4
    h5
    h6
    header
    hr
    i
    iframe
    img
    input
    label
    li
    object
    ol
    option
    p
    pre
    script
    select
    small
    source
    span
    strong
    sub
    sup
    table
    tbody
    td
    textarea
    tfoot
    th
    thead
    time
    tr
    u
    ul
    video
    """.split(/\s/)

CSS_PROPS = """
    align_items
    animation
    animation_direction
    background
    background_attachment
    background_color
    background_image
    background_size
    background_position
    background_position_x
    background_position_y
    background_repeat
    border
    border_bottom
    border_bottom_color
    border_bottom_style
    border_bottom_width
    border_collapse
    border_color
    border_image
    border_left
    border_left_color
    border_left_style
    border_left_width
    border_radius
    border_right
    border_right_color
    border_right_style
    border_right_width
    border_spacing
    border_style
    border_top
    border_top_color
    border_top_style
    border_top_width
    border_width
    bottom
    box_shadow
    clear
    clip
    color
    cursor
    direction
    display
    filter
    flex
    flex_direction
    flex_wrap
    float
    font
    font_family
    font_size
    font_size_adjust
    font_stretch
    font_style
    font_variant
    font_weight
    height
    justify_content
    left
    line_break
    line_height
    list_style
    list_style_image
    list_style_position
    list_style_type
    margin
    margin_bottom
    margin_left
    margin_right
    margin_top
    marker_offset
    max_height
    max_width
    min_height
    min_width
    opacity
    outline
    overflow
    overflow_x
    overflow_y
    padding
    padding_bottom
    padding_left
    padding_right
    padding_top
    pointer_events
    position
    resize
    right
    table_layout
    text_align
    text_align_last
    text_decoration
    text_indent
    text_justify
    text_overflow
    text_shadow
    text_transform
    text_autospace
    text_kashida_space
    text_underline_position
    top
    transform
    transition
    user_select
    vertical_align
    visibility
    white_space
    width
    word_break
    word_spacing
    word_wrap
    z_index
    zoom
    """.split(/\s/)

JS_EVENT = """
    onblur
    onchange
    oncontextmenu
    onfocus
    oninput
    onselect
    onsubmit
    onkeydown
    onkeypress
    onkeyup
    onclick
    ondblclick
    ondrag
    ondragend
    ondragenter
    ondragleave
    ondragover
    ondragstart
    ondrop
    onmouseenter
    onmousedown
    onmousemove
    onmouseout
    onmouseover
    onmouseup
    onload
    onscroll
    onwheel
    """.split(/\s/)

IE = navigator.msMaxTouchPoints
#IE
if not Array.isArray?
    Array.isArray = (obj) -> Object::toString.call(obj) == '[object Array]';

# define this for new page
onecup.new_page = ->

# needed for html rendering
current_tag = null
tag_chain = []
css_chain = ""
css_rule_chain = []
current_rule = null
levels = []
tags = []
old_oml = null
full_refresh = true
dont_refresh_flag = false


# ------------------------------- render system -----------------------------
# render the tags

render = ->
    finished_tags = tags
    tags = []
    return finished_tags

# check if first arg is a selector string like "#id.class.class"
check_selectors = (args) ->
    first_arg = args[0]
    if typeof(first_arg) == 'string'
        if "#" == first_arg[0] or "." == first_arg[0]
            return parse_selectors(args.shift())
    return {}

# parses selectors like "#id.class.class"
parse_selectors = (arg) ->
    attributes = {}
    classes = []
    for i in arg.split '.'
        if i.length == 0
            continue
        else if "#" == i[0]
            if attributes.id
                throw Error("mulitple ids #{arg}")
            attributes.id = i[1...]
        else
            classes.push i
    if classes.length > 0
        attributes.class = classes.join(" ")
    return attributes

make_selectors = (attrs) ->
    selector = ""
    if attrs.id
        selector += "#"+attrs.id
    if attrs.class
        selector += "."+attrs.class.split(" ").join(".")
    return selector

# css definer {left: 34} -> to "left: 34px;"
css_def = (css) ->
    if typeof(css) != 'object'
        return css
    lines = []
    for k, v of css
        if typeof(v) == 'number'
            v = v + "px"
        lines.push "#{k}:#{v}"
    return lines.join(";")


# create a tag function, pass tag names
make_tag = (tag_name) ->
    (args...) ->

        # see if first arg is "#id.class.class" syntax
        attributes = check_selectors(args)

        # see if the last argument is a function to render rest of the dom
        if typeof(args[args.length-1]) == 'function'
            inner_fn = args.pop()

        # turn the rest of the args into tag attributes
        for arg in args
            if typeof(arg) == 'object'
                for k, v of arg
                    if typeof(v) == 'function'
                        newv = onecup.event_fn(v)
                    else if typeof(v) == 'undefined'
                        continue
                    else if k == "style"
                        newv = v # don't do any thing yet
                    else
                        newv = v
                    attributes[k] = newv
            else
                throw Error("invalid tag argument #{JSON.stringify(arg)} of type #{typeof(arg)} for <#{tag_name}>")

        this_tag =
            tag: tag_name
            attrs: attributes
            listeners: {}
            children: null

        levels.push(tags)
        tags = inner_tags = []
        current_tag = this_tag
        tag_chain.push(current_tag)
        css_chain_prev = css_chain
        css_chain = css_chain + make_selectors(current_tag.attrs)

        inner_fn?()

        tags = levels.pop(tags)

        this_tag.children = inner_tags

        if this_tag.attrs.style?
            this_tag.attrs.style = css_def(this_tag.attrs.style)

        tag_chain.pop()
        css_chain = css_chain_prev

        current_tag = tag_chain[tag_chain.length-1]

        tags.push(this_tag)

# css stuff
make_css = (css_name) ->
    css_real_name = css_name.replace("_","-").replace("_","-")
    (args...) ->
        if current_rule
            current_rule[css_real_name] = args[0]
            return
        if not current_tag.attrs.style?
            current_tag.attrs.style = {}
        current_tag.attrs.style[css_real_name] = args[0]

# handler mapper
window._handler = {}
onecup.listeners = []
for i in [0...5000]
    do (i) ->
        onecup.listeners[i] = ->
            onecup.track_error(window._handler[i], arguments...)
            onecup.refresh()
onecup.fn_count = 0
onecup.event_fn = (fn) ->
    window._handler[onecup.fn_count] = fn
    count = onecup.fn_count
    onecup.fn_count += 1
    return count
# js events stuff
make_event = (js_name) ->
    (args...) ->
        current_tag.listeners[js_name[2...]] = onecup.event_fn(args[0])

# generate all tags
for tag in HTML_TAGS
    onecup[tag] = make_tag(tag)
for css in CSS_PROPS
    onecup[css] = make_css(css)
for js_event in JS_EVENT
    onecup[js_event] = make_event(js_event)

# special html functions
# produces normal text
onecup.text = (args...) ->
    tags.push
        special: "text"
        text: args.join("")

# produces unescaped text
onecup.raw = (args...) ->
    tags.push
        special: "raw"
        text: args.join("")

# put some nbsps
onecup.nbsp = (n=1) ->
    for i in [0...n]
        onecup.raw "&nbsp;"

# special image tag
onecup.raw_img = onecup.img
onecup.img = (args...) ->
    for a in args
        if a.src?
            kargs = a
            break
    if not kargs
        console.error "Image without source", args
        return
    src = kargs.src
    # if its a local png try replace with retina version
    if window.devicePixelRatio != 1 and src.indexOf(".png") != -1 and src[0...4] != "http"
        kargs.src = src.replace(".png", "@2x.png")
    if window.devicePixelRatio != 1 and src.indexOf(".jpg") != -1 and src[0...4] != "http"
        kargs.src = src.replace(".jpg", "@2x.jpg")
    onecup.raw_img(args...)

# create a new rule tag
inserted = {}
onecup.css = (args...) ->
    if args.length == 2
        [rule_selector, fn] = args
    else
        rule_selector = ""
        [fn] = args

    css_chain_prev = css_chain
    if rule_selector[0] == ":"
        css_chain = css_chain + rule_selector
    else if rule_selector[0] == "&"
        css_chain = css_chain + rule_selector[1...]
    else
        css_chain = css_chain + " " + rule_selector

    css_rule_chain.push(current_rule)
    current_rule = {}

    fn()

    rule_body = css_def(current_rule)
    current_rule = null
    if rule_body
        rule_css = css_chain + " {" + rule_body + "}"
        if inserted[rule_css] != true
            inserted[rule_css] = true
            document.styleSheets[0].insertRule(rule_css, 0)
            #console.log "rule_css", rule_css

    css_chain = css_chain_prev
    current_rule = css_rule_chain.pop()


if document.styleSheets.length == 0
    document.head.appendChild(document.createElement("style"))


onecup.import = ->
    all = []
    for k of onecup
        if k != "import"
            all.push "#{k} = onecup.#{k}"
    return "var " + all.join(", ") + ";"


onecup.importCoffee = (scope) ->
    all = (k for k of onecup when k != "import" and k != "importCoffee")
    return "{" + all.join(", ") + "} = onecup"



# redraws the full html or just parts of it
redraw = (time) ->
    # console.log "redraw -----------------"
    # reset fn count to start over
    onecup.fn_count = 0
    onecup.params = parse_url()
    onecup.post_render_fns = []
    # make sure document is ready to start drawing
    #if document.readyState != "complete"
    #    console.log "doc not complete", document.getElementById('onecup')
    #    onecup.after(0, onecup.refresh)
    #    return

    if not onecup.body
        try
            onecup.body = document.getElementById('onecup')
            if not onecup.body and document.body
                document.body.innerHTML += "<div id='onecup'></div>"
                onecup.body = document.getElementById('onecup')
            else
                #console.log "no element yet"
                onecup.after(0, onecup.refresh)
                return
        catch e
            #console.log "init", e
            onecup.after(0, onecup.refresh)

    if window.error_body?
        try
            window.body?()
        catch e
            tags = []
            window.error_body?(e)
    else
        window.body?()

    new_oml = render()

    if not full_refresh and old_oml
        dom_scan(onecup.body, new_oml, old_oml)
    else
        # clear whole document
        onecup.body.innerHTML = ''
        # build new nodes
        dom_build(onecup.body, new_oml)
        # dont run full refresh next time
        full_refresh = false
    old_oml = new_oml

    for fn in onecup.post_render_fns
        fn()

onecup.post_render = (fn) ->
    onecup.post_render_fns.push(fn)

# builds the dom
dom_build = (parent, oml) ->
    for elm in oml
        tag_build(elm)
        tag_add(parent, elm)
    return

# ads a tag
tag_add = (parent, elm) ->
    # if there is no parent we cant add?
    if not parent?.appendChild
        return
    elm.parentNode = parent
    if elm.dom?
        #console.log "tag add", elm.dom
        # single element
        parent.appendChild(elm.dom)
    if elm.doms?
        #console.log "raw add", elm.text
        # multiple elements
        for dom in elm.doms
            parent.appendChild(dom)

# builds a tag
tag_build = (elm) ->
    if elm.special == "raw"
        # 'raw' text node
        dom = document.createElement("span")
        dom.innerHTML = elm.text
        elm.doms = []
        for child in dom.childNodes
            elm.doms.push(child)
        # dont allow empty raw nodes
        if elm.doms.length == 0
            elm.doms.push(document.createTextNode(""))

    else if elm.special == "text"
        # true text node
        dom = document.createTextNode(elm.text)
        elm.dom = dom
    else
        dom = document.createElement(elm.tag)
        elm.dom = dom
        for k, v of elm.attrs
            if Array.isArray(v)
                v = v.join(" ")
            if k == "selected"
                if v == true
                    dom.setAttribute(k, v)
            else
                dom.setAttribute(k, v)
        for k, v of elm.listeners
            #console.log "add listener", k, v
            dom.addEventListener(k, onecup.listeners[v])

        if elm.children
            dom_build(dom, elm.children)

    return

# scan the dom for diffs
dom_scan = (parent, as, bs) ->
    #console.log "dom_scan", as, bs
    if !as? and !bs?
        return
    else if !as?
        #console.log "clear children"
        parent.innerHTML = ''
    else if !bs?
        #console.log "new children", as:as, bs:bs
        dom_build(parent, as)
    else
        # if bs has more nodes
        # we need remove some
        if as.length < bs.length
            #console.log "tag removed"
            for i in [as.length...bs.length]
                tag_remove(bs[i])
            scan_length = as.length
        else
            scan_length = bs.length
        # scan down existing nodes
        for i in [0...scan_length]
            tag_scan(as[i], bs[i])
        # if as has more nodes
        # we need to add some
        if as.length > bs.length
            #console.log "tag added"
            for i in [bs.length...as.length]
                elm = as[i]
                tag_build(elm)
                tag_add(parent, elm)
    return

# scan the tags for diffs
tag_scan = (a, b) ->
    #console.log "tag_scan", [a, b]
    if !b?
        throw "no tag b"
    else if a.special? or b.special?
        if a.special != b.special or a.text != b.text
            #console.log "special tag change"
            #console.log "tag build", a
            tag_build(a)
            #console.log "tag replace", a, b
            tag_replace(a, b)
        else
            if b.dom?
                a.dom = b.dom
            else if b.doms?
                a.doms = b.doms
            else
                throw "b has no doms"
    else if a.tag != b.tag
        #console.log "full tag changed"
        tag_build(a)
        tag_replace(a, b)

    else if a.attrs.id != b.attrs.id
        #console.log "full tag changed"
        tag_build(a)
        tag_replace(a, b)
    else
        # parcial tag change
        dom = a.dom = b.dom
        for k,v of a.attrs
            if v != b.attrs[k]
                #console.log "set attr", k
                if k == 'value' and document.activeElement != dom
                    dom.value = v
                else if k == 'style' and IE # ie 11 does not support setAttribute("style",...)
                    dom.removeAttribute(k)
                    dom.setAttribute(k, v)
                    #dom.style = v # old method for IE
                else if k == 'src'
                    dom.src = "data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs%3D"
                    dom.src = v
                else
                    dom.setAttribute(k, v)
        for k,v of b.attrs
            if not a.attrs[k]?
                #console.log "attrs removed", k
                dom.removeAttribute(k)

        # listeners scan
        for k,v of a.listeners
            if not b.listeners[k]?
                #console.log "none added?", k, v, b.listeners
                dom.addEventListener(k, onecup.listeners[v])
            else if v != b.listeners[k]
                #console.log "remove?", onecup.listeners[v]
                dom.removeEventListener(k, onecup.listeners[b.listeners[k]])
                dom.addEventListener(k, onecup.listeners[v])

        for k,v of b.listeners
            if not a.listeners[k]?
                #console.log "been removed?", k, v, onecup.listeners[v]
                #console.log "remove?", onecup.listeners[v]
                dom.removeEventListener(k, onecup.listeners[v])
        #console.log "listeners", a.listeners, b.listeners


        # scan down the children
        dom_scan(dom, a.children, b.children)

    return

# replace one tag with a changed tag
tag_replace = (a, b) ->
    # get the first b
    if b.dom?
        b_dom = b.dom
    else if b.doms?
        b_dom = b.doms[0]
    else
        throw "element b not created"

    parent = b_dom.parentNode
    if not parent?
        # fix for text area user removing nodes
        parent = b.parentNode
        tag_add(parent, a)
        return

    if a.dom?
        parent.insertBefore(a.dom, b_dom)
        a.parentNode = parent

    else if a.doms?
        for dom in a.doms
            parent.insertBefore(dom, b_dom)
        a.parentNode = parent
    else
        throw "element a not created yet"

    tag_remove(b)


# remove the old tag
tag_remove = (b) ->
    # remove b
    if b.dom?
        #console.log "remove b dom", b.dom
        parent = b.dom.parentNode
        # if it has no parent, then its removed?
        if parent
            parent.removeChild(b.dom)
    else if b.doms?
        #console.log "remove b doms", b.doms
        parent = b.doms[0].parentNode
        for dom in b.doms
            parent.removeChild(dom)

    return

# ----------------------------- url stuff -------------------------------

parse_url = ->
    # some bots dont have window.location?
    if not window.location?
        return {}
    params = window.location.search[1...]
    return onecup.parse_query_string(params)

onecup.parse_query_string = (params) ->
    args = {}
    for pair in params.split("&")
        continue if not pair
        [k, v] = pair.split("=")
        if v
            args[k] = unescape(decodeURI(v.replace(/\+/g, " ")))
    return args

onecup.mk_url = (base, params) ->
    url = base
    parts = for key, value of params
        part = ""
        part += key
        part += "="
        part += encodeURIComponent(value)
        part
    if parts.length > 0 and url[url.length-1] != "?"
        url += "?"
    return url + parts.join("&")

onecup.lookup = (selector) ->
    selectorType = 'querySelectorAll';
    if selector.indexOf('#') == 0
        selectorType = 'getElementById';
        selector = selector.substr(1, selector.length);
    return document[selectorType](selector);

setup_new_window = ->
    onecup.new_page()
    onecup.refresh()

onecup.newTab = (url) ->
    if electron? and url.substr(0, 4) == "http"
        electron.shell.openExternal(url)
        return
    window.open(url)

onecup.goto = window.goto = (url) ->
    if electron? and url.substr(0, 4) == "http"
        electron.shell.openExternal(url)
        return
    # if inside a frame open a new window
    track? "goto", url: url
    if url.substr(0, 4) == "http" or url.substr(0, 7) == "mailto:"
        window.location = url
        return
    if window.self != window.top
        window.open(url)
        return

    if window.history?.pushState?
        window.history.pushState("", url, url);
    else
        # safari users for who history is not supported
        if window.location.pathname == "/" and url[0...2] == "/#"
            window.location.hash = url[2...]
        else
            window.location = url

    setup_new_window()

window.onpopstate = (event) ->
    onecup.scroll_top()
    setup_new_window()

onecup.scroll_top = ->
    try
        window.scrollTo(0, 0)
    catch
        track? "scroll_error"

# ----------------------------- view stuff ------------------------------

window.current_view = null
window.last_view_params = null
window.with_view = (view_name, params) ->
    # call exit/enter on view change
    if view_name != window.current_view
        window.last_view_params?.exit?()
        params?.enter?()
        window.current_view = view_name
        onecup.refresh()

    window.last_view_params = params

# ---------------------------- event stuff ------------------------------

# click event is complex
onecup.on_click = (event) ->
    if event.ctrlKey or event.metaKey or event.altKey or event.button == 1
        return
    # do special thing for links with href
    target = event.target
    href = target.getAttribute?("href")
    while !href
        target = target.parentNode
        if not target or not target.getAttribute
            return
        href = target.getAttribute?("href")

    target.onclick?()

    if electron? and href.substr(0, 4) == "http"
        electron.shell.openExternal(href)
        event.preventDefault()
        event.stopPropagation()
        return

    if href.substr(0, 4) != "http" and not target.getAttribute("target")
        goto(href)
        onecup.refresh()
        event.preventDefault()
    else
        if !target.target?
            track? "exit", url:href
            window.location = href
        else
            track? "new_window", url:href
    event.stopPropagation()
    return

window.addEventListener("click", onecup.on_click, true)

# subit event is a no-op, forms are never submitted any more
onecup.on_submit = (event) ->
    event.preventDefault()
    event.stopPropagation()
window.addEventListener("submit", onecup.on_submit, true)


# ---------------------------- refresh stuff ------------------------------

# request animation frame fires a new frame only when browser is ready
requestAnimationFrame = window.requestAnimationFrame or
    window.mozRequestAnimationFrame or
    window.webkitRequestAnimationFrame or
    window.msRequestAnimationFrame or
    (callback) -> window.setTimeout(callback, 17)

onecup.after = (ms, fn) ->
    wrap_fn = ->
        fn()
        onecup.refresh()
    setTimeout(wrap_fn, ms)

onecup.later = (ms, fn) ->
    wrap_fn = ->
        fn()
        onecup.refresh()
    setTimeout(wrap_fn, ms)

# fancy refresh
needs_refresh_flag = false
dont_refresh_this_time = false
onecup.refresh = ->
    if dont_refresh_this_time
        dont_refresh_this_time = false
        return
    if needs_refresh_flag == false
        needs_refresh_flag = true
        tick = ->
            needs_refresh_flag = false
            onecup.track_error(redraw)
        requestAnimationFrame tick, 0

onecup.no_refresh = ->
    dont_refresh_this_time = true

onecup.track_error = (fn, args...) ->
    if track?
        try
            fn(args...)
        catch e
            track 'error', stack:e.stack, message:""+e
            throw e
    else
        fn(args...)

window.onresize = -> onecup.refresh()
visibilitychange = -> onecup.refresh()
document.addEventListener("visibilitychange", visibilitychange, false)

# refresh everything
onecup.params = parse_url()
onecup.after(0, onecup.refresh)


onecup.preloaded = {}
onecup.preload = (src) ->
    if window.devicePixelRatio != 1 and src.indexOf(".png") != -1 and src[0...4] != "http"
        src = src.replace(".png", "@2x.png")
    if not onecup.preloaded[src]
        image = new Image()
        image.src = src
        onecup.preloaded[src] = image

onecup.getCache = {}
onecup.get = (url) ->
    if not onecup.getCache[url]
        page =
            loaded: false
        xhr = new XMLHttpRequest()
        xhr.addEventListener "load", (e) ->
            page.status = xhr.status
            page.loaded = e
            page.json = JSON.parse(xhr.responseText)
            onecup.refresh()
        xhr.addEventListener "error", (e) ->
            page.error = e
            onecup.refresh()
        xhr.addEventListener "abort", (e) ->
            page.abort = e
            onecup.refresh()
        xhr.open("GET", url)
        xhr.send()
        page.xhr = xhr
        onecup.getCache[url] = page
    return onecup.getCache[url]
