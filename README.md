# octiron

*Octiron is an event bus with the ability to magically transform events.*

Events octiron responds to can be any classes or Hash prototypes. Using
transmogrifiers, events can be turned into other kinds of events
transparently.

[![Gem Version](https://badge.fury.io/rb/octiron.svg)](https://badge.fury.io/rb/octiron)
[![Build status](https://travis-ci.org/jfinkhaeuser/octiron.svg?branch=master)](https://travis-ci.org/jfinkhaeuser/octiron)
[![Code Climate](https://codeclimate.com/github/jfinkhaeuser/octiron/badges/gpa.svg)](https://codeclimate.com/github/jfinkhaeuser/octiron)
[![Test Coverage](https://codeclimate.com/github/jfinkhaeuser/octiron/badges/coverage.svg)](https://codeclimate.com/github/jfinkhaeuser/octiron/coverage)

# Usage

So what does this all mean?

## Fundamentals

First of all, the gem contains a publish/subscribe event bus, which easily
allows you to subscribe handlers to events of a particular class:

```ruby
require 'octiron'

class MyEvent
  # ...
end

include Octiron::World

on_event(MyEvent) do |event|
  # event.is_a?(MyEvent) == true
  # do something with the event
end
```

You can subscribe as many handlers to an event class as you want.

Next, you can transmogrify objects - typically events. Similar to suscribing
event handlers, you can register transmogrifiers for a particular
transmogrification.

```ruby
class AnotherEvent
end

on_transmogrify(MyEvent).to AnotherEvent do |my_event|
  # guaranteed: my_event.is_a?(MyEvent) == true
  AnotherEvent.new
end
```

As long as the transmogrifier returns an object of the `AnotherEvent` type,
all is well. Otherwise, an exception is raised.

Putting this together with the hitherto unmentioned `#publish` method, you can
easily build processing pipelines.

```ruby
on_transmogrify(MyEvent).to AnotherEvent do |my_event|
  # do something more meaningful
  AnotherEvent.new
end

on_event(MyEvent) do |event|
  publish transmogrify(event).to AnotherEvent
end

on_event(AnotherEvent) do |event|
  # We'll end up here with the transmogrified event
end

publish MyEvent.new
```

## Advanced Usage

There are some more advanced topics that might be useful to understand.

### Automatic Transmogrification

When you write a lot of transmogrifiers, chances are your event handlers all
look roughly the same:

```ruby
on_event(SourceEvent) do |event|
  begin
    new_event = transmogrify(event).to AnotherEvent
    publish(new_event)
  rescue RuntimeError
  end
end
```

This event handler pattern *tries* to transmogrify the source event to another
type, and on success will publish the result. On failure, it just wants to
swallow the event.

This pattern is supported with the `#autotransmogrify` function:

```ruby
autotransmogrify(SourceEvent) do |event|
  if not some_condition
    next
  end
  AnotherEvent.new
end
```

Your transmogrifier is installed as previously, and additionally an event handler
is registered that follows the pattern above. If the transmogrifier returns
no new event, that is silently accepted.

You can use `#autotransmogrify` and still raise errors, of course:

```ruby
autotransmogrify(SourceEvent, raise_on_nil: true) do |_|
  # do nothing
end

publish(SourceEvent.new) # will raise RuntimeError
```

### Singletons vs. API

The octiron gem exposes a number of simple wrapper functions we've used so far
to hide the API complexity a little. These wrapper functions make use of a
singleton event bus instance, and a singleton transmogrifier registry:

- `#on_event` delegates `Octiron::Events::Bus#subscribe`
- `#publish` delegates `Octiron::Events::Bus#publish`
- `#on_transmogrify` delegates to `Octiron::Transmogrifiers::Registry#register`
- `#transmogrify` delegates to `Octiron::Transmogrifiers::Registry#transmogrify`

You can just as well use these underlying API functions with multiple instances
of the event bus or the transmogrifier registry.

### Hash Prototypes

The octiron gem implements something of a prototyping mechanic for using Hashes
as events, but also as sources and targets of transmogrification. If the event
bus would register handlers for the Hash class, all Hashes would trigger the
same handlers (and similar for the transmogrifier registry).

Instead, where you would normally provide classes (e.g. `#on_event`), you can
specify a Hash that acts as a prototype. Then, where you would normally use
instances (e.g. `#publish`), you can provide a Hash again. If that published
Hash matches the prototype Hash, the handler associated with the prototype is
triggered.

So how does this matching work?

- If a prototype specifies a key without value (i.e. a nil value), the published
  instance *must* contain the key, but the value or value type is ignored.
- If a prototype specifies a key with a value, the published instance *must*
  contain the key, and it's value *must* match the respective value in the
  prototype.

```ruby
proto1 = {
  a: nil,
}

proto2 = {
  b: 42,
}

published1 = {
  a: 'foo',
}
# published1 matches proto1, but not proto2

published2 = {
  b: 42,
}
# published2 matches proto2, but not proto1
```

Hash prototyping is supported both for subscribing event handlers, and
registering transmogrifiers, allowing for something of the following:

```ruby
on_transmogrify(proto1).to proto2 do |event|
  x = event.dup
  x.delete(:a)
  x[:b] = 42
  x
end

on_event(proto1) do |event|
  publish transmogrify(event).to proto2
end

on_event(proto2) do |event|
  # we'll end up here
end

publish published1
```

*Note* that you can produce closed loops by publishing events from within event
handlers. In the above example, if the transmogrifier did not delete the `:a`
key from the newly created event, it would still match the `proto1` prototype,
which would trigger that handler and the transmogrifier again and again.
