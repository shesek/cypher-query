cypher = require './index.coffee'
{ equal: eq, deepEqual: deepEq, ok } = require 'assert'

describe 'CypherQuery', ->
  it 'works', ->
    eq cypher()
      .start('n=node(1)')
      .where('foo=1', 'bar=2')
      .match('n-->m', 'x<--n')
      .return('n')
      .return('m', 'x')
      .toString(),
    """
      START n=node(1)
      MATCH n-->m, x<--n
      WHERE foo=1 AND bar=2
      RETURN n, m, x
    """
  it 'uses the correct order', ->
    eq cypher().return('a').start('b').toString(), "START b\nRETURN a"

  it 'takes optional query object in cypher()', ->
    query = cypher(
      start: 'a'
      match: [ 'b', 'c' ]
      params: { d: 4 }
    ).where('d')
    
    eq query.toString(),
      """
      START a
      MATCH b, c
      WHERE d
      """
    deepEq query.params(), d: 4

  it 'collects the params', ->
    query = cypher()
      .start('n', n: 1)
      .where('foo={bar}', bar: 'bar')
      .where('baz={qux}', qux: 'qux')
      .params(corge: 'corge')
      .params('hello', 'world')
    deepEq query.params(), n: 1, bar: 'bar', qux: 'qux', corge: 'corge', hello: 'world'


  it 'executes the call on the database', (done) ->
    db = query: (query, params, cb) ->
      eq query, "START a\nRETURN b"
      deepEq params, a: 1, b: 2
      cb null, 'some result'
    cypher().start('a', a:1).return('b', b:2).execute db, (err, res) ->
      eq err, null
      eq res, 'some result'
      done()

  it 'can be installed to GraphDatabase::builder()', (done) ->
    class Graph then query: (query, params, cb) -> cb null, query, params
    cypher.install Graph
    ok Graph::builder?
    (new Graph).builder().start('a').execute (err, query, params) ->
      ok not err?
      eq query, "START a"
      deepEq params, {}
      done()

