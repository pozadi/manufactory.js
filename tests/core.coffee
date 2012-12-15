test "elements", ->

  MyModule = module (M) ->
    M.root '.abc'
  equal MyModule.ROOT_SELECTOR, '.abc', 'M.root() works'

  MyModule = module (M) ->
    M.element '.abc', 'foo', true
    M.element 'input[name=abc]'
    M.element 'body', null, false, true
    M.element 'body', 'theBody', true, true
  deepEqual MyModule.ELEMENTS, {
    foo: {selector: '.abc', dynamic: true, global: false}
    inputNameAbc: {selector: 'input[name=abc]', dynamic: false, global: false}
    body: {selector: 'body', dynamic: false, global: true}
    theBody: {selector: 'body', dynamic: true, global: true}
  }, 'M.element() works'

  MyModule = module (M) ->
    M.tree """
      .abc

        [type=button] 
        ul / items %useless_option%  
          li /  item dynamic
      body / theBody  global
      body  / global dynamic
    """
  equal MyModule.ROOT_SELECTOR, '.abc', 'M.tree() works (root)'
  deepEqual(MyModule.ELEMENTS, {
    typeButton: {selector: '[type=button]', dynamic: false, global: false}
    items: {selector: 'ul', dynamic: false, global: false}
    item: {selector: 'li', dynamic: true, global: false}
    theBody: {selector: 'body', dynamic: false, global: true}
    body: {selector: 'body', dynamic: true, global: true}
  }, 'M.tree() works (elements)')
  console.log MyModule.ELEMENTS

  myDiv = $("""
    <div>
      <input type=button value=lick_me>
      <ul>
        <li>1</li> <li>2</li> <li>3</li>
      </ul>
    </div>
  """).appendTo 'body'
  myInstance = new MyModule myDiv
  a = myInstance.find('li:last-child').get()
  b = myDiv.find('li:last-child').get()
  deepEqual a, b, '@find() method works'
  a = myInstance.root.get()
  b = myDiv.get()
  deepEqual a, b, '@root accesor works'
  a = myInstance.typeButton.get()
  b = myDiv.find('[value=lick_me]').get()
  deepEqual a, b, '@%element_name% accesor works'
  a = myInstance.item().get()
  b = myDiv.find('li').get()
  deepEqual a, b, '@%dynamic_element_name%() accesor works'
  a = myInstance.theBody.get()
  b = $('body').get()
  deepEqual a, b, 'Hey!'
  a = myInstance.body().get()
  b = $('body').get()
  deepEqual a, b, 'Ho!'
  myDiv.remove()

  myDiv = $("<div></div>").appendTo 'body'
  button = $("<input type=button value=lick_me>")
  list = $("<ul><li>1</li> <li>2</li> <li>3</li></ul>")
  myInstance = new MyModule myDiv
  a = myInstance.typeButton.get()
  b = []
  deepEqual a, b, 'element accesor empty before element added'
  myDiv.append(button).newHtml(true)
  a = myInstance.typeButton.get()
  b = button.get()
  deepEqual a, b, 'element accesed after it was added'
  list.appendTo(myDiv).newHtml(true)
  a = myInstance.items.get()
  b = list.get()
  deepEqual a, b, 'element accesed after it was added #2'
  myDiv.remove()

test "global variables", ->

  MyModule = module 'MyApp.MyModule', (M) ->
    return
  equal window.MyApp.MyModule, MyModule, "global varible creates"

test "methods", ->

  expect 2

  MyModule = module (M) ->
    M.methods
      initializer: ->
        ok true, 'initializer() calls on instnace creation'
      foo: -> 'bar'
  myInstance = new MyModule $('<div></div>')
  equal myInstance.foo(), 'bar', 'method declared in builder goes to module'

test "settings", ->

  MyModule = module (M) ->
    M.expectSettings 'foo', 'bar'

  myDiv = $('<div data-foo="abc" data-some="abc1"></div>')
  inst_1 = new MyModule myDiv
  deepEqual inst_1.settings, {foo: 'abc'}, 'settings grubs from data-*'

  myDiv = $('<div data-foo="abc" data-some="abc1"></div>')
  inst_2 = new MyModule myDiv, {baz: 'abc2'}
  deepEqual inst_2.settings, {foo: 'abc', baz: 'abc2'}, 'settings pased to constructor has accepted'

  myDiv = $('<div data-foo="abc" data-some="abc1"></div>')
  inst_3 = new MyModule myDiv, {foo: 'abc2'}
  deepEqual inst_3.settings, {foo: 'abc2'}, 'settings pased to constructor overvrites data-settings'

test "initialization (load)", ->

  expect 3

  html = """
    <div class="my-module"></div>
  """
  elements = []
  elements.push $(html).appendTo('body')

  module (M) ->
    M.root '.my-module'
    M.methods
      initializer: -> 
        ok true

  elements.push(el = $ html)
  $('body').append(el).newHtml()

  elements.push $(html).appendTo('body').newHtml()

  $(el).remove() for el in elements

test "DOM events", ->

  expect 10

  module (M) ->
    M.tree """
      .my-module1
        [type=button]
        a
    """
    M.events """
      lick typeButton  buttonLicked
      lick  typeButton extraHandler
      kick typeButton onKick

      kick a  onKick   
      kick a onKickA
    """
    M.event 'lick', 'typeButton', (element, event, eventData) ->
      equal (typeof @buttonLicked), 'function', '(inline) `this` in handler is module instance'
      equal element, @typeButton[0], '(inline) `element` in handler is event target'
      equal eventData, 'abc', '(inline) `eventData` in handler ...'
    M.methods
      buttonLicked: (element, event, eventData) ->
        equal (typeof @buttonLicked), 'function', '`this` in handler is module instance'
        equal element, @typeButton[0], '`element` in handler is event target'
        equal eventData, 'abc', '`eventData` in handler ...'
      extraHandler: ->
        ok true, "multiple handlers on same event"
      onKick: ->
        ok true, """
          Different event on same element,
          and one handler on multiple events.
          Should be called twice.
        """
      onKickA: ->
        ok true, 'another one'
  myDiv = $ """
    <div class=my-module1>
      <input type=button value=lick_me>
      <a href=#>kick me</a>
    </div>
  """
  myDiv.appendTo('body').newHtml()
  myDiv.find('input')
    .trigger('lick', 'abc')
    .trigger('kick')
    .end().find('a')
    .trigger('kick')
    .end().remove()



test "global DOM events", ->

  expect 12

  myDiv = $("""
    <div>
      <div class=my-module4 data-a=1></div>
      <div class=my-module4 data-a=2></div>
    </div>
  """).appendTo 'body'
  module (M) ->
    M.root '.my-module4'
    M.element 'body', 'theBody', false, true
    M.event 'lick', 'theBody', (element, event, eventData) ->
      equal (typeof @onLickBody), 'function', '`this` in handler is module instance'
      equal element, $('body')[0], '`element` in handler is event target'
      equal eventData, 'abc', '`eventData` in handler ...'
    M.event 'lick', 'theBody', 'onLickBody'
    M.methods 
      onLickBody: (element, event, eventData) ->
        equal (typeof @onLickBody), 'function', '`this` in handler is module instance'
        equal element, $('body')[0], '`element` in handler is event target'
        equal eventData, 'abc', '`eventData` in handler ...'
  $('body').trigger 'lick', 'abc'
  myDiv.remove()



test "jquery-plugin", ->

  myDiv = $("""
    <div>
      <div class=my-module2 data-a=1></div>
      <div class=my-module2 data-a=2></div>
      <div class=my-module2 data-a=3></div>
    </div>
  """).appendTo 'body'
  
  module 'Module1', (M) ->
    M.root '.my-module2'
    M.methods
      foo: -> 'bar'
      getA: -> @root.data 'a'

  for el in myDiv.find('div')
    equal $(el).data('a'), $(el).module('Module1').getA(), '.module()'

  myDiv.remove()


test "module events (local)", ->

  expect 3

  MyModule = module (M) ->

  myInstance = new MyModule $('<div></div>')

  handler = (data, eventName) ->
    equal data, 'abc'
    equal @, myInstance
    equal eventName, 'event-1'

  myInstance.on 'event-1', handler

  myInstance.fire 'event-1', 'abc'
  myInstance.fire 'not-listened-event'

  myInstance.off 'event-1', handler

  myInstance.fire 'event-1', 'abc'


test "module events (global)", ->

  expect 3

  module 'SuperModule', (M) ->

  myInstance = new SuperModule $('<div></div>')

  handler = (data, eventName) ->
    equal data, 'abc'
    equal @, myInstance
    equal eventName, 'event-1'

  modules.on 'event-1', 'SuperModule', handler

  myInstance.fire 'event-1', 'abc'
  myInstance.fire 'not-listened-event'

  modules.off 'event-1', 'SuperModule',  handler

  myInstance.fire 'event-1', 'abc'


test "module events (syntax sugar)", ->

  expect 28

  currentAInstance = null

  module 'ModuleA', (M) ->

    M.methods
      initializer: ->
        @fire 'born', 'abc'
      die: ->
        @fire 'die', 'cba'

  module 'ModuleB', (M) ->

    M.moduleEvents """
      born ModuleA onItBorn

      die  ModuleA onItDie
    """

    M.methods
      onItDie: (aInstance, data, eventName) ->
        equal aInstance, currentAInstance
        equal data, 'cba'
        equal eventName, 'die'
        equal @constructor.NAME, 'ModuleB'
      onItBorn: (aInstance, data, eventName) ->
        equal data, 'abc'
        equal eventName, 'born'
        equal @constructor.NAME, 'ModuleB'

  moduleB1 = new ModuleB $('<div></div>')
  moduleB2 = new ModuleB $('<div></div>')

  moduleA1 = new ModuleA $('<div></div>')
  moduleA2 = new ModuleA $('<div></div>')

  currentAInstance = moduleA1
  moduleA1.die()

  currentAInstance = moduleA2
  moduleA2.die()







