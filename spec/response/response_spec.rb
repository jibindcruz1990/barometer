require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'time'

describe Barometer::Response::Base do
  it { should have_field(:query).of_type(String) }
  it { should have_field(:weight).of_type(Integer) }
  it { should have_field(:status_code).of_type(Integer) }

  describe ".new" do
    its(:forecast) { should be_a Barometer::Response::PredictionCollection }
    its(:current) { should be_a Barometer::Response::Current }
    its(:metric) { should be_true }
    its(:weight) { should == 1 }
    its(:requested_at) { should be_a(Time) }
  end

  describe "#success?" do
    it "returns true if :status_code == 200" do
      subject.status_code = 200
      subject.should be_success
    end

    it "returns false if :status_code does not == 200" do
      subject.status_code = nil
      subject.should_not be_success

      subject.status_code = 406
      subject.should_not be_success
    end
  end

  describe "#complete?" do
    it "returns true when the current temperature has been set" do
      subject.current.temperature = [10]
      subject.should be_complete
    end

    it "returns true when the current temperature has not been set" do
      subject.should_not be_complete
    end
  end

  describe "#build_forecast" do
    it "yields a new response" do
      expect { |b|
        subject.build_forecast(&b)
      }.to yield_with_args(Barometer::Response::Prediction)
    end

    it "adds the new response to forecast array" do
      expect {
        subject.build_forecast do
        end
      }.to change{ subject.forecast.count }.by(1)
    end
  end

  describe "when searching forecasts using 'for'" do
    before(:each) do
      @response = Barometer::Response::Base.new

      now = Time.now
      local_now = Time.utc(now.year, now.month, now.day, now.hour, now.min, now.sec)

      1.upto(4) do |i|
        forecast_response = Barometer::Response::Prediction.new
        forecast_response.date = Date.parse((local_now + (i * 60 * 60 * 24)).to_s)
        @response.forecast << forecast_response
      end
      @response.forecast.size.should == 4

      @tommorrow = (local_now + (60 * 60 * 24))
    end

    it "returns nil when there are no forecasts" do
      @response.forecast = Barometer::Response::PredictionCollection.new
      @response.forecast.size.should == 0
      @response.for.should be_nil
    end

    it "finds the date using a Time" do
      @response.for(@tommorrow).should == @response.forecast.first
    end

    it "finds the date using a String" do
      tommorrow = @tommorrow.to_s
      @response.for(tommorrow).should == @response.forecast.first
    end

    it "finds the date using a Date" do
      tommorrow = Date.parse(@tommorrow.to_s)
      @response.for(tommorrow).should == @response.forecast.first
    end

    it "finds the date using a DateTime" do
      tommorrow = DateTime.parse(@tommorrow.to_s)
      @response.for(tommorrow).should == @response.forecast.first
    end

    it "finds the date using Data::Time" do
      tommorrow = Barometer::Utils::Time.parse(@tommorrow.to_s)
      @response.for(tommorrow).should == @response.forecast.first
    end

    it "finds nothing when there is not a match" do
      yesterday = (@tommorrow - (60 * 60 * 24 * 2))
      @response.for(yesterday).should be_nil
    end
  end
end
