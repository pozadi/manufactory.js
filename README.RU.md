# Зачем?

- Порядок в коде
- Упрощение работы с DOM
- Упрощение инициализации
- Упрощение и стандартизация общения между модулями
- Модуль — независимая сущность, со всеми вытекающими

# Принципы

Модуль — это объект, точнее класс. Но модуль ≠ js-класс и объект модуля ≠ js-объект (хотя ...)

Модуль независим, его границы очевидны, а не висят в воздухе как негласная договоренность.
Четко видно где модули общаются.

Ниша: среднее количество js — backbone/knockout рано, но что-то уже нужно.

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

# В билдере

    M.defaultSettings()
    M.tree()
    M.events()
    M.globalEvents()
    M.modulesEvents()
    M.methods()
    M.init()

# В объекте модуля

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

# Чего не будет

- создания jquery-плагина из модуля
- модули с множественными корнями
- пометка метода как tree-updater

# CSS-селектор → имя атрибута

- `div` — `div`  
- `@button` — `button`
- `.button` — `button`
- `@button a` — `buttonA`
- `@my-button` — `myButton`
- `input[type=text]` — `inputTypeText`

Split to words (delimetr is all not letters and not digits characters) then join words in mixedCase notation.

