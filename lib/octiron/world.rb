# coding: utf-8
#
# octiron
# https://github.com/jfinkhaeuser/octiron
#
# Copyright (c) 2016 Jens Finkhaeuser and other octiron contributors.
# All rights reserved.
#

require 'octiron/events/bus'
require 'octiron/transmogrifiers/registry'

##
# World module, putting together the event bus and transmogrifier registry with
# easy access functions.
module Octiron::World
  ##
  # Modules also can have class methods
  module ClassMethods
    ##
    # Singleton transmogrifier registry
    # @return (Octiron::Transmogrifiers::Registry) the registry.
    def transmogrifier_registry
      if @transmogrifier_registry.nil?
        @transmogrifier_registry = ::Octiron::Transmogrifiers::Registry.new
      end
      return @transmogrifier_registry
    end

    ##
    # Singleton event bus
    # @return (Octiron::Events::Bus) the bus.
    def event_bus
      if @event_bus.nil?
        @event_bus = ::Octiron::Events::Bus.new
      end
      return @event_bus
    end
  end # module ClassMethods
  extend ClassMethods

  ##
  # Delegator for the on_transmogrify(FROM).to TO syntax
  # @api private
  class TransmogrifierRegistrator
    def initialize(from)
      @from = from
    end

    def to(to, transmogrifier_object = nil, &transmogrifier_proc)
      ::Octiron::World.transmogrifier_registry.register(@from, to, false,
                                                        transmogrifier_object,
                                                        &transmogrifier_proc)
    end
  end

  ##
  # Delegator for the transmogrify(FROM).to TO syntax
  # @api private
  class TransmogrifyDelegator
    def initialize(from)
      @from = from
    end

    def to(to)
      return ::Octiron::World.transmogrifier_registry.transmogrify(@from, to)
    end
  end

  ##
  # Register a transmogrifier with the singleton transmogrifier registry
  def on_transmogrify(from)
    return TransmogrifierRegistrator.new(from)
  end

  ##
  # Transmogrify using the singleton transmogrifier registry
  def transmogrify(from)
    return TransmogrifyDelegator.new(from)
  end

  ##
  # Subscribe an event handler to an event with the singleton event bus
  def on_event(event_id, handler_object = nil, &handler_proc)
    ::Octiron::World.event_bus.subscribe(event_id, handler_object, &handler_proc)
  end

  ##
  # Publish an event on the singleton event bus
  def publish(event)
    ::Octiron::World.event_bus.publish(event)
  end

end
