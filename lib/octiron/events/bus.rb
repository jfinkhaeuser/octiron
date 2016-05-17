# coding: utf-8
#
# octiron
# https://github.com/jfinkhaeuser/octiron
#
# Copyright (c) 2016 Jens Finkhaeuser and other octiron contributors.
# All rights reserved.
#

require 'octiron/support/camel_case'
require 'octiron/support/constantize'

require 'collapsium/recursive_sort'
require 'collapsium/prototype_match'

module Octiron::Events

  ##
  # Implements and in-process pub-sub events broadcaster allowing multiple
  # observers to subscribe to different events.
  class Bus
    ##
    # @param default_namespace (Symbol) The default namespace to look in for
    #     Event classes.
    def initialize(default_namespace)
      @default_namespace = default_namespace.to_s
      @handlers = {}
    end

    ##
    # Subscribe an event handler to an event.
    # @param event_id (Class, String, other) A class or String naming an event
    #     class.
    # @param handler_object (Object) Handler object that must implement a
    #     `#call` method accepting an instance of the event class provided in
    #     the first parameter. If nil, a block needs to be provided.
    # @param handler_proc (Proc) Handler block that accepts an instance of the
    #     event class provided in the first parameter. If nil, a handler object
    #     must be provided.
    # @return The class represented by the event_id, as a String name.
    def subscribe(event_id, handler_object = nil, &handler_proc)
      handler = handler_proc || handler_object
      if not handler
        raise ArgumentError, "Please pass either an object or a handler block"
      end
      event_name = parse_event_id(event_id)

      handlers_for(event_name, true) << handler

      return event_name
    end
    alias register subscribe

    ##
    # Unsubscribe an event handler from an event.
    # @param event_id (Class, String, other) A class or String naming an event
    #     class.
    # @param handler_object (Object) Handler object that must implement a
    #     `#call` method accepting an instance of the event class provided in
    #     the first parameter. If nil, a block needs to be provided.
    # @param handler_proc (Proc) Handler block that accepts an instance of the
    #     event class provided in the first parameter. If nil, a handler object
    #     must be provided.
    # @return The class represented by the event_id, as a String name.
    def unsubscribe(event_id, handler_object = nil, &handler_proc)
      handler = handler_proc || handler_object
      if not handler
        raise ArgumentError, "Please pass either an object or a handler block"
      end
      event_name = parse_event_id(event_id)

      handlers_for(event_name, true).delete(handler)

      return event_name
    end

    ##
    # Broadcast an event. This is an instance of a class provided to #subscribe
    # previously.
    # @param event (Object) the event to publish
    def publish(event)
      event_name = event
      if not event.is_a?(Hash)
        event_name = event.class.to_s
      end
      handlers_for(event_name, false).each do |handler|
        handler.call(event)
      end
    end
    alias broadcast publish
    alias notify publish

    private

    # The first parameters is the event class or event name. The second parameter
    # is whether this is for write or read access. We don't want to pollute
    # @handlers with data from the #publish call.
    def handlers_for(name, write)
      # Use prototype matching for Hash names
      if name.is_a?(Hash)
        name.extend(::Collapsium::PrototypeMatch)

        # Check for prototype matches
        @handlers.keys.each do |proto|
          if name.prototype_match(proto)
            return @handlers[proto]
          end
        end

        # No prototype matches. That means if write is true, we need to treat
        # name as a new prototype to regiser. Otherwise, we need to return an
        # empty list. That happens to be the same logic as for the simple key
        # below.
      end

      # If we're in write access, make sure to store an empty list as well as
      # returning one (if necessary).
      if write
        @handlers[name] ||= []
      end

      # In read access, want to either return an empty list, or the registered
      # handlers, but not ovewrite the registered handlers.
      return @handlers[name] || []
    end

    include ::Octiron::Support::CamelCase
    include ::Octiron::Support::Constantize

    def parse_event_id(event_id)
      case event_id
      when Class
        return event_id.to_s
      when Hash
        return event_id
      when String
        return constantize(event_id).to_s
      else
        return constantize("#{@default_namespace}::#{camel_case(event_id)}").to_s
      end
    end
  end # class Bus
end # module Octiron::Events
