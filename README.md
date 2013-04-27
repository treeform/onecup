# Onecup #

Onecup uses coffee script's nifty function nesting trick to bring your kickass yet simple templeting library.

```
html ->
  body ->
    div ->
      text "get "
      a href:"https://github.com/treeform/onecup", -> "OneCup"
      text " here"
```

Onecup makes several assumptions:

 + big chunks of the page going to be re-rendered at once.
 + there is a need for explicit whitespace control
 + HTML is more of an object code then markup

Onecup excels at generating complex HTML in a few lines. It is just coffee script which is just javascript. It requires no compilation (apart from coffee script) and you can use all expressiveness and organization of coffee script anywhere in the templates.

## Features ##

### JQuery style selectors ###
If first argument to a template tag begins with a `#` or `.` it is treated as a *id* or *class*. It uses the JQuery selectors syntax. Example:

```
div "#list-holder" ->
  ol "#main-list.number-list" ->
    for i in [0..10]
	li ".number-iten", "nubmer {i}"
```

### explicit text and whitespace ###
Text is explicit, yet you get explicit control over your whitespace. You also don't have to fight over whitespace minifiers, because everything produced is already minified.

```
div ->
  text "foo"
div ->
  text "foo"
```

Using `text` or leaving it on the same line is equivalent

```
p "look its the same thing"
p ->
    text "look its the same thing"
```

### raw text ###
`text` escapes things by default so you might have to use `raw` if you want to inject html or other markup

```
div ->
  raw markdown_html
```

### styles ###
Styles can be passed directly using the `style` attribute. This is needed when generating some complex looking HTML such as graphs and other visualizations. Or to not clutter the css with layout code that is not reusable.

```
div style{"z-index":5*4}, "z-index computation"
div style:{'background-color': "red"}, ->
   text "this text will be red"
```

### html attributes ###

Special HTML attributes can also be passed. `selected`, `disabled`, `checked`, `readonly`, and `multiple` are supported. They are surprisingly awkward in other templeting engines. 

```
div ->
  ol ->
    for i in [0..10]
      li ->
        text "nubmer {i}"
        input 
            type:check 
            checked:i==5
```
   
you can also define your own custom attributes

```
div data:"1234"
```

### just coffee script ###

Onecup is 100% coffee script, so you can use functions, loops, if blocks, classes, and other coffee script constructs.

### function ###

```
# define a common function
bbox = (content) ->
  div ".other-border", ->
    div ".inner-border", ->
	div ".inner-layout", ->
	   content()

bbox ->
  text "this box has fancy border"

bbox ->
  text "so does this"
```

### if blocks ###
```
a = true
if a 
    p "a is true"
else
    p "a is false"
```

### loops ###

```
colors = ["red", "green", "blue"]
for color in colors
  div style:{'color': color}
```

## Use ##

How to use OneCup in your app:

```
# import tags into your namespace
{render, div, span, table, thead, tbody, tr, td, th, text, textarea, button, hr, iframe,
 raw, a, br, b, img, label, form, input, ul, li, h1, h2, h4, select, option, p} = window.drykup

# define a template namespace
$t = {}

# attach function to your template namespace
$t.full_doc ->
  body ->
    p "content here"

# anywhere in your code
html = onecup.render($t.full_doc(template, args))
# use JQuery (or some thing else) to insert it into html
$("html").html(html)

```

## Origin ##

Onecup was originally fork of dryKup (https://github.com/mark-hahn/drykup) by Mark Hahn, which was a fork of CoffeeKup (https://github.com/mauricemach/coffeekup) by Maurice Machado. But now its a whole different thing!