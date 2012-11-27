# Util function that helps run some code on particular action (in server-side terms).

# It isn't part of dom-modules, 
# and can be dropped peacefully in case you don't need it.
# As well as you can use it without dom-modules.

# Run some JavaScript only on particular action.
#   action 'controller_name#action_name', -> ...
#   action 'foo#bar', 'foo#baz', -> ...
action = (args...) ->
  $ ->
    callback = args.pop()
    callback() if action.matcher(a.split('#') for a in args)
    

# Check if some of listed actions handling now.
# You can redefine this function.
#   action.matcher [['controller_name', 'action_name'], [...], ...]
action.matcher = (actions) ->
  selector = (for a in actions
    # Suppose you add .controller-foo and .action-bar classes to body on server-side.
    "body.controller-#{a[0]}.action-#{a[1]}").join ', '
  $(selector).length > 0

# REFACTOR: I don't happy with function name. 
window.action = action
