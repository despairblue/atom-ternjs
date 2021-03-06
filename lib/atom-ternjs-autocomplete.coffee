apd = require 'atom-package-dependencies'

module.exports =
class AtomTernjsAutocomplete

    exclusive: true
    client: null
    suggestionsArr = null
    currentSuggestionIndex: null
    disposables: null
    documentationView = null
    maxItems = null
    # automcomplete-plus
    autocompletePlus = null
    id: 'atom-ternjs-provider'
    selector: '.source.js'
    blacklist: '.source.js .comment'

    init: (client, documentationView) ->
        atom.packages.activatePackage('autocomplete-plus')
          .then (pkg) =>
            @autocompletePlus = apd.require('autocomplete-plus')
            @registerEvents()
        @disposables = []
        @suggestionsArr = []
        @currentSuggestionIndex = 0
        @client = client
        @documentationView = documentationView

    requestHandler: (options) ->
        return [] unless options?.editor? and options?.buffer? and options?.cursor?
        prefix = options.prefix

        if prefix.endsWith(';') or prefix.indexOf('..') != -1 or !prefix.length
            @documentationView.hide()
            return []

        that = this

        return new Promise (resolve) ->
            that.client.update(options.editor.getURI(), options.editor.getText()).then =>
                that.client.completions(options.editor.getURI(), {line: options.position.row, ch: options.position.column}).then (data) =>
                    that.suggestionsArr = []
                    that.currentSuggestionIndex = 0
                    if !data.completions.length
                        resolve([])
                        that.documentationView.hide()
                        return
                    if data.completions.length is 1 and data.completions[0].name.replace('$', '') is prefix
                        resolve(that.suggestionsArr)
                        that.documentationView.hide()
                        return
                    for obj, index in data.completions
                        if index == maxItems
                            break
                        that.suggestionsArr.push {

                            word: obj.name,
                            prefix: prefix,
                            label: obj.type,
                            renderLabelAsHtml: false,
                            className: null,
                            _ternDocs: obj.doc,
                            onWillConfirm: ->
                                if prefix.endsWith('.')
                                    this.word = this.prefix + this.word
                            onDidConfirm: ->
                        }
                    resolve(that.suggestionsArr)
                    that.setDocumentationContent()
                , (err) ->
                    console.log err

    setDocumentationContent: ->
        return unless @suggestionsArr.length
        @documentationView.setTitle(@suggestionsArr[@currentSuggestionIndex].word, @suggestionsArr[@currentSuggestionIndex].label)
        @documentationView.setContent(@suggestionsArr[@currentSuggestionIndex]._ternDocs)
        @documentationView.show()

    forceCompletion: ->
        @autocompletePlus.autocompleteManager.runAutocompletion()

    forceCancel: ->
        @autocompletePlus.autocompleteManager.hideSuggestionList()

    hideDocumentation: ->
        @documentationView.hide()

    getMaxIndex: ->
        Math.min(maxItems, @suggestionsArr.length)

    addSelector: (selector) ->
        @selector = @selector + ',' + selector

    removeSelector: (selector) ->
        @selector = @selector.replace(',' + selector, '')

    registerEvents: ->
        @disposables.push atom.config.observe('autocomplete-plus.maxSuggestions', => maxItems = atom.config.get('autocomplete-plus.maxSuggestions'))
        @disposables.push atom.workspace.onDidChangeActivePaneItem =>
            @hideDocumentation()
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-cancel', =>
            @hideDocumentation()
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-confirm', =>
            @hideDocumentation()
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-select-next', =>
            if ++@currentSuggestionIndex >= @getMaxIndex()
                @currentSuggestionIndex = 0
            @setDocumentationContent()
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-select-previous', =>
            if --@currentSuggestionIndex < 0
                @currentSuggestionIndex = @getMaxIndex() - 1
            @setDocumentationContent()

    unregisterEvents: ->
        for disposable in @disposables
            disposable.dispose()
        @disposables = []

    cleanup: ->
        @documentationView.hide()
        @unregisterEvents()
