"use strict"

isString = (val) -> typeof val is 'string'
isArray = (val) -> typeof val is 'array'
extend = (target, source) -> target[k]=v for k, v of source; target

class CypherQuery
  PARTS = [ 'start', 'match', 'where', 'with'
            'set', 'delete', 'forach', 'return'
            'union', 'union all'
            'order by', 'limit', 'skip' ]
  
  constructor: (opt) ->
    return new CypherQuery opt unless this?

    @_params = {}
    @_query = {}
    @[key] ([].concat val)... for key, val of opt  if opt?

  toString: ->
    (for key in PARTS when (val = @_query[key])?
      joiner = if key is 'where' then ' AND ' else ', '
      key.toUpperCase() + ' ' + val.join joiner
    ).join "\n"

  execute: (db, cb) -> db.query @toString(), @_params, cb

  params: (params) ->
    if params?
      extend @_params, params
      this
    else @_params

  part_builder = (key) -> (vals...) ->
    @params vals.pop() unless isString vals[vals.length-1]

    unless @_query[key]? then @_query[key] = vals
    else @_query[key].push vals...

    this

  @::[k] = part_builder k for k in PARTS

  index: (index, expr, params) -> @start "n=#{index}(#{expr})", params

  autoindex: (expr, params) -> @index 'node:node_auto_index', expr, params

  @install: (target = require 'neo4j/lib/GrpahDatabase') ->
    target::builder= (opt) ->
      query = new CypherQuery opt
      query.execute = query.execute.bind query, this
      query


module.exports = CypherQuery
