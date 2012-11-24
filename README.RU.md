# Принципы

Стандартизация, Декомпозиция, Самодокументируемость.

Модуль — это класс объектов, объектов модуля. Это почти то же, что js-класс и js-объект, но с небольшими дополнениями. Каждый модуль содержит в себе js-класс, а каждый объект модуля — js-объект.

# Когда стоит применять?

Библиотеку разумно применять на средних и больших проектах, со средним количеством JavaScript.
Можно применять и на проектах с небольшим количеством JavaScript с целью повторного использования модулей.
Если ваш проект полностью построен на JavaScript лучше попробовать Backbone, Knockout или что-то подобное.

# Что вы получите?

- Разбиение кода на независимые модули
- Упрощение инициализации
- Упрощение работы с элементами DOM и событиями
- Средства общения сежду модулями
- Самодокументируемый код
- Управление зависимостями (порядком инициализации)
- В добавок различные мелкие плюшки

# Состав
  
- Элементы
  - Статические
  - Динамические
- События
  - DOM-события на элементах модуля
  - DOM-события на внешних элементах — "глобальные"
  - События модулей
- Инициализация
  - При загрузке
  - Ленивая
- Настройки
  - Дефолтные
  - В data-атрибутах у корневого элемента
  - При создании объекта модуля вручную
- Вспомогательные функции
  - см. API

# API

## В билдере

    M.defaultSettings %object%
    M.tree %multiline_string%
    M.events %multiline_string%
    M.globalEvents %multiline_string% or %object% ???
    M.modulesEvents %multiline_string%
    M.methods %object%
    M.init %string%
    M.dependsOn %string[, %string[, ...]]
    M.extends %string%
    M.eventPrefix %string%

## В объекте модуля

    @root
    @find()
    @%element_name%
    @%dynamic_element_name%()
    @updateTree()

    @on()
    @off()
    @fire()

    @%method_name%()

    @settings
    @setOption()

## В window

    .module %module_name%, ->
    .modules
      .bind %module_name%, %event_name%, ->
      .find %module_name%
      .initAll()
    .action '%controller%#%action%', ->

## В $.fn

    .module %module_name% # возвращает массив объектов модулей
    .htmlIserted() # провоцирует вызовы initAll() и updateTree()


# CSS-селектор → имя атрибута

- `div` — `div`  
- `@button` — `button`
- `.button` — `button`
- `@button a` — `buttonA`
- `@my-button` — `myButton`
- `input[type=text]` — `inputTypeText`

Split to words (delimetr is all not letters and not digits characters) then join words in mixedCase notation.

