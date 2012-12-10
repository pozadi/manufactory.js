*DOM-modules.js* — это библиотека для организации вашего яваскрипта на сайте в 
виде модулей. Эта библиотека не умеет подгружать модули по необходимости 
управлять зависимостями и т.д. Она решает другие задачи.

## Идеология

*Стандартизация, декомпозиция, самодокументируемость* — это основа библиотеки.
Использование DOM-modules.js помогает сделать код однородным и 
самозадокументированным. И помогает выделить модули в независимые сущности.

С другой стороны, библиотека помогает работать с DOM и событиями. И упрощает
инициализацию и общение между модулями. Но я не придумал для этих вещей 
красивые слова.

## Пример

### Список дел


```CoffeeScript
# CoffeeScript

module 'Todos', (M) ->
  M.tree """
    .todos
      h1 small / clearButton
      ol / itemList
        li / item dynamic
          [type=checkbox] / itemCheckbox
      form
        [type=text] / newItemText
  """
  M.events """
    submit form add
    change itemCheckbox toggleItem
    click clearButton clear
  """
  M.methods
    template: _.template """
      <li>
        <input type=checkbox> <%= text %>
      </li>
    """
    add: ->
      newItem = $ @template text: @newItemText.val()
      @itemList.append newItem
      @newItemText.val ''
      false
    toggleItem: (checkbox) ->
      item = $(checkbox).parents 'li'
      item.toggleClass 'done', $(checkbox).prop 'checked'
    clear: ->
      @item().filter('.done').remove()
```

```html
<!-- HTML -->

<div class=todos>
  <h1>ToDo <small>Clear completed</small></h1>
  <ol>
    <li>
      <input type=checkbox> Nothing
    </li>
  </ol>
  <form>
    <input type=text placeholder="Good stuff">
    <input type=submit value=Add>
  </form>
</div>
```

## Создание модуля

### `window.module([name], callback)`

Для создания модуля нужно вызвать функцию `module()`, и передать
в нее имя будущего модуля и функцию, в которой будет доступно API для создания
модуля. Имя передавать не обязательно.

```CoffeeScript
MyModule = module 'myApp.MyModule', (M) ->
  ...
```

После выполнения этого кода будет создан модуль. В переменных `MyModule` и 
`window.myApp.MyModule` будет класс модуля. Если не указывать имя, то глобальная 
переменная не создастся.

Теперь можно создать экземпляр модуля, так же как и экземпляр любого класса.

```CoffeeScript
myInstance = new MyModule $('.js-my-module'), {someOption: 'value'}
```

При создании экземпляра модуля необходимо передать корневой элемент модуля 
(*jQuery-объект*) и вторым параметром настройки, но это уже не обязательно.

Забегая вперед скажу, что создавать модуль таким образом, по задумке, придется 
редко. (См. инициализация)

В конструкторе (в `callback` переданном в `module()`) доступно API создания 
модуля. Оно передается первым и единственным параметром в `callback`.

> здесь и далее под `M` будет подразумеваться API создания модуля

## Элементы

Первое что делается при создании модуля — описываются DOM-элементы, с которыми он
работает. Описанные элементы будут доступны в экземпляре модуля, а так же будут
использоваться при описании событий.

Описание элементов это часть той самой самодокументируемости.

### `M.tree(treeOfElements)`

`M.tree()` используется для описания структуры элементов модуля. В эту функцию
передается дерево элементов модуля напоминающее код на [haml](http://haml.info/).

```CoffeeScript
M.tree """
  .js-super-puper
    .js-item-list
      .js-item
    .js-button
"""
```

Это самый простой случай — каждая строка это селектор. Первая строка — 
селектор корневого элемента модуля. Остальные — обычные элементы. Отступы при
разборе будут убраны и не будут учитываться. Но их желательно ставить для 
ясности.

Если модуль объявлен с таким деревом, то в экземпляре модуля будут доступны
следующие свойтва: `@jsItemList`, `@jsItem` и `@jsButton` — это уже готовые 
*jQuery-объекты*.

Селекторы преобразуются в свойства по правилу: разбиваем селектор на слова 
(разделитель — всё кроме букв и цифр) и соединяем слова в одно слово написав
каждое слово, кроме первого, с большой буквы. 

Но есть возможность самому выбрать имя. Для этого после селектора нужно 
поставить символ `/` и после него имя: `input[type=button] / superButton`

Кроме имени после `/` можно указать опции элемента.

Если написать `.items li / dynamic`, то вместо свойства `@itemsLi` в экземпляре 
будет доступен метод `@itemsLi()` который будет каждый раз возвращать свежий 
объект `@root.find('.items li')`. Кстати, корень всегда доступен в свойстве 
`@root`.

Вторая доступная опция `global`. Если написать `body / global`, то элемент будет
искаться не внутри корня модуля, а во всем документе.

```CoffeeScript
M.tree """
  .js-super-puper
    ul / itemList
      li / item dynamic
    form [name=add] / addButton
  body / global
"""
```

### `M.root(selector)` и `M.element(selector, name=null, dynamic=false, global=false)`

Есть способ добавлять элементы и указывать селектор корня на более низком уровне
чем `M.tree()`.

`M.root()` задает селектор корня. `M.element()` добавляет элемент (можно вызывать
много раз, в отличии от `M.tree()`).

## События DOM

После описания всех элементов, с которыми работает модуль, идет описание всех 
событий. Это одна из основных идей. Модуль состоит из описательной части и 
логики (методы). Описательная часть автоматически является документацией к 
модулю. Конечно не полной, но уже можно получить много информации в специально
отведенном, всегда одном и том же, месте.

### `M.evets(eventsDescription)`

```CoffeeScript
M.events """
  click addButonn addItem
  click item removeItem
"""
```

Описание событий, как и описание элементов, делается в виде одной большой 
строки (Haters gonna hate). Каждая строка, в большой строке, состоит из трех 
слов: название события, имя элемента и имя метода.

### `M.event(eventName, elementName, handler)`

Есть и более низкоуровневый способ. Здесь `handler` может быть как строкой 
(имя метода), так и функцией. В любом случае в обработчике, будь то метод или
анонимная функция, `this` будет указывать на объект модуля. Первый параметр 
будет элементом на котором произошло событие, и дальше параметры как в `jQuery`:

```CoffeeScript
(element, event, data) ->
  this // экземпляр модуля
```

## События модулей

    # TODO

## Методы

    # TODO

## Инициализация

    # TODO

## Утилиты

    # TODO

## API целиком

### Глобальные функции (`window.`)

 * [`window.module([name], callback)`](#windowmodulename-callback) — создание модуля

### В конструкторе (`M.`)

 * [`M.tree(treeOfElements)`](#mtreetreeofelements) — описание элементов
 * [`M.root(selector)`](#mrootselector-%D0%B8-melementselector-namenull-dynamicfalse-globalfalse) — указание корневого селектора
 * [`M.element(selector, name=null, dynamic=false, global=false)`](#mrootselector-%D0%B8-melementselector-namenull-dynamicfalse-globalfalse) — добавление элемента
 * [`M.evets(eventsDescription)`](#mevetseventsdescription) — описание событий
 * [`M.event(eventName, elementName, handler)`](#mevetseventsdescription) — добавление события

### В экземпляре модуля (`@`)
 
 * TODO

### %Придумать название% `window.modules.`
 
 * TODO

### Плагины jQuery `$(...).`
 
 * TODO






