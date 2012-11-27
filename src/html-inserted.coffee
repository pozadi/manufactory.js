# Small jQuery plugin, actually just alias for .trigger('html-inserted')

# It isn't part of dom-modules, 
# and can be dropped peacefully in case you don't need it.
# As well as you can use it without dom-modules.

# But dom-modules listens for 'html-inserted' event in order to
# update module's elements, and init modules when DOM changes.
# So you probably need it.

# Usage:
#   $(...).append(...).htmlInserted()
#   $(...).appendTo(...).htmlInserted()

jQuery::htmlInserted = ->
  @trigger 'html-inserted'