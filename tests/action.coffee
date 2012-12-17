test "action()", ->

  $('body').addClass 'controller-foo action-bar'

  expect 5

  equal typeof action, 'function', "expect action() to be defined"

  action 'foo#bar', ->
    ok true, 'code runs when it should'

  action 'foo#baz', ->
    ok false, "code don't run when it should not"
    $('body').removeClass 'controller-foo action-bar'

  action 'not#match', 'foo#bar', ->
    ok true, 'multiple actions'

  action 'not#match', 'not#match_as_well', ->
    ok false, 'multiple actions (not match)'

  action 'foo', ->
    ok true, 'only controller'

  action '#bar', ->
    ok true, 'only action'

  action 'baz', ->
    ok false, 'only controller (not match)'

  action '#baz', ->
    ok false, 'only action (not match)'

