module Barometer
  module Data
    module Attribute
      class Zone < Virtus::Attribute::Object
        primitive Data::Zone
        default nil

        def self.writer_class(*)
          TypeRequiredWriter
        end
      end
    end
  end
end
