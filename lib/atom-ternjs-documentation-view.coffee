module.exports =
class DocumentationView

  @title = null
  @sub = null
  @content = null
  @allowed = false
  @active = false

  constructor: (serializeState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('atom-ternjs-doc')

    # Create child elements
    @title = document.createElement('h1')
    @sub = document.createElement('h2')
    @content = document.createElement('p')

    @element.appendChild(@title)
    @element.appendChild(@sub)
    @element.appendChild(@content)

    @registerEvents()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  registerEvents: ->
    @element.addEventListener 'webkitTransitionEnd', =>
      return unless !@active
      @element.classList.remove('visible')

  toggle: ->
    @element.classList.toggle('active')

  show: ->
    return unless @allowed
    @active = true
    @element.classList.add('visible')
    @element.classList.add('active')

  hide: ->
    @active = false
    @element.classList.remove('active')

  setTitle: (name, params) ->
    return unless name
    @title.innerHTML = name
    @sub.innerHTML = params

  setContent: (str) ->
    if str
      @allowed = true
      str = str.replace(/(?:\r\n|\r|\n)/g, '<br />')
      @content.innerHTML = str
    else
      @allowed = false
      @content.innerHTML = ''
      @hide()

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
