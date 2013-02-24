_.extend $.fn, {
  module: (moduleName) ->
    if @length
      new manufactory._modules[moduleName] @first()
  update: ->
    @splice 0, @length
    @push el for el in $(@selector, @context)
    @
}
