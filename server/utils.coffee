module.exports =
  isMongoDBID: (id) -> _.isString(id) and id.length is 24 and id.match(/[a-f0-9]/gi)?.length is 24
    
  getByHandle: (Model, handle, next) ->
    if @isMongoDBID(handle)
      Model.findById(handle).exec(next)
    else
      Model.findOne({slug: handle}).exec(next)
