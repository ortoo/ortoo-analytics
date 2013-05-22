models = require './models'
util = require 'util'
sentinel = require 'redis-sentinel'
redis = require 'redis'
mongoose = require 'mongoose'
winston = require 'winston'

class AnalyticsService

    constructor: (opts) ->
        opts or= {}

        # Default to 1m for the reap interval
        @reapInterval = opts.reapInterval or 60000
        @redisCollectionKey = opts.redis.collectionKey or 'analytics:events'

        # Setup our connections
        @_setupConnections opts

        if opts.reap
            setInterval @reap.bind(@), @reapInterval

    _setupConnections: (opts) ->
        {Event} = models opts.mongooseConnectionString
        @Event = Event
        sentinelEndpoints = opts.redis.sentinelEndpoints
        masterName = opts.redis.sentinelMasterName or 'mymaster'
        redisServerDetails = opts.redis.serverDetails
        if sentinelEndpoints
            @redisClient = sentinel.createClient sentinelEndpoints, masterName, {role: 'master'}
        else
            @redisClient = redis.createClient redisServerDetails.port, redisServerDetails.host

    newEvent: (data, callback) ->

        # Check that we have the required properties
        unless data.eventName? and data.context?
            throw new Error "Expected context and eventName for event data: #{util.inspect data}"

        # Create the date and an objectId
        data.time = new Date()
        data._id = new mongoose.Types.ObjectId()

        jsonData = JSON.stringify data

        # We store the data as a json string in a sorted set (sorted by time)
        @redisClient.zadd @redisCollectionKey, data.time.getTime(), jsonData, (err, result) ->
            callback? err


    reap: ->
        # The data we reap is the data from now to all times in the past
        now = new Date().getTime()
        @redisClient.zrangebyscore @redisCollectionKey, 0, now, (err, members) =>
            if err then return winston.error err.stack, err

            # Move the results over to mongodb
            members.forEach (member) =>
                @Event.create JSON.parse(member), (err) ->
                    if err then return winston.error err.stack, err

            # Delete the redis batch
            if members.length isnt 0
                @redisClient.zremrangebyscore @redisCollectionKey, 0, now, (err) ->
                    if err then return winston.error err.stack, err


module.exports.initialize = (opts) ->
    # Service is globally available for the module
    service = new AnalyticsService opts

    # Setup our exported properties
    module.exports.Event = service.Event
    module.exports.newEvent = service.newEvent.bind(service)
    return service
