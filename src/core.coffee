window.manufactory =
  _modules: {}
  _instances: {}
  find: (moduleName) ->
    @_instances[moduleName] or []
  init: (moduleName, context) ->
    @_modules[moduleName].init(context)
  initAll: (context = document) ->
    for moduleName, Module of @_modules when Module.AUTO_INIT
      @init moduleName, context


manufactory.module = (moduleName, builder) ->

  # Called with one argument:
  #   manufactory.module ->
  #     ...
  unless builder
    builder = moduleName
    moduleName = null

  newModule = class extends manufactory.Module
  newModule.constructor(moduleName)

  builder(new manufactory.ModuleInfo newModule)

  newModule.__runAutoInit()

  unless newModule.LAMBDA
    parts = newModule.NAME.split '.'
    theName = parts.pop()
    currentScope = window
    for part in parts
      currentScope = (currentScope[part] or= {})
    currentScope[theName] = newModule

  return newModule
