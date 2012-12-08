test "Dom-modules: elements", ->

  MyModule = module (M) ->
    M.root '.abc'
  equal MyModule.ROOT_SELECTOR, '.abc', 'M.root() works'

  MyModule = module (M) ->
    M.element '.abc', 'foo', true
  deepEqual MyModule.ELEMENTS, {foo: {selector: '.abc', dynamic: true}}, 'M.element() works'

  MyModule = module (M) ->
    M.element 'input[name=abc]'
  deepEqual MyModule.ELEMENTS, {
    inputNameAbc: {selector: 'input[name=abc]', dynamic: false}
  }, 'M.element() works #2'

  MyModule = module (M) ->
    M.tree """
      .abc

        [type=button]  
        ul / items %useless_option%  
          li / item dynamic
    """
  equal MyModule.ROOT_SELECTOR, '.abc', 'M.tree() works'
  deepEqual(MyModule.ELEMENTS, {
    typeButton: {selector: '[type=button]', dynamic: false}
    items: {selector: 'ul', dynamic: false}
    item: {selector: 'li', dynamic: true}
  }, 'M.tree() works #2')
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
  myDiv.remove()

  myDiv = $("<div></div>").appendTo 'body'
  button = $("<input type=button value=lick_me>")
  list = $("<ul><li>1</li> <li>2</li> <li>3</li></ul>")
  myInstance = new MyModule myDiv
  a = myInstance.typeButton.get()
  b = []
  deepEqual a, b, 'element accesor empty before element added'
  myDiv.append(button).htmlInserted()
  a = myInstance.typeButton.get()
  b = button.get()
  deepEqual a, b, 'element accesed after it was added'
  list.appendTo(myDiv).htmlInserted()
  a = myInstance.items.get()
  b = list.get()
  deepEqual a, b, 'element accesed after it was added #2'
  myDiv.remove()

test "Dom-modules: global variables", ->

  MyModule = module 'MyApp.MyModule', (M) ->
    return
  equal window.MyApp.MyModule, MyModule, "global varible creates"

test "Dom-modules: methods", ->

  expect 2

  MyModule = module (M) ->
    M.methods
      initializer: ->
        ok true, 'initializer() calls on instnace creation'
      foo: -> 'bar'
  myInstance = new MyModule $('<div></div>')
  equal myInstance.foo(), 'bar', 'method declared in builder goes to module'

test "Dom-modules: settings", ->

  MyModule = module (M) ->
    M.expectSettings 'foo', 'bar'
  myDiv = $('<div data-foo="abc" data-some="abc1"></div>')

  inst_1 = new MyModule myDiv
  deepEqual inst_1.settings, {foo: 'abc'}, 'settings grubs from data-*'

  inst_2 = new MyModule myDiv, {baz: 'abc2'}
  deepEqual inst_2.settings, {foo: 'abc', baz: 'abc2'}, 'settings pased to constructor has accepted'

  inst_3 = new MyModule myDiv, {foo: 'abc2'}
  deepEqual inst_3.settings, {foo: 'abc2'}, 'settings pased to constructor overvrites data-settings'

test "Dom-modules: initialization (load)", ->

  expect 3

  html = """
    <div class="my-module"></div>
  """
  elements = []
  elements.push $(html).appendTo('body')

  module (M) ->
    M.root '.my-module'
    M.init 'load'
    M.methods
      initializer: -> 
        ok true

  elements.push(el = $ html)
  $('body').append(el).htmlInserted()

  elements.push $(html).appendTo('body').htmlInserted()

  $(el).remove() for el in elements

test "Dom-modules: DOM events (regular)", ->

  expect 10

  module (M) ->
    M.init 'load'
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
  myDiv.appendTo('body').htmlInserted()
  myDiv.find('input')
    .trigger('lick', 'abc')
    .trigger('kick')
    .end().find('a')
    .trigger('kick')
    .end().remove()

test "Dom-modules: DOM events (lazy)", ->

  expect 10

  module (M) ->
    M.init 'lazy'
    M.tree """
      .my-module3
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
    <div class=my-module3>
      <input type=button value=lick_me>
      <a href=#>kick me</a>
    </div>
  """
  myDiv.appendTo('body')
  myDiv.find('input')
    .trigger('lick', 'abc')
    .trigger('kick')
    .end().find('a')
    .trigger('kick')
    .end().remove()

test "Dom-modules: global DOM events (regular)", ->

  expect 12

  myDiv = $("""
    <div>
      <div class=my-module4 data-a=1></div>
      <div class=my-module4 data-a=2></div>
    </div>
  """).appendTo 'body'
  module (M) ->
    M.init 'load'
    M.root '.my-module4'
    M.globalEvent 'lick', 'body', (element, event, eventData) ->
      equal (typeof @onLickBody), 'function', '`this` in handler is module instance'
      equal element, $('body')[0], '`element` in handler is event target'
      equal eventData, 'abc', '`eventData` in handler ...'
    M.globalEvent 'lick', 'body', 'onLickBody'
    M.methods 
      onLickBody: (element, event, eventData) ->
        equal (typeof @onLickBody), 'function', '`this` in handler is module instance'
        equal element, $('body')[0], '`element` in handler is event target'
        equal eventData, 'abc', '`eventData` in handler ...'
  $('body').trigger 'lick', 'abc'
  myDiv.remove()

test "Dom-modules: global DOM events (lazy)", ->

  expect 12
  
  module (M) ->
    M.init 'lazy'
    M.root '.my-module5'
    M.globalEvent 'lick1', 'body', (element, event, eventData) ->
      equal (typeof @onLickBody), 'function', '`this` in handler is module instance'
      equal element, $('body')[0], '`element` in handler is event target'
      equal eventData, 'abc', '`eventData` in handler ...'
    M.globalEvent 'lick1', 'body', 'onLickBody'
    M.methods 
      onLickBody: (element, event, eventData) ->
        equal (typeof @onLickBody), 'function', '`this` in handler is module instance'
        equal element, $('body')[0], '`element` in handler is event target'
        equal eventData, 'abc', '`eventData` in handler ...'
  myDiv = $("""
    <div>
      <div class=my-module5 data-a=1></div>
      <div class=my-module5 data-a=2></div>
    </div>
  """).appendTo 'body'
  $('body').trigger 'lick1', 'abc'
  myDiv.remove()

test "Dom-modules: jquery-plugin (regular)", ->

  myDiv = $("""
    <div>
      <div class=my-module2 data-a=1></div>
      <div class=my-module2 data-a=2></div>
      <div class=my-module2 data-a=3></div>
    </div>
  """).appendTo 'body'
  
  module 'Module1', (M) ->
    M.init 'load'
    M.root '.my-module2'
    M.methods
      foo: -> 'bar'
      getA: -> @root.data 'a'

  for instance in myDiv.find('div').modules 'Module1'
    equal instance.foo(), 'bar', '.modules()'

  for el in myDiv.find('div')
    equal $(el).data('a'), $(el).module('Module1').getA(), '.module()'

  myDiv.remove()

test "Dom-modules: jquery-plugin (lazy)", ->

  myDiv = $("""
    <div>
      <div class=my-module2 data-a=1></div>
      <div class=my-module2 data-a=2></div>
      <div class=my-module2 data-a=3></div>
    </div>
  """).appendTo 'body'
  
  module 'Module1', (M) ->
    M.init 'lazy'
    M.root '.my-module2'
    M.methods
      foo: -> 'bar'
      getA: -> @root.data 'a'

  for instance in myDiv.find('div').modules 'Module1'
    equal instance.foo(), 'bar', '.modules()'

  for el in myDiv.find('div')
    equal $(el).data('a'), $(el).module('Module1').getA(), '.module()'

  myDiv.remove()


test "Dom-modules: module events (local)", ->

  expect 2

  MyModule = module (M) ->

  myInstance = new MyModule $('body')

  handler = (instance, data) ->
    equal data, 'abc'
    equal instance, myInstance

  myInstance.on 'event-1', handler

  myInstance.fire 'event-1', 'abc'
  myInstance.fire 'not-listened-event'

  myInstance.off 'event-1', handler

  myInstance.fire 'event-1', 'abc'


test "Dom-modules: module events (global)", ->

  expect 2

  module 'SuperModule', (M) ->

  myInstance = new SuperModule $('body')

  handler = (instance, data) ->
    equal data, 'abc'
    equal instance, myInstance

  modules.on 'SuperModule', 'event-1', handler

  myInstance.fire 'event-1', 'abc'
  myInstance.fire 'not-listened-event'

  modules.off 'SuperModule', 'event-1', handler

  myInstance.fire 'event-1', 'abc'


test "Dom-modules: module events (syntax sugar)", ->

  ok 'todo'
