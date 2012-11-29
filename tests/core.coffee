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





