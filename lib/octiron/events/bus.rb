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
    # @return  FIXME
    def subscribe(event_id, handler_object = nil, &handler_proc)
      handler = handler_proc || handler_object
      if not handler
        raise ArgumentError, "Please pass either an object or a handler block"
      end
      event_class = parse_event_id(event_id)

      handlers = @handlers.fetch(event_class.to_s, [])
      handlers << handler
      @handlers[event_class.to_s] = handlers

      return event_class
    end
    alias register subscribe

    ##
    #
    def unsubscribe(event_id, handler_object = nil, &handler_proc)
      handler = handler_proc || handler_object
      if not handler
        raise ArgumentError, "Please pass either an object or a handler block"
      end
      event_class = parse_event_id(event_id)

      handlers = @handlers.fetch(event_class.to_s, [])
      handlers -= [handler]
      @handlers[event_class.to_s] = handlers

      return event_class
    end

    ##
    # TODO document
    # Broadcast an event
    def publish(event)
      # TODO: add Hash prototype support
      handlers = @handlers.fetch(event.class.to_s, [])
      handlers.each do |handler|
        handler.call(event)
      end
    end
    alias broadcast publish
    alias notify publish

    private

    include ::Octiron::Support::CamelCase
    include ::Octiron::Support::Constantize

    def parse_event_id(event_id)
      # TODO: add Hash prototype support
      case event_id
      when Class
        return event_id
      when String
        return constantize(event_id)
      else
        return constantize("#{@default_namespace}::#{camel_case(event_id)}")
      end
    end
  end # class Bus
end # module Octiron::Events
