ortoo-analytics
===============

Analytics collector

Events are immediately stored into redis, before being periodically saved into mongodb

## Initialization ##

```javascript
analytics.initialize(opts);
```

Opts:

* `reapInterval` - period in ms between transfer from redis to mongodb
* `mongooseConnectionString`
* `redisConnectionString`

## API ##

```javascript
analytics.newEvent(data);
```

Data can contain any properties (with the exception of `time`) and they will be persisted. However there are some standard and compulsory properties

**Compulsory properties**

* context - where we've collected the data from (e.g. 'Server', 'GovernorHub client')
* eventName - e.g 'NewNoticeboardPost'

**Standard properties**

* object - the ID of the object the event is happening to (if applicable)
* objectType - a string type for the object. Recommended for grouping of objects (e.g. 'NoticeboardPost')
* user - the ID of the user who triggered the event (if applicable)
* container - the ID of the object's container (if applicable - e.g. the group a 'NoticeboardPost' belongs to)
* containerType - a string type for the container
