_.extend $.fn, {
  module: (moduleName) ->
    if @length
      new manufactory._modules[moduleName] @first()
}
