test "Dom-modules: elements", ->

  MyModule = module (M) ->
    M.root '.abc'
  equal MyModule.ROOT_SELECTOR, '.abc', 'M.root() works'

  MyModule = module (M) ->
    M.element '.abc', 'foo', true
  deepEqual MyModule.ELEMENTS, {foo: {selector: '.abc', dynamic: true}}, 'M.element() works'

  MyModule = module (M) ->
    M.element 'input[name=abc]'
  deepEqual MyModule.ELEMENTS, {inputNameAbc: {selector: 'input[name=abc]', dynamic: false}}, 'M.element() works #2'

  MyModule = module (M) ->
    M.tree """
      .abc
        [type=button]
        ul / items
          li / item dynamic
    """
  equal MyModule.ROOT_SELECTOR, '.abc', 'M.tree() works'
  deepEqual(MyModule.ELEMENTS, {
    typeButton: {selector: '[type=button]', dynamic: false}
    items: {selector: 'ul', dynamic: false}
    item: {selector: 'li', dynamic: true}
  }, 'M.tree() works #2')

  myDiv = $("""
    <div style="display:none">
      <input type=button value=lick_me>
      <ul>
        <li>1</li> <li>2</li> <li>3</li>
      </ul>
    </div>
  """).appendTo 'body'
  myInstance = new MyModule myDiv
  deepEqual myInstance.find('li:last-child').get(), myDiv.find('li:last-child').get(), '@find() method works'
  deepEqual myInstance.root.get(), myDiv.get(), '@root accesor works'
  deepEqual myInstance.typeButton.get(), myDiv.find('[value=lick_me]').get(), '@%element_name% accesor works'
  deepEqual myInstance.item().get(), myDiv.find('li').get(), '@%dynamic_element_name%() accesor works'