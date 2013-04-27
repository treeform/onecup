# Onecup #

Onecup is a pure coffee script client side or server side tempting engine. It excels at generating complex HTML in a few lines. Onecup is just coffee script which is just javascript. It requires no compolation (apart from coffeescript) and you can use all expressiveness and organization of coffee script anywhere in the templates.

Hello world example:
```
html ->
  body ->
    div ->
      text "get "
      a href:"https://github.com/treeform/onecup", -> "OneCup"
      text " here"
```

Onecup makes several assumptions:

 + big chunks of the page going to be re-renders at once.
 + there is a need to explicit whitespace control
 + HTML is more of an object code then markup

## Features ##

### jquery style selectors ###
If first argument to a template tag begins with a `#` or `.` it is treated as a *id* or *class*. It uses the JQuery selectors syntax. Example:

```
div "#list-holder" ->
  ol "#main-list.number-list" ->
    for i in [0..10]
	li ".number-iten", "nubmer {i}"
```

### explicit text and whitespace ###
Text is explicit, yet you get explicit control over your whitespace. You also don't have to fight over whitespace minifiers, because verything produced is already minified.

```
div ->
  text "foo"
div ->
  text "foo"
```

Using `text` or leaving it on the same line is equivilent

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
You can also pass styles directly using the `style` attribute. This is needed when generating some complex looking HTML such as graphs and other visualizations. Or if you don't want to clutter your css with layout code that is not reusible.

```
div style{"z-index":5*4}, "z-index compution"
div style:{'background-color': "red"}, ->
   text "this text will be red"
```

### html attributes ###

You can also pass special HTML attributes: `selected`, `disabled`, `checked`, `readonly`, and `multiple`. Which are surprisingly awkward in other templeting engines. 

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

Compatibility with coffee script is 100%. OneCup is coffee script so you can use coffee script functions, loops, ifs, classes, and other constructs.

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

### ifs ###
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

# anywere in your code
html = drykup.render($t.full_doc(template, args))
# use JQuery (or some thing else) to insert it into html
$("html").html(html)

```

## Origin ##

Onecup was originally fork of drykup (https://github.com/mark-hahn/drykup) by Mark Hahn, which was a fork of coffeekup (https://github.com/mauricemach/coffeekup) by Maurice Machado. But now its a whole different thing!