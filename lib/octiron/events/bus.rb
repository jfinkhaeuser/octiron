# coding: utf-8
#
# octiron
# https://github.com/jfinkhaeuser/octiron
#
# Copyright (c) 2016-2017 Jens Finkhaeuser and other octiron contributors.
# All rights reserved.
#

require 'octiron/support/identifiers'

require 'collapsium/recursive_sort'
require 'collapsium/prototype_match'

module Octiron::Events

  ##
  # Implements and in-process pub-sub events broadcaster allowing multiple
  # observers to subscribe to different events.
  class Bus
    # @return (String) the default namespace to search for events
    attr_reader :default_namespace

    # The default handler class
    DEFAULT_CLASS = 'octiron-default'.freeze

    ##
    # @param default_namespace (Symbol) The default namespace to look in for
    #     Event classes.
    def initialize(default_namespace = ::Octiron::Events)
      @default_namespace = default_namespace.to_s
      clear
    end

    ##
    # Clears all event handlers
    def clear
      @handlers = {}
    end

    ##
    # Subscribe an event handler to an event.
    # @param event_id (Class, String, other) A class or String naming an event
    #     class.
    # @param handler_object (Object) Handler object that must implement a
    #     `#call` method accepting an instance of the event class provided in
    #     the first parameter. If nil, a block needs to be provided.
    # @param handler_class (Object) An object describing the handler class; the
    #     default is DEFAULT_CLASS. Handlers are executed sorted by handler class,
    #     so the class provided here must be sortable.
    # @param handler_proc (Proc) Handler block that accepts an instance of the
    #     event class provided in the first parameter. If nil, a handler object
    #     must be provided.
    # @return The class represented by the event_id, as a String name.
    def subscribe(event_id, handler_object = nil, handler_class = DEFAULT_CLASS,
                  &handler_proc)
      return with_handlers(event_id, handler_class, handler_object,
                           handler_proc) do |hlist, h|
               hlist << h
             end
    end
    alias register subscribe

    ##
    # Unsubscribe an event handler from an event.
    # @param event_id (Class, String, other) A class or String naming an event
    #     class.
    # @param handler_object (Object) Handler object that must implement a
    #     `#call` method accepting an instance of the event class provided in
    #     the first parameter. If nil, a block needs to be provided.
    # @param handler_class (Object) An object describing the handler class; the
    #     default is DEFAULT_CLASS. Handlers are executed sorted by handler class,
    #     so the class provided here must be sortable.
    # @param handler_proc (Proc) Handler block that accepts an instance of the
    #     event class provided in the first parameter. If nil, a handler object
    #     must be provided.
    # @return The class represented by the event_id, as a String name.
    def unsubscribe(event_id, handler_object = nil, handler_class = DEFAULT_CLASS,
                    &handler_proc)
      return with_handlers(event_id, handler_class, handler_object,
                           handler_proc) do |hlist, h|
               hlist.delete(h)
             end
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
      @handlers.keys.sort.each do |handler_class|
        handlers_for(event_name, handler_class, false).each do |handler|
          handler.call(event)
        end
      end
    end
    alias broadcast publish
    alias notify publish

    private

    # The first parameters is the event class or event name. The second parameter
    # is whether this is for write or read access. We don't want to pollute
    # @handlers with data from the #publish call.
    def handlers_for(name, handler_class, write)
      # Defaults for the class
      @handlers[handler_class] ||= {}

      # Use prototype matching for Hash names
      if name.is_a?(Hash)
        name.extend(::Collapsium::PrototypeMatch)

        # The prototype hash logic is a little complex. A hash event can match
        # multiple prototypes, e.g. { a: 42 } should match { a: nil } as well as
        # { a: 42 }.
        # When writing, we want to be as precise as possible and find the best
        # match. When reading, we want to merge all matches, ideally.
        if write
          best_score = -1
          best_proto = nil

          # Find the best matching prototype
          @handlers[handler_class].keys.each do |proto|
            score = name.prototype_match_score(proto)
            if score > best_score
              best_score = score
              best_proto = proto
            end
          end

          if not best_proto.nil?
            return @handlers[handler_class][best_proto]
          end
        else
          merged = []

          @handlers[handler_class].keys.each do |proto|
            if name.prototype_match(proto)
              merged += @handlers[handler_class][proto]
            end
          end

          if not merged.empty?
            return merged
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
        @handlers[handler_class][name] ||= []
      end

      # In read access, want to either return an empty list, or the registered
      # handlers, but not ovewrite the registered handlers.
      return @handlers[handler_class][name] || []
    end

    def with_handlers(event_id, handler_class, handler_object, handler_proc)
      handler = resolve_handler(handler_object, &handler_proc)
      event_name = identify(event_id)

      yield handlers_for(event_name, handler_class, true), handler

      return event_name
    end

    def resolve_handler(handler_object = nil, &handler_proc)
      handler = handler_proc || handler_object
      if not handler
        raise ArgumentError, "Please pass either an object or a handler block"
      end
      return handler
    end

    include ::Octiron::Support::Identifiers
  end # class Bus
end # module Octiron::Events
