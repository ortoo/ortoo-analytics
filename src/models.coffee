mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.Types.ObjectId

EventSchema = new Schema {
    time: {type: Date, required: true}
    eventName: {type: String, required: true}
    context: {type: String, required: true}

    user: ObjectId

    object: ObjectId
    objectType: String

    container: ObjectId
}, { strict: false }


conn = mongoose.createConnection()
Event = conn.model 'Event', EventSchema

rgxReplSet = /^.+,.+$/

module.exports = {
    Event
    conn
    mongoose
    open: (args...) ->
        if rgxReplSet.test args[0]
            conn.openSet args...
        else
            console.log 'connecting'
            conn.open args...

}