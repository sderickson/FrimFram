module.exports =
  id: 'http://my.site/schemas#'
  definitions:
  
    #- common
    metaSchema: require './common/meta.schema'
    objectId: require './common/objectId.schema'
    
    
    #- models
    user: require './models/user.schema'