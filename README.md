*manufactory.js* — это библиотека для организации вашего яваскрипта на сайте в 
виде модулей. Эта библиотека не умеет подгружать модули по необходимости 
управлять зависимостями и т.д. Она решает другие задачи.

Основная идея состоит в том, чтобы разделить код модуля на две части: 
 * описание в декларативном стиле того, что можно описать в декларативном стиле;
 * обычный код. 

При создании модуля сначала описываются все DOM элементы, c которыми
он работает, и события, на которые он реагирует. Это описательная часть. 
Посмотрев описательную часть, уже можно составить представление о модуле. После
описательной части идут методы, в которых содержится собственно код модуля.

Второе, что дает библиотека — это средства общения между модулями. Библиотека
дает *события модулей*, которые работают параллельно с событиями DOM. И 
предоставляет API для получения доступа к объектам модулей.

Третье — автоматическая инициализация.

И четвертое — мелкие полезные утилиты.

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
    template: _.template "<li><input type=checkbox> <%= text %></li>"
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
  <ol></ol>
  <form>
    <input type=text placeholder="Good stuff">
    <input type=submit value=Add>
  </form>
</div>
```

## Подключение

Для работы библиотеки нужно подключить jQuery 1.8+, [Underscore.js](http://underscorejs.org/) 1.4.3+
и саму библиотеку (файл [manufactory.js](https://github.com/pozadi/manufactory.js/blob/master/manufactory.js))

## Создание модуля

### `window.module([name], callback)`

Для создания модуля нужно вызвать функцию `module()`, и передать
в нее имя будущего модуля и функцию, в которой будет доступно API для создания
модуля. Имя передавать не обязательно.

```CoffeeScript
MyModule = module 'myApp.MyModule', (M) ->
  ... # Код создания модуля
```

После выполнения этого кода будет создан модуль. В переменных `MyModule` и 
`window.myApp.MyModule` будет класс модуля. Если не указывать имя, то глобальная 
переменная не создастся.

Теперь можно создать экземпляр модуля, так же как и экземпляр любого класса.

```CoffeeScript
myInstance = new MyModule $('.js-my-module'), {someOption: 'value'}
```

При создании экземпляра модуля необходимо передать корневой элемент модуля 
(jQuery-объект) и вторым параметром настройки, но это уже не обязательно.

Забегая вперед скажу, что создавать модуль таким образом, по задумке, придется 
редко. (См. инициализация)

В `callback`, переданном в `module()`, доступен объект `ModuleInfo`. Он
передается в `callback`. Это всё что передаетя в `callback`. Вызывая методы 
этого объекта мы и создаем будущий модуль.

> здесь и далее под `M` будет подразумеваться объект `ModuleInfo`

## Элементы

Первое, что делается при создании модуля — описываются DOM-элементы, с которыми он
работает. Описанные элементы будут доступны в экземпляре модуля, а так же будут
использоваться при описании событий.

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
  this # экземпляр модуля
```

## События модулей

Библиотека предоставляет дополнительный уровень событий в дополнение к событиям
DOM. События DOM срабатывают на элементах DOM, а события модулей на экземплярах
модулей. Можно подписаться как на события конкретного экземпляра, так и на 
события всех экземпляров определенного модуля.

### `%module_instance%.on(eventName, handler)`

Подписаться на событие экземпляра модуля. В обработчик передаются данные переданные в 
функцию `fire()` и имя события. При этом в `this` будет ссылка на экземпляр 
модуля на котором произошло событие.

```CoffeeScript
(data, eventName) ->
  this # Ссылка на экземпляр модуля на котором произошло событие
```

### `window.modules.on(eventName, moduleName, handler)`

Можно подписаться на события всех существующих и будущих экземпляров модуля. В
обработчик передается всё так же как в предыдущем случае.

### `%module_instance%.off(eventName, handler)`

Отписать обработчик от события.

### `window.modules.off(eventName, moduleName, handler)`

Отписать обработчик от события.

### `%module_instance%.fire(eventName, data)`

Сгенерировать событие на экземпляре модуля.

### `M.moduleEvents(moduleEventsDescription)`

По задумке, вместо использования низкоуровневых методов `.on()`, все события
описываются в декларативном стиле при создании модуля.

```CoffeeScript
M.modulesEvents """
  eventNameA moduleNameA hadlerA
  eventNameB moduleNameB hadlerB
"""
```

Где `hadlerA` и `hadlerB` — методы создаваемого модуля. При этом нужно обратить
внимание, что в этих методах, в отличии от обработчика в `.on()`, в переменной
`this` будет ссылка не на экземпляр на котором произошло событие, а на экземпляр
к которому пренадлежит метод. Ссылка же на источник события будет передана 
первым параметром:

```CoffeeScript
module 'ModuleA', (M) ->
  ...
  M.methods
    someMethod: ->
      ...
      @fire 'important-event', {some: 'data'}

module 'ModuleB', (M) ->
  ...
  M.moduleEvents """
    important-event ModuleA onImpotentEvent
  """
  M.methods:
    onImpotentEvent: (moduleAInstabce, data, eventName) ->
      this            # Ссылка на экземпляр ModuleB
      moduleAInstabce # Ссылка на экземпляр ModuleA
      data            # {some: 'data'}
      eventName       # 'important-event'
```

### `M.moduleEvent(eventName, moduleName, handler)`

Тоже что и `M.event()` для `M.events()`.

## Методы

### `M.methods(object)`

Функция для описания методеов модуля. Так же через нее можно добавить 
дополнительные свойства модуля. Всё молжно быть понятно из примера:

```CoffeeScript
module 'SuperPuper', (M) ->
  M.tree """
    .super-puper
      ul / list
        li / item dynamic
  """
  M.methods
    someProperty: 'foo'
    someMethod: ->
      this          # Ссылка на экземпляр модуля
      @list         # jQuery-объект
      @item()       # jQuery-объект
      @someProperty # 'foo'
      @fire( ... )  # Сгенерировать событие

# Получение экземпляра модуля (подробнее ниже)
instance = $('.super-puper').module 'SuperPuper'
instance.someMethod()
instance.list
instance.someProperty
```

## Инициализация

По умолчанию все модули автоматически инициализируются на элементах 
соответствующих корневому селектору. Для этого и нужен корневой селектор.

### `M.autoInit(boolean)`

Можно отключить этот механизм, вызвав эту функцию и передав ей ложь.

### Метод `initializer`

При создании экземпляра модуля, которое происходит при автоматической 
инициализации, и которое можно сделать вручную (`new MyModule( ... )`), 
происходит вызов метода модуля `initializer`, если такой есть. В этод метод
ничего не передается.

### `window.modules.init(moduleName)`

    TODO

### `window.modules.initAll()`

    TODO

## Настройки

    TODO

## Доступ к экземплярам модулей

Получить ссылку на экземпляр модуля можно множеством способов.

1. Создав модуль `%экземпляр% = new Module(...)`
2. Подписавшись на событие (см. События модулей)
3. Получить из корневого DOM элемента (подробнее ниже)
4. Через `window.modules.find()`

### `$(...).module(moduleName)`

    TODO

### `window.modules.find(moduleName)`

    TODO

## Утилиты

### `window.action(actionName, handler)`

    TODO

### `$(...).newHtml()`

    TODO

## API целиком

### Глобальные функции (`window.`)

 * [`window.module([name], callback)`](#windowmodulename-callback) — создание модуля
 * [`window.action(actionName, handler)`](#windowactionactionname-handler)

### В конструкторе (`M.`)

 * [`M.tree(treeOfElements)`](#mtreetreeofelements) — описание элементов
 * [`M.root(selector)`](#mrootselector-%D0%B8-melementselector-namenull-dynamicfalse-globalfalse) — указание корневого селектора
 * [`M.element(selector, name=null, dynamic=false, global=false)`](#mrootselector-%D0%B8-melementselector-namenull-dynamicfalse-globalfalse) — добавление элемента
 * [`M.evets(eventsDescription)`](#mevetseventsdescription) — описание событий
 * [`M.event(eventName, elementName, handler)`](#mevetseventsdescription) — добавление события
 * [`M.moduleEvents(moduleEventsDescription)`](#mmoduleeventsmoduleeventsdescription)
 * [`M.moduleEvent(eventName, moduleName, handler)`](#mmoduleeventeventname-modulename-handler)
 * [`M.methods(object)`](#mmethodsobject)
 * [`M.autoInit(boolean)`](#mautoinitboolean)

### В экземпляре модуля (`@`)
 
 * `@root`
 * `@%element_name%`
 * `@%dynamic_element_name%()`
 * `@find(...)` — алиас для `@root.find(...)`
 * `@updateTree()`
 * `@%method_name%()`
 * [`@on(eventName, handler)`](#module_instanceoneventname-handler)
 * [`@off(eventName, handler)`](#module_instanceoffeventname-handler)
 * [`@fire(eventName, data)`](#module_instancefireeventname-data)
 * `@settings`
 * `@setOption(name, value)`

### %Придумать название% `window.modules.`
 
 * [`.on(eventName, moduleName, handler)`](#windowmodulesoneventname-modulename-handler)
 * [`.off(eventName, moduleName, handler)`](#windowmodulesoffeventname-modulename-handler)
 * [`.find(moduleName)`](#windowmodulesfindmodulename)
 * [`.init(moduleName)`](#windowmodulesinitmodulename)
 * [`.initAll()`](#windowmodulesinitall)

### Плагины jQuery `$(...).`
 
 * [`.module(moduleName)`](#modulemodulename)
 * [`.newHtml()`](#newhtml)
