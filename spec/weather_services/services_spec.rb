require 'spec_helper'

describe "WeatherServices" do
  
  before(:each) do
    query_term = "Calgary,AB"
    @query = Barometer::Query.new(query_term)
    @service = Barometer::WeatherService.source(:wunderground)
    @time = Time.now
  end
  
  describe "and the class method" do
    
    describe "source" do
      
      it "responds" do
        Barometer::WeatherService.respond_to?("source").should be_true
      end
      
      it "requires a Symbol or String" do
        lambda { Barometer::WeatherService.source }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.source(1) }.should raise_error(ArgumentError)
        
        lambda { Barometer::WeatherService.source("wunderground") }.should_not raise_error(ArgumentError)
        lambda { Barometer::WeatherService.source(:wunderground) }.should_not raise_error(ArgumentError)
      end
      
      it "raises an error if source doesn't exist" do
        lambda { Barometer::WeatherService.source(:not_valid) }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.source(:wunderground) }.should_not raise_error(ArgumentError)
      end
      
      it "returns the corresponding Service object" do
        Barometer::WeatherService.source(:wunderground).should == WeatherService::Wunderground
        Barometer::WeatherService.source(:wunderground).superclass.should == Barometer::WeatherService
      end
      
      it "raises an error when retrieving the wrong class" do
        lambda { Barometer::WeatherService.source(:temperature) }.should raise_error(ArgumentError)
      end
      
    end
    
  end
  
  describe "when initialized" do
    
    before(:each) do
      @service = Barometer::WeatherService.new
      @measurement = Data::Measurement.new
      @query = Barometer::Query.new("test")
    end
    
    it "defaults _meets_requirements?" do
      Barometer::WeatherService.send("_meets_requirements?").should be_true
    end

    it "stubs _source_name" do
      lambda { Barometer::WeatherService.send("_source_name") }.should raise_error(NotImplementedError)
    end

    it "stubs _accepted_formats" do
      lambda { Barometer::WeatherService.send("_accepted_formats") }.should raise_error(NotImplementedError)
    end
    
    it "stubs _measure" do
      Barometer::WeatherService._measure(@measurement,@query,true).is_a?(Data::Measurement).should be_true
    end
    
    it "stubs _build_extra" do
      Barometer::WeatherService._build_extra.should be_nil
    end
    
    it "stubs _fetch" do
      Barometer::WeatherService._fetch.should be_nil
    end
    
    it "stubs _build_current" do
      Barometer::WeatherService._build_current.should be_nil
    end
    
    it "stubs _build_forecast" do
      Barometer::WeatherService._build_forecast.should be_nil
    end
    
    it "stubs _build_location" do
      Barometer::WeatherService._build_location.should be_nil
    end
    
    it "stubs _build_sun" do
      Barometer::WeatherService._build_sun.should be_nil
    end
    
    it "stubs _build_links" do
      Barometer::WeatherService._build_links.should == {}
    end
    
    it "defaults _supports_country?" do
      Barometer::WeatherService._supports_country?.should be_true
    end
    
    it "defaults _requires_keys?" do
      Barometer::WeatherService._requires_keys?.should be_false
    end
    
    it "defaults _has_keys?" do
      lambda { Barometer::WeatherService._has_keys? }.should raise_error(NotImplementedError)
    end
    
  end
  
  describe "when measuring," do
    
    it "responds to measure" do
      Barometer::WeatherService.respond_to?("measure").should be_true
    end
    
    # since Barometer::WeatherService defines the measure method, you could actuall just
    # call Barometer::WeatherService.measure ... but this will not invoke a specific
    # weather API driver.  Make sure this usage raises an error.
    it "requires an actuall driver" do
      lambda { Barometer::WeatherService.measure(@query) }.should raise_error(NotImplementedError)
    end
    
    it "requires a Barometer::Query object" do
      lambda { Barometer::WeatherService.measure("invalid") }.should raise_error(ArgumentError)
      @query.is_a?(Barometer::Query).should be_true
      lambda { Barometer::WeatherService.measure(@query) }.should_not raise_error(ArgumentError)
    end
    
    it "returns a Data::Measurement object" do
      @service.measure(@query).is_a?(Data::Measurement).should be_true
    end
    
    it "returns current and future" do
      measurement = @service.measure(@query)
      measurement.current.is_a?(Data::CurrentMeasurement).should be_true
      measurement.forecast.is_a?(Array).should be_true
    end
    
  end
  
  describe "when answering the simple questions," do
    
    before(:each) do
      # the function being tested was monkey patched in an earlier test
      # so the original file must be reloaded
      load 'lib/barometer/weather_services/service.rb'
      
      @measurement = Data::Measurement.new
      @now = Data::LocalDateTime.parse("01-jan-2009 2:05 pm")
    end
    
    describe "windy?" do
      
      it "requires a measurement object" do
        lambda { Barometer::WeatherService.windy? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.windy?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.windy?(@measurement) }.should_not raise_error(ArgumentError)
      end
      
      it "requires threshold as a number" do
        lambda { Barometer::WeatherService.windy?(@measurement,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.windy?(@measurement,1) }.should_not raise_error(ArgumentError)
        lambda { Barometer::WeatherService.windy?(@measurement,1.1) }.should_not raise_error(ArgumentError)
      end
      
      it "requires time as a Data::LocalTime object" do
        #lambda { Barometer::WeatherService.windy?(@measurement,1,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.windy?(@measurement,1,@now) }.should_not raise_error(ArgumentError)
      end

      it "stubs forecasted_windy?" do
        Barometer::WeatherService._forecasted_windy?(@measurement,nil,nil).should be_nil
      end
      
      describe "and is current" do
        
        before(:each) do
          module Barometer; class Data::Measurement
            def current?(a=nil); true; end
          end; end
        end
      
        it "returns nil" do
          Barometer::WeatherService.windy?(@measurement).should be_nil
        end
        
        it "returns true if currently_windy?" do
          module Barometer; class WeatherService
            def self._currently_windy?(a=nil,b=nil); true; end
          end; end
          Barometer::WeatherService.windy?(@measurement).should be_true
        end

        it "returns false if !currently_windy?" do
          module Barometer; class WeatherService
            def self._currently_windy?(a=nil,b=nil); false; end
          end; end
          Barometer::WeatherService.windy?(@measurement).should be_false
        end
        
      end
      
      describe "and is NOT current" do
        
        before(:each) do
          module Barometer; class Data::Measurement
            def current?(a=nil); false; end
          end; end
        end
      
        it "returns nil" do
          Barometer::WeatherService.windy?(@measurement).should be_nil
        end
        
        it "returns true if forecasted_windy?" do
          module Barometer; class WeatherService
            def self._forecasted_windy?(a=nil,b=nil,c=nil); true; end
          end; end
          Barometer::WeatherService.windy?(@measurement).should be_true
        end

        it "returns false if !forecasted_windy?" do
          module Barometer; class WeatherService
            def self._forecasted_windy?(a=nil,b=nil,c=nil); false; end
          end; end
          Barometer::WeatherService.windy?(@measurement).should be_false
        end
        
      end
      
    end
    
    describe "currently_windy?" do

      before(:each) do
        # the function being tested was monkey patched in an earlier test
        # so the original file must be reloaded
        load 'lib/barometer/weather_services/service.rb'
        
        @measurement = Data::Measurement.new
        @threshold = 10
      end

      it "requires a measurement object" do
        lambda { Barometer::WeatherService._currently_windy? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_windy?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_windy?(@measurement) }.should_not raise_error(ArgumentError)
      end

      it "requires threshold as a number" do
        lambda { Barometer::WeatherService._currently_windy?(@measurement,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_windy?(@measurement,1) }.should_not raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_windy?(@measurement,1.1) }.should_not raise_error(ArgumentError)
      end

      it "returns nil when value unavailable" do
        measurement = Data::Measurement.new
        Barometer::WeatherService._currently_windy?(measurement,@threshold).should be_nil
        measurement.current = Data::CurrentMeasurement.new
        Barometer::WeatherService._currently_windy?(measurement,@threshold).should be_nil
        measurement.current.wind = Data::Speed.new
        Barometer::WeatherService._currently_windy?(measurement,@threshold).should be_nil
      end

      describe "when metric" do

        before(:each) do
          @measurement = Data::Measurement.new
          @measurement.current = Data::CurrentMeasurement.new
          @measurement.current.wind = Data::Speed.new
          @measurement.metric!
          @measurement.metric?.should be_true
        end

        # measurement.current.wind.kph.to_f
        it "returns true when wind speed (kph) above threshold" do
          @measurement.current.wind.kph = @threshold + 1
          Barometer::WeatherService._currently_windy?(@measurement,@threshold).should be_true
        end

        it "returns false when wind speed (kph) below threshold" do
          @measurement.current.wind.kph = @threshold - 1
          Barometer::WeatherService._currently_windy?(@measurement,@threshold).should be_false
        end

      end

      describe "when imperial" do

        before(:each) do
          @measurement = Data::Measurement.new
          @measurement.current = Data::CurrentMeasurement.new
          @measurement.current.wind = Data::Speed.new
          @measurement.imperial!
          @measurement.metric?.should be_false
        end

        it "returns true when wind speed (mph) above threshold" do
          @measurement.current.wind.mph = @threshold - 1
          Barometer::WeatherService._currently_windy?(@measurement,@threshold).should be_false
        end

        it "returns false when wind speed (mph) below threshold" do
          @measurement.current.wind.mph = @threshold - 1
          Barometer::WeatherService._currently_windy?(@measurement,@threshold).should be_false
        end

      end

    end
    
    describe "wet?" do
      
      it "requires a measurement object" do
        lambda { Barometer::WeatherService.wet? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.wet?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.wet?(@measurement) }.should_not raise_error(ArgumentError)
      end
      
      it "requires threshold as a number" do
        lambda { Barometer::WeatherService.wet?(@measurement,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.wet?(@measurement,1) }.should_not raise_error(ArgumentError)
        lambda { Barometer::WeatherService.wet?(@measurement,1.1) }.should_not raise_error(ArgumentError)
      end
      
      it "requires time as a Data::LocalTime object" do
        #lambda { Barometer::WeatherService.wet?(@measurement,1,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.wet?(@measurement,1,@now) }.should_not raise_error(ArgumentError)
      end

      describe "and is current" do
        
        before(:each) do
          module Barometer; class Data::Measurement
            def current?(a=nil); true; end
          end; end
        end
      
        it "returns nil" do
          Barometer::WeatherService.wet?(@measurement).should be_nil
        end
        
        it "returns true if currently_wet?" do
          module Barometer; class WeatherService
            def self._currently_wet?(a=nil,b=nil); true; end
          end; end
          Barometer::WeatherService.wet?(@measurement).should be_true
        end

        it "returns false if !currently_wet?" do
          module Barometer; class WeatherService
            def self._currently_wet?(a=nil,b=nil); false; end
          end; end
          Barometer::WeatherService.wet?(@measurement).should be_false
        end
        
      end
      
      describe "and is NOT current" do
        
        before(:each) do
          module Barometer; class Data::Measurement
            def current?(a=nil); false; end
          end; end
        end
      
        it "returns nil" do
          Barometer::WeatherService.wet?(@measurement).should be_nil
        end
        
        it "returns true if forecasted_wet?" do
          module Barometer; class WeatherService
            def self._forecasted_wet?(a=nil,b=nil,c=nil); true; end
          end; end
          Barometer::WeatherService.wet?(@measurement).should be_true
        end

        it "returns false if !forecasted_wet?" do
          module Barometer; class WeatherService
            def self._forecasted_wet?(a=nil,b=nil,c=nil); false; end
          end; end
          Barometer::WeatherService.wet?(@measurement).should be_false
        end
        
      end
      
    end
    
    describe "currently_wet?" do
    
      before(:each) do
        # the function being tested was monkey patched in an earlier test
        # so the original file must be reloaded
        load 'lib/barometer/weather_services/service.rb'
        
        @measurement = Data::Measurement.new
        @threshold = 10
        @temperature = 15
      end
    
      it "requires a measurement object" do
        lambda { Barometer::WeatherService._currently_wet? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_wet?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_wet?(@measurement) }.should_not raise_error(ArgumentError)
      end
    
      it "requires threshold as a number" do
        lambda { Barometer::WeatherService._currently_wet?(@measurement,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_wet?(@measurement,1) }.should_not raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_wet?(@measurement,1.1) }.should_not raise_error(ArgumentError)
      end
    
      it "returns nil when value unavailable" do
        measurement = Data::Measurement.new
        Barometer::WeatherService._currently_wet?(measurement,@threshold).should be_nil
        measurement.current = Data::CurrentMeasurement.new
        Barometer::WeatherService._currently_wet?(measurement,@threshold).should be_nil
        measurement.current.wind = Data::Speed.new
        Barometer::WeatherService._currently_wet?(measurement,@threshold).should be_nil
      end
      
      describe "currently_wet_by_icon?" do

        before(:each) do
          @measurement.current = Data::CurrentMeasurement.new
        end

        it "requires a Barometer::Measurement object" do
          lambda { Barometer::WeatherService._currently_wet_by_icon?(nil) }.should raise_error(ArgumentError)
          lambda { Barometer::WeatherService._currently_wet_by_icon?("invlaid") }.should raise_error(ArgumentError)

          lambda { Barometer::WeatherService._currently_wet_by_icon?(@measurement.current) }.should_not raise_error(ArgumentError)
        end

        it "returns nil if no icon" do
          @measurement.current.icon?.should be_false
          Barometer::WeatherService._currently_wet_by_icon?(@measurement.current).should be_nil
        end

        it "returns true if matching icon code" do
          module Barometer; class WeatherService; def self._wet_icon_codes
            ["rain"]
          end; end; end
          @measurement.current.icon = "rain"
          @measurement.current.icon?.should be_true
          Barometer::WeatherService._currently_wet_by_icon?(@measurement.current).should be_true
        end

        it "returns false if NO matching icon code" do
          module Barometer; class WeatherService; def self._wet_icon_codes
            ["rain"]
          end; end; end
          @measurement.current.icon = "sunny"
          @measurement.current.icon?.should be_true
          Barometer::WeatherService._currently_wet_by_icon?(@measurement.current).should be_false
        end

      end
      
      describe "and currently_wet_by_dewpoint?" do
        
        describe "when metric" do
 
          before(:each) do
            @measurement = Data::Measurement.new
            @measurement.current = Data::CurrentMeasurement.new
            @measurement.current.temperature = Data::Temperature.new
            @measurement.current.dew_point = Data::Temperature.new
            @measurement.metric!
            @measurement.metric?.should be_true
          end
          
          it "returns true when temperature < dew_point" do
            @measurement.current.temperature.c = @temperature
            @measurement.current.dew_point.c = @temperature + 1
            Barometer::WeatherService._currently_wet_by_dewpoint?(@measurement).should be_true
          end
        
          it "returns false when temperature > dew_point" do
            @measurement.current.temperature.c = @temperature
            @measurement.current.dew_point.c = @temperature - 1
            Barometer::WeatherService._currently_wet_by_dewpoint?(@measurement).should be_false
          end
          
        end
        
        describe "when imperial" do
          
          before(:each) do
            @measurement = Data::Measurement.new
            @measurement.current = Data::CurrentMeasurement.new
            @measurement.current.temperature = Data::Temperature.new
            @measurement.current.dew_point = Data::Temperature.new
            @measurement.imperial!
            @measurement.metric?.should be_false
          end

          it "returns true when temperature < dew_point" do
            @measurement.current.temperature.f = @temperature
            @measurement.current.dew_point.f = @temperature + 1
            Barometer::WeatherService._currently_wet_by_dewpoint?(@measurement).should be_true
          end

          it "returns false when temperature > dew_point" do
            @measurement.current.temperature.f = @temperature
            @measurement.current.dew_point.f = @temperature - 1
            Barometer::WeatherService._currently_wet_by_dewpoint?(@measurement).should be_false
          end

        end
      
      end
      
      describe "and currently_wet_by_humidity?" do
        
        before(:each) do
          @measurement = Data::Measurement.new
          @measurement.current = Data::CurrentMeasurement.new
        end
        
        it "returns true when humidity >= 99%" do
          @measurement.current.humidity = 99
          Barometer::WeatherService._currently_wet_by_humidity?(@measurement.current).should be_true
          @measurement.current.humidity = 100
          Barometer::WeatherService._currently_wet_by_humidity?(@measurement.current).should be_true
        end
      
        it "returns false when humidity < 99%" do
          @measurement.current.humidity = 98
          Barometer::WeatherService._currently_wet_by_humidity?(@measurement.current).should be_false
        end
        
      end
      
      describe "and currently_wet_by_pop?" do
        
        before(:each) do
          @measurement = Data::Measurement.new
          @measurement.forecast = [Data::ForecastMeasurement.new]
          @measurement.forecast.first.date = Date.today
          @measurement.forecast.size.should == 1
        end
        
        it "returns true when pop (%) above threshold" do
          @measurement.forecast.first.pop = @threshold + 1
          Barometer::WeatherService._currently_wet_by_pop?(@measurement, @threshold).should be_true
        end

        it "returns false when pop (%) below threshold" do
          @measurement.forecast.first.pop = @threshold - 1
          Barometer::WeatherService._currently_wet_by_pop?(@measurement, @threshold).should be_false
        end
        
      end
    
    end
    
    describe "forecasted_wet?" do
    
      before(:each) do
        # the function being tested was monkey patched in an earlier test
        # so the original file must be reloaded
        load 'lib/barometer/weather_services/service.rb'
        
        @measurement = Data::Measurement.new
        @threshold = 10
        @temperature = 15
      end
    
      it "requires a measurement object" do
        lambda { Barometer::WeatherService._forecasted_wet? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_wet?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_wet?(@measurement) }.should_not raise_error(ArgumentError)
      end

      it "requires threshold as a number" do
        lambda { Barometer::WeatherService._forecasted_wet?(@measurement,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_wet?(@measurement,1) }.should_not raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_wet?(@measurement,1.1) }.should_not raise_error(ArgumentError)
      end

      it "requires utc_time as a Data::LocalTime object" do
        #lambda { Barometer::WeatherService.forecasted_wet?(@measurement,1,"string") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_wet?(@measurement,1,@now) }.should_not raise_error(ArgumentError)
      end

      it "returns nil when value unavailable" do
        measurement = Data::Measurement.new
        Barometer::WeatherService._forecasted_wet?(measurement,@threshold).should be_nil
        measurement.forecast = [Data::ForecastMeasurement.new]
        Barometer::WeatherService._forecasted_wet?(measurement,@threshold).should be_nil
      end
      
      describe "forecasted_wet_by_icon?" do

        before(:each) do
          @measurement.forecast = [Data::ForecastMeasurement.new]
          @measurement.forecast.first.date = Date.today
          @measurement.forecast.size.should == 1
        end

        it "requires a Barometer::Measurement object" do
          lambda { Barometer::WeatherService._forecasted_wet_by_icon?(nil) }.should raise_error(ArgumentError)
          lambda { Barometer::WeatherService._forecasted_wet_by_icon?("invlaid") }.should raise_error(ArgumentError)

          lambda { Barometer::WeatherService._forecasted_wet_by_icon?(@measurement.forecast.first) }.should_not raise_error(ArgumentError)
        end

        it "returns nil if no icon" do
          @measurement.forecast.first.icon?.should be_false
          Barometer::WeatherService._forecasted_wet_by_icon?(@measurement.forecast.first).should be_nil
        end

        it "returns true if matching icon code" do
          module Barometer; class WeatherService; def self._wet_icon_codes
            ["rain"]
          end; end; end
          @measurement.forecast.first.icon = "rain"
          @measurement.forecast.first.icon?.should be_true
          Barometer::WeatherService._forecasted_wet_by_icon?(@measurement.forecast.first).should be_true
        end

        it "returns false if NO matching icon code" do
          module Barometer; class WeatherService; def self._wet_icon_codes
            ["rain"]
          end; end; end
          @measurement.forecast.first.icon = "sunny"
          @measurement.forecast.first.icon?.should be_true
          Barometer::WeatherService._forecasted_wet_by_icon?(@measurement.forecast.first).should be_false
        end

        after(:each) do
          # the function being tested was monkey patched in an earlier test
          # so the original file must be reloaded
          load 'lib/barometer/weather_services/service.rb'
        end

      end

      describe "and forecasted_wet_by_pop?" do
        
        before(:each) do
          @measurement = Data::Measurement.new
          @measurement.forecast = [Data::ForecastMeasurement.new]
          @measurement.forecast.first.date = Date.today
          @measurement.forecast.size.should == 1
        end
        
        it "returns true when pop (%) above threshold" do
          @measurement.forecast.first.pop = @threshold + 1
          Barometer::WeatherService._forecasted_wet_by_pop?(@measurement.forecast.first, @threshold).should be_true
        end

        it "returns false when pop (%) below threshold" do
          @measurement.forecast.first.pop = @threshold - 1
          Barometer::WeatherService._forecasted_wet_by_pop?(@measurement.forecast.first, @threshold).should be_false
        end
        
      end

    end
    
    describe "day?" do
      
      it "requires a measurement object" do
        lambda { Barometer::WeatherService.day? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.day?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.day?(@measurement) }.should_not raise_error(ArgumentError)
      end
      
      it "requires time as a Data::LocalTime object" do
        #lambda { Barometer::WeatherService.day?(@measurement,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.day?(@measurement,@now) }.should_not raise_error(ArgumentError)
      end
      
      describe "and is current" do
        
        before(:each) do
          module Barometer; class Data::Measurement
            def current?(a=nil); true; end
          end; end
        end
      
        it "returns nil" do
          Barometer::WeatherService.day?(@measurement).should be_nil
        end
        
        it "returns true if currently_day?" do
          module Barometer; class WeatherService
            def self._currently_day?(a=nil); true; end
          end; end
          Barometer::WeatherService.day?(@measurement).should be_true
        end

        it "returns false if !currently_day?" do
          module Barometer; class WeatherService
            def self._currently_day?(a=nil); false; end
          end; end
          Barometer::WeatherService.day?(@measurement).should be_false
        end
        
      end
      
      describe "and is NOT current" do
        
        before(:each) do
          module Barometer; class Data::Measurement
            def current?(a=nil); false; end
          end; end
        end
      
        it "returns nil" do
          Barometer::WeatherService.day?(@measurement).should be_nil
        end
        
        it "returns true if forecasted_day?" do
          module Barometer; class WeatherService
            def self._forecasted_day?(a=nil,b=nil); true; end
          end; end
          Barometer::WeatherService.day?(@measurement).should be_true
        end

        it "returns false if !forecasted_day?" do
          module Barometer; class WeatherService
            def self._forecasted_day?(a=nil,b=nil); false; end
          end; end
          Barometer::WeatherService.day?(@measurement).should be_false
        end
        
      end
      
    end
    
    describe "currently_day?" do

      before(:each) do
        # the function being tested was monkey patched in an earlier test
        # so the original file must be reloaded
        load 'lib/barometer/weather_services/service.rb'
        
        @measurement = Data::Measurement.new
      end

      it "requires a measurement object" do
        lambda { Barometer::WeatherService._currently_day? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_day?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_day?(@measurement) }.should_not raise_error(ArgumentError)
      end
      
      it "returns nil when value unavailable" do
        measurement = Data::Measurement.new
        Barometer::WeatherService._currently_day?(measurement).should be_nil
      end
      
      describe "and currently_after_sunrise?" do
        
        before(:each) do
          @measurement = Data::CurrentMeasurement.new
          @now = Data::LocalTime.parse("2:02 pm")
          @past = @now - (60*60)
          @future = @now + (60*60)
        end
        
        it "returns true when now is past sun_rise" do
          @measurement.sun = Data::Sun.new(@past)
          @measurement.current_at.should be_nil
          Barometer::WeatherService._currently_after_sunrise?(@measurement).should be_nil
          
          @measurement.current_at = @now
          @measurement.current_at.should_not be_nil
          Barometer::WeatherService._currently_after_sunrise?(@measurement).should be_true
        end

        it "returns false when now if before sun_rise" do
          @measurement.sun = Data::Sun.new(@future)
          @measurement.current_at.should be_nil
          Barometer::WeatherService._currently_after_sunrise?(@measurement).should be_nil
          
          @measurement.current_at = @now
          @measurement.current_at.should_not be_nil
          Barometer::WeatherService._currently_after_sunrise?(@measurement).should be_false
        end
        
      end
      
      describe "and currently_before_sunset?" do
        
        before(:each) do
          @measurement = Data::CurrentMeasurement.new
          @now = Data::LocalTime.parse("2:02 pm")
          @past = @now - (60*60)
          @future = @now + (60*60)
        end
        
        it "returns true when now is before sun_set" do
          @measurement.sun = Data::Sun.new(nil,@future)
          @measurement.current_at.should be_nil
          Barometer::WeatherService._currently_before_sunset?(@measurement).should be_nil
          
          @measurement.current_at = @now
          @measurement.current_at.should_not be_nil
          Barometer::WeatherService._currently_before_sunset?(@measurement).should be_true
        end

        it "returns false when now if after sun_set" do
          @measurement.sun = Data::Sun.new(nil,@past)
          @measurement.current_at.should be_nil
          Barometer::WeatherService._currently_before_sunset?(@measurement).should be_nil
          
          @measurement.current_at = @now
          @measurement.current_at.should_not be_nil
          Barometer::WeatherService._currently_before_sunset?(@measurement).should be_false
        end
        
      end
      
    end
    
    describe "forecasted_day?" do

      before(:each) do
        # the function being tested was monkey patched in an earlier test
        # so the original file must be reloaded
        load 'lib/barometer/weather_services/service.rb'
        
        @measurement = Data::Measurement.new
      end

      it "requires a measurement object" do
        lambda { Barometer::WeatherService._forecasted_day? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_day?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_day?(@measurement) }.should_not raise_error(ArgumentError)
      end
      
      it "requires time as a Data::LocalTime object" do
        #lambda { Barometer::WeatherService.forecasted_day?(@measurement,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_day?(@measurement,@now) }.should_not raise_error(ArgumentError)
      end

      it "returns nil when value unavailable" do
        measurement = Data::Measurement.new
        Barometer::WeatherService._forecasted_day?(measurement).should be_nil
      end
      
      describe "and forecasted_after_sunrise?" do
        
        before(:each) do
          @measurement = Data::ForecastMeasurement.new
          @now = Data::LocalDateTime.parse("2:02 pm")
          @past = @now - (60*60)
          @future = @now + (60*60)
        end
        
        it "returns true when now is past sun_rise" do
          @measurement.sun = Data::Sun.new(@past)
          Barometer::WeatherService._forecasted_after_sunrise?(@measurement, @now).should be_true
        end
      
        it "returns false when now if before sun_rise" do
          @measurement.sun = Data::Sun.new(@future)
          Barometer::WeatherService._forecasted_after_sunrise?(@measurement, @now).should be_false
        end
        
      end
      
      describe "and forecasted_before_sunset?" do
        
        before(:each) do
          @measurement = Data::ForecastMeasurement.new
          @now = Data::LocalDateTime.parse("2:02 pm")
          @past = @now - (60*60)
          @future = @now + (60*60)
        end
        
        it "returns true when now is before sun_set" do
          @measurement.sun = Data::Sun.new(nil,@future)
          Barometer::WeatherService._forecasted_before_sunset?(@measurement,@now).should be_true
        end
      
        it "returns false when now if after sun_set" do
          @measurement.sun = Data::Sun.new(nil,@past)
          Barometer::WeatherService._forecasted_before_sunset?(@measurement,@now).should be_false
        end
        
      end
      
    end
    
    describe "sunny?" do
      
      it "requires a measurement object" do
        lambda { Barometer::WeatherService.sunny? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.sunny?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.sunny?(@measurement) }.should_not raise_error(ArgumentError)
      end
      
      it "requires time as a Data::LocalTime object" do
        #lambda { Barometer::WeatherService.sunny?(@measurement,"a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService.sunny?(@measurement,@now) }.should_not raise_error(ArgumentError)
      end

      it "draws attention to this spot to fix this test"
      # it "returns false if night time" do
      #   @measurement.forecast = [Data::ForecastMeasurement.new]
      #   @measurement.forecast.size.should == 1
      #   @measurement.forecast[0].date = Date.today
      #   module Barometer; class WeatherService; def self.day?(a=nil, b=nil)
      #     true
      #   end; end; end
      #   Barometer::WeatherService.forecasted_sunny?(@measurement).should be_true
      #   module Barometer; class WeatherService; def self.day?(a=nil, b=nil)
      #     false
      #   end; end; end
      #   Barometer::WeatherService.forecasted_sunny?(@measurement).should be_false
      # end

      describe "and is current" do
        
        before(:each) do
          module Barometer; class Data::Measurement
            def current?(a=nil); true; end
          end; end
        end
      
        it "returns nil" do
          Barometer::WeatherService.sunny?(@measurement).should be_nil
        end
        
        it "returns true if currently_sunny?" do
          module Barometer; class WeatherService
            def self._currently_sunny?(a=nil); true; end
          end; end
          Barometer::WeatherService.sunny?(@measurement).should be_true
        end

        it "returns false if !currently_sunny?" do
          module Barometer; class WeatherService
            def self._currently_sunny?(a=nil); false; end
          end; end
          Barometer::WeatherService.sunny?(@measurement).should be_false
        end
        
      end
      
      describe "and is NOT current" do
        
        before(:each) do
          module Barometer; class Data::Measurement
            def current?(a=nil); false; end
          end; end
        end
      
        it "returns nil" do
          Barometer::WeatherService.sunny?(@measurement).should be_nil
        end
        
        it "returns true if forecasted_sunny?" do
          module Barometer; class WeatherService
            def self._forecasted_sunny?(a=nil,b=nil); true; end
          end; end
          Barometer::WeatherService.sunny?(@measurement).should be_true
        end

        it "returns false if !forecasted_wet?" do
          module Barometer; class WeatherService
            def self._forecasted_sunny?(a=nil,b=nil); false; end
          end; end
          Barometer::WeatherService.sunny?(@measurement).should be_false
        end
        
      end
      
    end
    
    describe "currently_sunny?" do
    
      before(:each) do
        # the function being tested was monkey patched in an earlier test
        # so the original file must be reloaded
        load 'lib/barometer/weather_services/service.rb'
        
        @measurement = Data::Measurement.new
      end
    
      it "requires a measurement object" do
        lambda { Barometer::WeatherService._currently_sunny? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_sunny?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._currently_sunny?(@measurement) }.should_not raise_error(ArgumentError)
      end
    
      it "returns nil when value unavailable" do
        measurement = Data::Measurement.new
        Barometer::WeatherService._currently_sunny?(measurement).should be_nil
        measurement.current = Data::CurrentMeasurement.new
        Barometer::WeatherService._currently_sunny?(measurement).should be_nil
      end
      
      it "returns false if night time" do
        @measurement.current = Data::CurrentMeasurement.new
        module Barometer; class WeatherService; def self._currently_day?(a=nil)
          true
        end; end; end
        module Barometer; class WeatherService; def self._currently_sunny_by_icon?(a=nil)
          true
        end; end; end
        Barometer::WeatherService._currently_sunny?(@measurement).should be_true
        module Barometer; class WeatherService; def self._currently_day?(a=nil)
          false
        end; end; end
        Barometer::WeatherService._currently_sunny?(@measurement).should be_false
      end

      describe "currently_sunny_by_icon?" do

        before(:each) do
          @measurement.current = Data::CurrentMeasurement.new
        end

        it "requires a Barometer::Measurement object" do
          lambda { Barometer::WeatherService._currently_sunny_by_icon?(nil) }.should raise_error(ArgumentError)
          lambda { Barometer::WeatherService._currently_sunny_by_icon?("invlaid") }.should raise_error(ArgumentError)

          lambda { Barometer::WeatherService._currently_sunny_by_icon?(@measurement.current) }.should_not raise_error(ArgumentError)
        end

        it "returns nil if no icon" do
          @measurement.current.icon?.should be_false
          Barometer::WeatherService._currently_sunny_by_icon?(@measurement.current).should be_nil
        end

        it "returns true if matching icon code" do
          module Barometer; class WeatherService; def self._sunny_icon_codes
            ["sunny"]
          end; end; end
          @measurement.current.icon = "sunny"
          @measurement.current.icon?.should be_true
          Barometer::WeatherService._currently_sunny_by_icon?(@measurement.current).should be_true
        end

        it "returns false if NO matching icon code" do
          module Barometer; class WeatherService; def self._sunny_icon_codes
            ["sunny"]
          end; end; end
          @measurement.current.icon = "rain"
          @measurement.current.icon?.should be_true
          Barometer::WeatherService._currently_sunny_by_icon?(@measurement.current).should be_false
        end

      end
      
    end
    
    describe "forecasted_sunny?" do
    
      before(:each) do
        # the function being tested was monkey patched in an earlier test
        # so the original file must be reloaded
        load 'lib/barometer/weather_services/service.rb'
        
        @measurement = Data::Measurement.new
      end
    
      it "requires a measurement object" do
        lambda { Barometer::WeatherService._forecasted_sunny? }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_sunny?("a") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_sunny?(@measurement) }.should_not raise_error(ArgumentError)
      end

      it "requires utc_time as a Data::LocalTime object" do
        #lambda { Barometer::WeatherService.forecasted_sunny?(@measurement,"string") }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService._forecasted_sunny?(@measurement,@now) }.should_not raise_error(ArgumentError)
      end

      it "returns nil when value unavailable" do
        measurement = Data::Measurement.new
        Barometer::WeatherService._forecasted_sunny?(measurement).should be_nil
        measurement.forecast = [Data::ForecastMeasurement.new]
        measurement.forecast.size.should == 1
        Barometer::WeatherService._forecasted_sunny?(measurement).should be_nil
      end

      it "returns false if night time" do
        @measurement.forecast = [Data::ForecastMeasurement.new]
        @measurement.forecast.size.should == 1
        target_date = Date.today
        @measurement.forecast[0].date = target_date
        module Barometer; class WeatherService; def self._forecasted_day?(a=nil, b=nil)
          true
        end; end; end
        module Barometer; class WeatherService; def self._forecasted_sunny_by_icon?(a=nil, b=nil)
          true
        end; end; end
        Barometer::WeatherService._forecasted_sunny?(@measurement, target_date).should be_true
        module Barometer; class WeatherService; def self._forecasted_day?(a=nil, b=nil)
          false
        end; end; end
        Barometer::WeatherService._forecasted_sunny?(@measurement).should be_false
      end
      
      describe "forecasted_sunny_by_icon?" do

        before(:each) do
          @measurement.forecast = [Data::ForecastMeasurement.new]
          @measurement.forecast.first.date = Date.today
          @measurement.forecast.size.should == 1
        end

        it "requires a Barometer::Measurement object" do
          lambda { Barometer::WeatherService._forecasted_sunny_by_icon?(nil) }.should raise_error(ArgumentError)
          lambda { Barometer::WeatherService._forecasted_sunny_by_icon?("invlaid") }.should raise_error(ArgumentError)

          lambda { Barometer::WeatherService._forecasted_sunny_by_icon?(@measurement.forecast.first) }.should_not raise_error(ArgumentError)
        end

        it "returns nil if no icon" do
          @measurement.forecast.first.icon?.should be_false
          Barometer::WeatherService._forecasted_sunny_by_icon?(@measurement.forecast.first).should be_nil
        end

        it "returns true if matching icon code" do
          module Barometer; class WeatherService; def self._sunny_icon_codes
            ["sunny"]
          end; end; end
          @measurement.forecast.first.icon = "sunny"
          @measurement.forecast.first.icon?.should be_true
          Barometer::WeatherService._forecasted_sunny_by_icon?(@measurement.forecast.first).should be_true
        end

        it "returns false if NO matching icon code" do
          module Barometer; class WeatherService; def self._sunny_icon_codes
            ["sunny"]
          end; end; end
          @measurement.forecast.first.icon = "rain"
          @measurement.forecast.first.icon?.should be_true
          Barometer::WeatherService._forecasted_sunny_by_icon?(@measurement.forecast.first).should be_false
        end

        after(:each) do
          # the function being tested was monkey patched in an earlier test
          # so the original file must be reloaded
          load 'lib/barometer/weather_services/service.rb'
        end

      end

    end
    
  end
  
end