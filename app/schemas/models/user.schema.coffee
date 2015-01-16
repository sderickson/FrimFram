module.exports =
  id: '#user'
  required: ['name', 'email']
  properties:
    _id: {$ref: 'schemas#objectId'}
    name: { type: 'string', minLength: 1 }
    slug: { type: 'string', minLength: 1 }
    email: { type: 'email', format: 'email', minLength: 5 }
  additionalProperties: false 