"use strict"

isString = (val) -> typeof val is 'string'
extend = (target, source) -> target[k]=v for k, v of source; target

class CypherQuery
  PARTS = [ 'start', 'match', 'where', 'with', 'return'
            'union', 'union all'
            'order by', 'limit', 'skip', ]
  
  constructor: (parts) ->
    return new CypherQuery parts unless this?

    if parts?.params?
      @params = parts.params
      delete parts.params
    else @params = {}

    @parts = if parts?
      parts[key] = [ val ] for key, val of parts when isString val
      parts
    else {}

  execute: (db, cb) -> db.query @toString(), @params, cb
  toString: -> compile @parts

  set: (params) -> extend @params, params; this

  part_builder = (key) -> (vals..., params) ->
    if params?
      if isString params then vals.push params
      else extend @params, params

    unless @parts[key]? then @parts[key] = vals
    else @parts[key].push vals...

    this

  @::[k] = part_builder k for k in PARTS

  index: (index, expr, params) -> @start "n=#{index}(#{expr})", params

  autoindex: (expr, params) -> @index 'node:node_auto_index', expr, params

  @install: (target = require 'neo4j/lib/GrpahDatabase') ->
    target::builder= (parts) ->
      query = new CypherQuery parts
      query.execute = query.execute.bind query, this
      query

  @compile: compile = (parts) ->
    parts.return ?= [ 'n' ]
    (for key in PARTS when (val = parts[key])?
      joiner = if key is 'where' then ' AND ' else ', '
      key.toUpperCase() + ' ' + val.join joiner
    ).join "\n"

module.exports = CypherQuery
