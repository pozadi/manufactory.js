test ".htmlInserted()", ->

  expect 2

  equal typeof $().htmlInserted, 'function', "expect .htmlInserted() to be defined"

  myDiv = $('<div style="display:none">test</div>').appendTo('body')
  myDiv.on 'html-inserted', ->
    ok true, "event handler runs when .htmlInserted() calls"
    myDiv.remove()

  myDiv.htmlInserted()