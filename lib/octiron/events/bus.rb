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
    # Register an event handler for an event.
    # @param event_id (Class, String, other) A class or String naming an event
    #     class.
    # @param handler_object (Object) Handler object that must implement a
    #     `#call` method accepting an instance of the event class provided in
    #     the first parameter. If nil, a block needs to be provided.
    # @param handler_proc (Proc) Handler block that accepts an instance of the
    #     event class provided in the first parameter. If nil, a handler object
    #     must be provided.
    def register(event_id, handler_object = nil, &handler_proc)
      handler = handler_proc || handler_object
      if not handler
        raise ArgumentError, "Please pass either an object or a handler block"
      end
      event_class = parse_event_id(event_id)
      handlers_for(event_class) << handler
      return event_class
    end

    # Broadcast an event
    def notify(event)
      # TODO: add Hash prototype support
      handlers_for(event.class).each do |handler|
        handler.call(event)
      end
    end

    private

    include ::Octiron::Support::CamelCase
    include ::Octiron::Support::Constantize

    def handlers_for(event_class)
      @handlers[event_class.to_s] ||= []
    end

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
