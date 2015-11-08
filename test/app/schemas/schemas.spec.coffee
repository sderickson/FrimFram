describe 'the app ajv object', ->
  
  it 'contains all schemas in the app/schemas folder', ->
    expect(app.ajv.getSchema('models/user.schema')).toBeDefined()
    expect(app.ajv.getSchema('common/objectId.schema')).toBeDefined()
    
    
describe '$rel linking between schemas', ->
  
  it 'works through links starting with "schemas#...", such as "schemas#objectId" in the User model schema', ->
    goodUser = { _id: '012345678901234567890123', name: 'foo', email: 'bar@foo.com' }
    expect(app.ajv.validate('models/user.schema', goodUser)).toBe(true)
      
    badUser = { _id: 'Not formatted like an ID at all!' }
    expect(app.ajv.validate('models/user.schema', badUser)).toBe(false)