mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.Types.ObjectId

EventSchema = new Schema {
    time: {type: Date, required: true}
    eventName: {type: String, required: true}

    user: ObjectId

    object: ObjectId
    objectType: String

    container: ObjectId
    containerId: String
}, { strict: false }

module.exports = (connectionStr) ->
    conn = mongoose.createConnection connectionStr
    Event = conn.model 'Event', EventSchema

    return {
        Event
    }