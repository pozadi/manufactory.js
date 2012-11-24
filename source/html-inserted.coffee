# Small jQuery plugin, actually just alias for .trigger('html-inserted')

# It isn't part of dom-modules, 
# and can be dropped peacefully in case you don't need it.
# As well as you can use it without dom-modules.

# But this file extends dom-modules a little, to help it 
# run initialisation when DOM chages. So you probably need it.

# Usage:
#   $(...).append(...).htmlInserted()
#   $(...).appendTo(...).htmlInserted()

jQuery::htmlInserted = ->
  @trigger 'html-inserted'


# TODO: extend dom-modules