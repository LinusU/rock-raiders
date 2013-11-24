
WS = [' ', '\t', '\r', '\n']

STATE_NONE = 0
STATE_KEY = 1
STATE_WS = 2
STATE_VAL = 3

STATE_NO = 0
STATE_MAYBE = 1
STATE_YES = 2

REGEX_NUM = /^\-?[0-9\.]+$/

class CFGParser
  constructor: ->
    @state = STATE_NONE
    @comment = STATE_NO
    @root = { _parent: null }
    @obj = @root
    @key = ''
    @val = ''
  write: (chunk) ->

    formatVal = (val) ->
      if val is 'TRUE'
        true
      else if val is 'FALSE'
        false
      else if REGEX_NUM.test val
        parseFloat val
      else
        val

    saveKeyVal = =>
      @obj[@key] = formatVal @val
      @key = ''
      @val = ''

    startBlock = =>
      parent = @obj
      @obj = {}
      Object.defineProperty @obj, '_parent', { enumerable: false, configurable: true, value: parent }
      parent[@key] = @obj
      @key = ''

    stopBlock = =>
      @obj = @obj._parent

    parseChar = (c) =>
      switch @state
        when STATE_NONE

          if c is '}'
            stopBlock()
            @state = STATE_NONE
          else if c not in WS
            @state = STATE_KEY
            @key = c

        when STATE_KEY

          if c in WS
            @state = STATE_WS
          else
            @key += c

        when STATE_WS

          if c is '{'
            startBlock()
            @state = STATE_NONE
          else if c not in WS
            @state = STATE_VAL
            @val = c

        when STATE_VAL

          if c in WS
            saveKeyVal()
            @state = STATE_NONE
          else
            @val += c

    for c in chunk
      switch @comment
        when STATE_NO

          if c is ';'
            @comment = STATE_YES
          else if c is '/'
            @comment = STATE_MAYBE
          else
            parseChar c

        when STATE_MAYBE

          if c is ';'
            parseChar '/'
            @comment = STATE_YES
          else if c is '/'
            @comment = STATE_YES
          else
            parseChar '/'
            parseChar c
            @comment = STATE_NO

        when STATE_YES

          if c is '\n'
            @comment = STATE_NO


window.CFGParser = CFGParser
