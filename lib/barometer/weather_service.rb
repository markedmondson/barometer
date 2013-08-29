$:.unshift(File.dirname(__FILE__))
require 'weather_services/base'

module Barometer
  module WeatherService
    def self.services=(services)
      @@services = services
    end

    def self.services
      @@services ||= Utils::VersionedRegistration.new
    end

    def self.register(key, *args, &block)
      if block_given?
        services.register(key, *args, &block)
      elsif args.size > 0
        services.register(key, *args)
      else
        raise ArgumentError
      end
    end

    def self.source(key, version=nil)
      services.find(key, version) or raise NotFound
    end

    def self.new(*args)
      Base.new(*args)
    end

    class KeyRequired < StandardError; end
    class NotFound < StandardError; end
  end
end

require 'weather_services/wunderground_v1'
require 'weather_services/yahoo'
require 'weather_services/weather_bug'
require 'weather_services/noaa'
