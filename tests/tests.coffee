$ -> 

  moduleAHtmlOne = """
    <div class="js-module">
      <button>hello</button>
      <input type="button" value="hello">
      <input type="text" name="a">
      <input type="text" name="b">
      <div class="js-some-div-">
        <div class="child">abc</div>
      </div>
    </div>
  """
  moduleAHtmlAll =  """
    #{moduleAHtmlOne}
    #{moduleAHtmlOne}
    <div class="-global-div">
  """
  hiddenDom = $('<div>').hide().appendTo('body')



  QUnit.testStart (details) ->
    $('<div>').html(moduleAHtmlAll).appendTo(hiddenDom)
    window.TestModuleA = manufactory.module 'test.modules.A', (M) ->
      M.tree """
        .js-module    / foo bar static    dynamic  global /

          button, [type=button]/ allButtons !@#$%^&*()\_+±   
          input[type=text] 

          / withEmptySelector

          // comment
          .js-some-div-  
          .js-some-div- .child    // comment

          .-global-div /global / Приве†
    * / all
      """
      M.expectSettings 'foo bar'
      M.defaultSettings 
        foo: 'default foo'
        bar: 'default bar'
      M.methods
        initializer: ->
          @message = 'hello'
        getMessage: ->
          @message
    window.TestModuleB = manufactory.module (Module) ->
      Module
        .root('.js-module')
        .element('button, [type=button]', 'allButtons')
        .element('input[type=text]')
        .element('.js-some-div-')
        .element('.js-some-div- .child')
        .element('.-global-div', null, true)
        .element('*', 'all')
      Module.autoInit false
    window.TestModuleEmpty = manufactory.module (M) ->



  QUnit.testDone (details) ->
    window.TestModuleA = window.TestModuleB = window.TestModuleEmpty = undefined
    hiddenDom.empty()
    manufactory._modules = {}
    manufactory._instances = {}
    for name, callbacksList in manufactory.callbacks._global
      callbacks.disable() for callbacks in callbacksList
    manufactory.callbacks._global = {}



  test "global varibles", ->
    equal TestModuleA, window.test.modules.A

  test "automatic initialisation", ->
    equal manufactory.find('test.modules.A').length, 2
    equal manufactory.find(TestModuleB.NAME).length, 0
    equal manufactory.find(TestModuleEmpty.NAME).length, 0

  test "M.tree(), M.root(), M.element()", ->
    equal TestModuleA.ROOT_SELECTOR, '.js-module'
    equal TestModuleEmpty.ROOT_SELECTOR, null
    equal TestModuleB.ROOT_SELECTOR, TestModuleA.ROOT_SELECTOR
    deepEqual TestModuleB.ELEMENTS, TestModuleA.ELEMENTS
    deepEqual TestModuleA.ELEMENTS, {
      allButtons:    {selector: 'button, [type=button]', global: false}
      inputTypeText: {selector: 'input[type=text]',      global: false}
      someDiv:       {selector: '.js-some-div-',         global: false}
      someDivChild:  {selector: '.js-some-div- .child',  global: false}
      globalDiv:     {selector: '.-global-div',          global: true }
      all:           {selector: '*',                     global: false}
    }

  test "@root, @$element, @$$element", ->
    root = $ moduleAHtmlOne
    obj = new TestModuleA root
    deepEqual root.get(), obj.root.get()
    deepEqual root.find('button, [type=button]').get(), obj.$allButtons.get()
    deepEqual $('.-global-div').get(), obj.$globalDiv.get()
    #TODO @$$element

  test "methods", ->
    equal (new TestModuleA $ []).getMessage(), 'hello'

  test "settings", ->
    deepEqual (new TestModuleA $ '<div>').settings, TestModuleA.DEFAULT_SETTINGS
    deepEqual (new TestModuleA $ '<div data-baz="baz">').settings, TestModuleA.DEFAULT_SETTINGS
    deepEqual (new TestModuleA $ '<div data-foo="foo">').settings, {
      foo: 'foo',
      bar: 'default bar'
    }
    deepEqual (new TestModuleA $ '<div data-foo="foo" data-bar="bar" data-baz="baz">').settings, {
      foo: 'foo',
      bar: 'bar'
    }
    deepEqual (new TestModuleA $('<div>'), {foo: 'foo', baz: 'baz'}).settings, {
      foo: 'foo',
      bar: 'default bar',
      baz: 'baz'
    }
    deepEqual (new TestModuleA $('<div data-foo="foo" data-bar="bar">'), {bar: 'bar1'}).settings, {
      foo: 'foo',
      bar: 'bar1'
    }

  ### TODO:
    @find()
    @updateElements()
    manufactory.initAll()
    manufactory.init()
    DOM events (local/global)
      M.events()
      M.event()
      triggering itself
      handler arguments
    module events (local/global)
      @on(), @off(), @fire()
      manufactory.on(), manufactory.off()
      M.moduleEvents()
      triggering itself
      handler arguments
    $.fn.module()
    $.fn.update()
  ###
