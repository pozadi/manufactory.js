qunitTap QUnit, (str) ->
  console.log str

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

  moduleACount = ->
    manufactory.find('test.modules.A').length

  moduleAElementsTree = """
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



  QUnit.testStart (details) ->
    $('<div>').html(moduleAHtmlAll).appendTo(hiddenDom)
    window.TestModuleA = manufactory.module 'test.modules.A', (M) ->
      M.tree moduleAElementsTree
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
    window.test.modules = undefined
    hiddenDom.empty()
    $(document).off()
    manufactory._instances = {}
    manufactory._modules = {}



  test "global varibles", ->
    equal TestModuleA, window.test.modules.A

  test "automatic initialisation", ->
    equal moduleACount(), 2
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

  test "@find()", ->
    root = $ moduleAHtmlOne
    obj = new TestModuleA root
    deepEqual obj.find('[type=text]').get(), root.find('[type=text]').get()

  baseUpdateTest = (updateFn) ->
    ->
      root = $ moduleAHtmlOne
      obj = new TestModuleA root
      deepEqual obj.$inputTypeText.get(), root.find('[type=text]').get()
      root.append('<input type="text" />')
      notDeepEqual obj.$inputTypeText.get(), root.find('[type=text]').get()
      updateFn(obj)
      deepEqual obj.$inputTypeText.get(), root.find('[type=text]').get()

  test "@updateElements()", baseUpdateTest (obj) ->
    obj.updateElements()

  test "@$element.update()", baseUpdateTest (obj) ->
    obj.$inputTypeText.update()

  baseInitTest = (initFn) ->
    ->
      equal moduleACount(), 2
      hiddenDom.append(moduleAHtmlOne)
      equal moduleACount(), 2
      initFn()
      equal moduleACount(), 3
      equal manufactory.find(TestModuleB.NAME).length, 0
      hiddenDom.append(moduleAHtmlOne)
      initFn($ '<div>')
      equal moduleACount(), 3
      initFn(hiddenDom)
      equal moduleACount(), 4

  test "manufactory.initAll()", baseInitTest (context) ->
    manufactory.initAll(context)

  test "manufactory.init()", baseInitTest (context) ->
    manufactory.init('test.modules.A', context)

  test "$.fn.module()", ->
    root = $ moduleAHtmlOne
    equal moduleACount(), 2
    ok root.module('test.modules.A') instanceof TestModuleA
    equal moduleACount(), 3
    obj1 = new TestModuleA root
    obj2 = root.module('test.modules.A')
    equal moduleACount(), 3
    equal obj1, obj2

  baseDomEventsTest = (defineEvents) ->
    ->
      MyModule = manufactory.module 'test.modules.DomEventsTest', (M) ->
        M.tree moduleAElementsTree
        defineEvents M
        baseHandler = (getExpectedTarget) ->
          (targetEl, event, additionalData) ->
            ok (this instanceof MyModule)
            equal targetEl, getExpectedTarget(this)
            equal additionalData, 'additionalData'
            equal event.target, targetEl
        M.methods
          onRootClicked: baseHandler (module) -> module.root[0]
          onInputChange: baseHandler (module) -> module.$$inputTypeText(':first')[0]
          onGlobalDivLicked: baseHandler (module) -> module.$globalDiv[0]
      root = $ moduleAHtmlOne
      manufactory.initAll(root)
      root.trigger 'click', 'additionalData'
      root.find('input[type=text]:first').trigger 'change', 'additionalData'
      $('.-global-div').trigger 'lick', 'additionalData'

  # 4 assertions on baseHandler
  # 5 = 2 local events + 1 global * 3 instances
  test "DOM events (M.events())", 4 * 5, baseDomEventsTest (M) ->
    M.events """
      click                  onRootClicked
      change  inputTypeText  onInputChange
      lick    globalDiv      onGlobalDivLicked
    """

  test "DOM events (M.event(... root ...))", 4, baseDomEventsTest (M) ->
    M.event 'click', 'root', 'onRootClicked'

  test "DOM events (M.event(... local element  ...))", 4, baseDomEventsTest (M) ->
    M.event 'change', 'inputTypeText', 'onInputChange'

  test "DOM events (M.event(... local element, custom handler))", 4, baseDomEventsTest (M) ->
    M.event 'change', 'inputTypeText', (targetEl, event, additionalData) ->
      ok (this instanceof test.modules.DomEventsTest)
      equal targetEl, @$$inputTypeText(':first')[0]
      equal additionalData, 'additionalData'
      equal event.target, targetEl

  test "DOM events (M.event(... global element  ...))", 4 * 3, baseDomEventsTest (M) ->
    M.event 'lick  ', 'globalDiv', 'onGlobalDivLicked'
