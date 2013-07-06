Progressive Cypher query builder API. Represnts the query as an object
(a tiny wrapper around string expressions), allowing to pass it around
and mutate it.

Written in CoffeeScript.

This is alpha quality software. It has not been throughtfully tested.

### Install
`npm install cypher-query`

### Usage
```coffee
cypher = require 'cypher-query'

query = cypher()
  .start('n = node(*)')
  .where('n.name = {name}', name: 'Joe')
  .where('n.age > {age}')
  .params(age: 22)
  .return('n.email', 'n.age')

# Alternative API
query = cypher
  start: 'n = node(*)'
  where: [ 'n.name = {name}', 'n.age > {age}' ]
  return: [ 'n.email', 'n.age' ]
  params: { name: 'Joe', age: 22 }

# Compile with toString() or compile()
query.toString() # START n=node(*)
                 # WHERE n.name = {name} AND n.age > {age}
                 # RETURN n.email, n.age

# Use params() to get all the collected params
query.params() # { name: 'Joe', age: 22 }

# Compile with compile(true) to embed the params into the string
query.compile(true) # START n=node(*)
                    # WHERE n.name = 'Joe' and n.age > 22
                    # RETURN n.email, n.age
```
#### With [thingdom/node-neo4j](https://github.com/thingdom/node-neo4j)
```coffee
db = new neo4j.GraphDatabase
cypher = require 'cypher-query'

cypher().start('n=node(*)').execute db, (err, res) ->
cypher(start: 'n=node(*)').execute db, (err, res) ->

# Or install as db.builder()
cypher.install(db)
db.builder().start('n=node(4)').execute (err, res) ->
db.builder(start: 'n=node(4)').execute (err, res) ->

# Or install globally to GraphDatabase's prototype
cypher.install()
```

#### Utility methods
```coffee
# Escape strings
cypher.escape 'hello " world!' # "hello "" world!"

# Escape identifiers
cypher.escape_identifier 'some ` identifier' # `some `` identifier`
```

### License
MIT
