// Generated by CoffeeScript 1.6.2
(function() {
  var AnalyticsService, Event, conn, models, mongoose, pendingNewEvents, redis, sentinel, util, winston,
    __slice = [].slice;

  models = require('./models');

  util = require('util');

  sentinel = require('redis-sentinel');

  redis = require('redis');

  mongoose = require('mongoose');

  winston = require('winston');

  Event = models.Event, conn = models.conn, mongoose = models.mongoose;

  pendingNewEvents = [];

  AnalyticsService = (function() {
    function AnalyticsService(opts) {
      opts || (opts = {});
      this.reapInterval = opts.reapInterval || 60000;
      this.redisCollectionKey = opts.redis.collectionKey || 'analytics:events';
      this._setupConnections(opts);
      if (opts.reap) {
        setInterval(this.reap.bind(this), this.reapInterval);
      }
    }

    AnalyticsService.prototype._setupConnections = function(opts) {
      var masterName, redisServerDetails, sentinelEndpoints;

      models.open(opts.mongooseConnectionString);
      sentinelEndpoints = opts.redis.sentinelEndpoints;
      masterName = opts.redis.sentinelMasterName || 'mymaster';
      redisServerDetails = opts.redis.serverDetails;
      if (sentinelEndpoints) {
        return this.redisClient = sentinel.createClient(sentinelEndpoints, masterName, {
          role: 'master'
        });
      } else {
        return this.redisClient = redis.createClient(redisServerDetails.port, redisServerDetails.host);
      }
    };

    AnalyticsService.prototype.newEvent = function(data, callback) {
      var jsonData;

      if (!((data.eventName != null) && (data.context != null))) {
        throw new Error("Expected context and eventName for event data: " + (util.inspect(data)));
      }
      data.time = new Date();
      data._id = new mongoose.Types.ObjectId();
      jsonData = JSON.stringify(data);
      return this.redisClient.zadd(this.redisCollectionKey, data.time.getTime(), jsonData, function(err, result) {
        return typeof callback === "function" ? callback(err) : void 0;
      });
    };

    AnalyticsService.prototype.reap = function() {
      var now,
        _this = this;

      now = new Date().getTime();
      return this.redisClient.zrangebyscore(this.redisCollectionKey, 0, now, function(err, members) {
        if (err) {
          return winston.error(err.stack, err);
        }
        members.forEach(function(member) {
          return Event.create(JSON.parse(member), function(err) {
            if (err) {
              return winston.error(err.stack, err);
            }
          });
        });
        if (members.length !== 0) {
          return _this.redisClient.zremrangebyscore(_this.redisCollectionKey, 0, now, function(err) {
            if (err) {
              return winston.error(err.stack, err);
            }
          });
        }
      });
    };

    return AnalyticsService;

  })();

  module.exports.initialize = function(opts) {
    var newEventArgs, service, _i, _len;

    service = new AnalyticsService(opts);
    module.exports.newEvent = service.newEvent.bind(service);
    for (_i = 0, _len = pendingNewEvents.length; _i < _len; _i++) {
      newEventArgs = pendingNewEvents[_i];
      service.newEvent.apply(service, newEventArgs);
    }
    pendingNewEvents.length = 0;
    return service;
  };

  module.exports.newEvent = function() {
    var args;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    pendingNewEvents.push(args);
  };

  module.exports.Event = Event;

  module.exports.conn = conn;

  module.exports.mongoose = mongoose;

}).call(this);
