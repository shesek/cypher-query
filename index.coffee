"use strict"
extend = (target, source) -> target[k]=v for k, v of source; target

RESERVED = [ 'start', 'create', 'set', 'delete', 'foreach', 'match', 'where', 'with'
             'return', 'skip', 'limit', 'order', 'by', 'asc', 'desc', 'on', 'when',
             'case', 'then', 'else', 'drop', 'using', 'merge', 'constraint', 'assert'
             'scan', 'remove', 'union' ]
INVALID_IDEN = /\W/

QUERY_PARTS = [ 'start', 'match', 'where', 'with', 'set', 'delete', 'forach', 'return'
                'union', 'union all', 'order by', 'limit', 'skip' ]
class CypherQuery
  constructor: (opt) ->
    return new CypherQuery opt unless this?

    @_params = {}
    @_query = {}
    @[key] ([].concat val)... for key, val of opt  if opt?

  toString: ->
    (for key in QUERY_PARTS when (val = @_query[key])?
      joiner = if key is 'where' then ' AND ' else ', '
      key.toUpperCase() + ' ' + val.join joiner
    ).join "\n"

  execute: (db, cb) -> db.query @toString(), @_params, cb
  compile: (with_params) ->
    unless with_params then @toString()
    else
      @toString().replace /\{(\w+)\}/g, (_, key) =>
        escape @_params[key] or throw new Error "Missing: #{key}"

  params: (params, val) ->
    if val?
      @_params[params] = val
      this
    else if params?
      extend @_params, params
      this
    else @_params

  part_builder = (key) -> (vals...) ->
    return @_query[key] unless vals.length
    @params vals.pop() unless typeof vals[vals.length-1] is 'string'
    unless @_query[key]? then @_query[key] = vals
    else @_query[key].push vals...
    this

  @::[k] = part_builder k for k in QUERY_PARTS
  ret: @::return
  orderBy: @::['order by']

  index: (index, expr, params) -> @start "n=#{index}(#{expr})", params

  autoindex: (expr, params) -> @index 'node:node_auto_index', expr, params

  @install: (target = require 'neo4j/lib/GraphDatabase') ->
    target::builder = (opt) ->
      query = new CypherQuery opt
      query.execute = query.execute.bind query, this
      query

  @escape: escape = (val) -> switch typeof val
    when 'boolean' then val ? 'true' : 'false'
    when 'number' then val
    else '"' + ((''+val).replace /"/g, '""') + '"'

  @escape_identifier: escape_identifier = (name) ->
    if name.toLowerCase() in RESERVED or INVALID_IDEN.test name
      '`' + (name.replace '`', '``') + '`'
    else name

  @pattern: do (
    patterns = out: '-%s->', in: '<-%s-', all: '-%s-'
    length_re = /^(?:\d+)?(?:\.\.)?(?:\d+)?$/
  ) ->
    ({ type, direction, alias, optional, length }) ->
      rel_str = if type? or alias? or optional
        '[' + \
        (if alias? then escape_identifier alias else '') + \
        (if optional then '?' else '') + \
        (if type? then ':' + escape_identifier type else '') + \
        (if length? and (length_re.test length) then '*' + length else '') + \
        ']'
      else ''

      (patterns[direction or 'all'] or throw new Error 'Invalid direction')
        .replace('%s', rel_str)

module.exports = CypherQuery
