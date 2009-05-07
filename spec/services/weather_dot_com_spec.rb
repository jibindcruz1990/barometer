require 'spec_helper'

describe "WeatherDotCom" do
  
  before(:each) do
    @accepted_formats = [:short_zipcode, :weather_id]
    #Barometer.config = { 1 => { :weather => { :keys => { :partner => WEATHER_PARTNER_KEY, :license => WEATHER_LICENSE_KEY }}}}
    Barometer::WeatherDotCom.keys = { :partner => WEATHER_PARTNER_KEY, :license => WEATHER_LICENSE_KEY }
  end
  
  describe "the class methods" do
    
    it "defines accepted_formats" do
      Barometer::WeatherDotCom.accepted_formats.should == @accepted_formats
    end
    
    it "defines get_all" do
      Barometer::WeatherDotCom.respond_to?("get_all").should be_true
    end
    
  end
  
  describe "building the current data" do
    
    it "defines the build method" do
      Barometer::WeatherDotCom.respond_to?("build_current").should be_true
    end
    
    it "requires Hash input" do
      lambda { Barometer::WeatherDotCom.build_current }.should raise_error(ArgumentError)
      lambda { Barometer::WeatherDotCom.build_current({}) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Data::CurrentMeasurement object" do
      current = Barometer::WeatherDotCom.build_current({})
      current.is_a?(Data::CurrentMeasurement).should be_true
    end
    
  end
  
  describe "building the forecast data" do
    
    it "defines the build method" do
      Barometer::WeatherDotCom.respond_to?("build_forecast").should be_true
    end
    
    it "requires Hash input" do
      lambda { Barometer::WeatherDotCom.build_forecast }.should raise_error(ArgumentError)
      lambda { Barometer::WeatherDotCom.build_forecast({}) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Array object" do
      current = Barometer::WeatherDotCom.build_forecast({})
      current.is_a?(Array).should be_true
    end
    
  end
  
  describe "building the location data" do
    
    it "defines the build method" do
      Barometer::WeatherDotCom.respond_to?("build_location").should be_true
    end
    
    it "requires Hash input" do
      lambda { Barometer::WeatherDotCom.build_location }.should raise_error(ArgumentError)
      lambda { Barometer::WeatherDotCom.build_location({}) }.should_not raise_error(ArgumentError)
    end
    
    it "requires Barometer::Geo input" do
      geo = Data::Geo.new({})
      lambda { Barometer::WeatherDotCom.build_location({}, {}) }.should raise_error(ArgumentError)
      lambda { Barometer::WeatherDotCom.build_location({}, geo) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Barometer::Location object" do
      location = Barometer::WeatherDotCom.build_location({})
      location.is_a?(Data::Location).should be_true
    end
    
  end
  
  describe "building the sun data" do
    
    it "defines the build method" do
      Barometer::WeatherDotCom.respond_to?("build_sun").should be_true
    end
    
    it "requires Hash input" do
      lambda { Barometer::WeatherDotCom.build_sun }.should raise_error(ArgumentError)
      lambda { Barometer::WeatherDotCom.build_sun({}) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Barometer::Sun object" do
      sun = Barometer::WeatherDotCom.build_sun({})
      sun.is_a?(Data::Sun).should be_true
    end
    
  end

  describe "when measuring" do

    before(:each) do
      @query = Barometer::Query.new("90210")
      @query.preferred = "90210"
      @measurement = Data::Measurement.new
      
      url = "http://xoap.weather.com:80/weather/local/"
  
      FakeWeb.register_uri(:get, 
         "#{url}90210?dayf=5&unit=m&link=xoap&par=#{WEATHER_PARTNER_KEY}&prod=xoap&key=#{WEATHER_LICENSE_KEY}&cc=*",
         :string => File.read(File.join(File.dirname(__FILE__), 
           '../fixtures/services/weather_dot_com', 
           '90210.xml')
         )
       )  
    end

    describe "all" do
      
      it "responds to _measure" do
        Barometer::WeatherDotCom.respond_to?("_measure").should be_true
      end
      
      it "requires a Barometer::Measurement object" do
        lambda { Barometer::WeatherDotCom._measure(nil, @query) }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherDotCom._measure("invlaid", @query) }.should raise_error(ArgumentError)
  
        lambda { Barometer::WeatherDotCom._measure(@measurement, @query) }.should_not raise_error(ArgumentError)
      end
  
      it "requires a Barometer::Query query" do
        lambda { Barometer::WeatherDotCom._measure }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherDotCom._measure(@measurement, 1) }.should raise_error(ArgumentError)
        
        lambda { Barometer::WeatherDotCom._measure(@measurement, @query) }.should_not raise_error(ArgumentError)
      end
      
      it "returns a Barometer::Measurement object" do
        result = Barometer::WeatherDotCom._measure(@measurement, @query)
        result.is_a?(Data::Measurement).should be_true
        result.current.is_a?(Data::CurrentMeasurement).should be_true
        result.forecast.is_a?(Array).should be_true
        
        result.source.should == :weather_dot_com
      end
      
    end

  end
  
  describe "when answering the simple questions," do
    
    before(:each) do
      @measurement = Data::Measurement.new
    end
    
    describe "currently_wet_by_icon?" do
      
      before(:each) do
        @measurement.current = Data::CurrentMeasurement.new
      end
  
      it "returns true if matching icon code" do
        @measurement.current.icon = "4"
        @measurement.current.icon?.should be_true
        Barometer::WeatherDotCom.currently_wet_by_icon?(@measurement.current).should be_true
      end
      
      it "returns false if NO matching icon code" do
        @measurement.current.icon = "32"
        @measurement.current.icon?.should be_true
        Barometer::WeatherDotCom.currently_wet_by_icon?(@measurement.current).should be_false
      end
      
    end
    
    describe "forecasted_wet_by_icon?" do
      
      before(:each) do
        @measurement.forecast = [Data::ForecastMeasurement.new]
        @measurement.forecast.first.date = Date.today
        @measurement.forecast.size.should == 1
      end
      
      it "returns true if matching icon code" do
        @measurement.forecast.first.icon = "4"
        @measurement.forecast.first.icon?.should be_true
        Barometer::WeatherDotCom.forecasted_wet_by_icon?(@measurement.forecast.first).should be_true
      end
      
      it "returns false if NO matching icon code" do
        @measurement.forecast.first.icon = "32"
        @measurement.forecast.first.icon?.should be_true
        Barometer::WeatherDotCom.forecasted_wet_by_icon?(@measurement.forecast.first).should be_false
      end
      
    end
    
    describe "currently_sunny_by_icon?" do
      
      before(:each) do
        @measurement.current = Data::CurrentMeasurement.new
      end
      
      it "returns true if matching icon code" do
        @measurement.current.icon = "32"
        @measurement.current.icon?.should be_true
        Barometer::WeatherDotCom.currently_sunny_by_icon?(@measurement.current).should be_true
      end
      
      it "returns false if NO matching icon code" do
        @measurement.current.icon = "4"
        @measurement.current.icon?.should be_true
        Barometer::WeatherDotCom.currently_sunny_by_icon?(@measurement.current).should be_false
      end
      
    end
    
    describe "forecasted_sunny_by_icon?" do
      
      before(:each) do
        @measurement.forecast = [Data::ForecastMeasurement.new]
        @measurement.forecast.first.date = Date.today
        @measurement.forecast.size.should == 1
      end
      
      it "returns true if matching icon code" do
        @measurement.forecast.first.icon = "32"
        @measurement.forecast.first.icon?.should be_true
        Barometer::WeatherDotCom.forecasted_sunny_by_icon?(@measurement.forecast.first).should be_true
      end
      
      it "returns false if NO matching icon code" do
        @measurement.forecast.first.icon = "4"
        @measurement.forecast.first.icon?.should be_true
        Barometer::WeatherDotCom.forecasted_sunny_by_icon?(@measurement.forecast.first).should be_false
      end
      
    end
    
  end
  
  describe "overall data correctness" do
    
    before(:each) do
      @query = Barometer::Query.new("90210")
      @query.preferred = "90210"
      @measurement = Data::Measurement.new
      
      url = "http://xoap.weather.com:80/weather/local/"
  
      FakeWeb.register_uri(:get, 
         "#{url}90210?dayf=5&unit=m&link=xoap&par=#{WEATHER_PARTNER_KEY}&prod=xoap&key=#{WEATHER_LICENSE_KEY}&cc=*",
         :string => File.read(File.join(File.dirname(__FILE__), 
           '../fixtures/services/weather_dot_com', 
           '90210.xml')
         )
       )
    end
    
    # curl "http://xoap.weather.com:80/weather/local/90210?dayf=5&unit=m&link=xoap&par=1083363440&prod=xoap&key=710d8b0ff1001a9a&cc=*
  
    it "should correctly build the data" do
      result = Barometer::WeatherDotCom._measure(@measurement, @query)
      
      # build current
      @measurement.current.humidity.to_i.should == 75
      @measurement.current.icon.should == "33"
      @measurement.current.condition.should == "Fair"
      @measurement.current.temperature.to_i.should == 16
      @measurement.current.dew_point.to_i.should == 12
      @measurement.current.wind_chill.to_i.should == 16
      @measurement.current.wind.to_i.should == 5
      @measurement.current.wind.degrees.to_i.should == 80
      @measurement.current.wind.direction.should == "E"
      @measurement.current.pressure.to_f.should == 1016.6
      @measurement.current.visibility.to_f.should == 16.1
      
      # build sun
      # sun_rise = Barometer::Zone.merge("6:01 am", "5/4/09 12:51 AM PDT", -7)
      # sun_set = Barometer::Zone.merge("7:40 pm", "5/4/09 12:51 AM PDT", -7)
      # @measurement.current.sun.rise.should == sun_rise
      # @measurement.current.sun.set.should == sun_set
      @measurement.current.sun.rise.to_s.should == "06:01 am"
      @measurement.current.sun.set.to_s.should == "07:40 pm"

      # builds location
      @measurement.location.name.should == "Beverly Hills, CA (90210)"
      @measurement.location.latitude.to_f.should == 34.10
      @measurement.location.longitude.to_f.should == -118.41
      
      # builds forecasts
      @measurement.forecast.size.should == 5

      @measurement.forecast[0].date.should == Date.parse("May 3")
      @measurement.forecast[0].condition.should == "Partly Cloudy"
      @measurement.forecast[0].icon.should == "30"
      @measurement.forecast[0].high.should be_nil
      @measurement.forecast[0].low.to_i.should == 14
      @measurement.forecast[0].pop.to_i.should == 10
      @measurement.forecast[0].humidity.to_i.should == 65
      
      @measurement.forecast[0].wind.should_not be_nil
      @measurement.forecast[0].wind.to_i.should == 16
      @measurement.forecast[0].wind.degrees.to_i.should == 288
      @measurement.forecast[0].wind.direction.should == "WNW"
      
      # sun_rise = Barometer::Zone.merge("6:02 am", "5/4/09 12:25 AM PDT", -7)
      # sun_set = Barometer::Zone.merge("7:40 pm", "5/4/09 12:25 AM PDT", -7)
      # @measurement.forecast[0].sun.rise.should == sun_rise
      # @measurement.forecast[0].sun.set.should == sun_set
      @measurement.forecast[0].sun.rise.to_s.should == "06:02 am"
      @measurement.forecast[0].sun.set.to_s.should == "07:40 pm"
      
      @measurement.forecast[0].night.should_not be_nil
      @measurement.forecast[0].night.condition.should == "Partly Cloudy"
      @measurement.forecast[0].night.icon.should == "29"
      @measurement.forecast[0].night.pop.to_i.should == 10
      @measurement.forecast[0].night.humidity.to_i.should == 71
      
      @measurement.forecast[0].night.wind.should_not be_nil
      @measurement.forecast[0].night.wind.to_i.should == 14
      @measurement.forecast[0].night.wind.degrees.to_i.should == 335
      @measurement.forecast[0].night.wind.direction.should == "NNW"
    end
    
  end
  
end