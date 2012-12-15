test ".newHtml()", ->

  expect 2

  equal typeof $().newHtml, 'function', "expect .newHtml() to be defined"

  myDiv = $('<div>test</div>').appendTo('body')
  myDiv.on 'new-html', ->
    ok true, "event handler runs when .newHtml() calls"
    myDiv.remove()

  myDiv.newHtml()