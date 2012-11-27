test "action()", ->

  $('body').addClass 'controller-foo action-bar'

  expect 2

  equal typeof action, 'function', "expect action() to be defined"

  action 'foo#bar', ->
    ok true, 'code runs when it should'

  action 'foo#baz', ->
    ok false, "code don't run when it should not"