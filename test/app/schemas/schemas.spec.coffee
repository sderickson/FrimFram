describe 'the global tv4 object', ->
  
  it 'contains a "root" schema', ->
    expect(tv4.getSchema('http://my.site/schemas')).toBeDefined()
    
  it 'contains other schemas in relation to schemas, such as the User model schema with the route "schemas#user"', ->
    expect(tv4.getSchema('http://my.site/schemas#user')).toBeDefined()
    
    
describe '$rel linking between schemas', ->
  
  it 'works through links starting with "schemas#...", such as "schemas#objectId" in the User model schema', ->
    userSchema = require 'schemas/models/user.schema'
    
    goodUser = { _id: '012345678901234567890123', name: 'foo', email: 'bar@foo.com' }
    expect(tv4.validate(goodUser, userSchema)).toBe(true)
      
    badUser = { _id: 'Not formatted like an ID at all!' }
    expect(tv4.validate(badUser, userSchema)).toBe(false)