test ".newHtml()", ->

  expect 4

  equal typeof $().newHtml, 'function', "expect .newHtml() to be defined"

  myDiv = $('<div></div>').appendTo('body')
  myDiv.newHtml ->
    ok true, "event handler runs when .newHtml() calls"
  myDiv.newHtml true, ->
    ok true, "should be called twice"

  myDiv.newHtml()
  myDiv.newHtml(true)
