require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Barometer::Converter::FromWoeIdToGeocode, :vcr => {
  :match_requests_on => [:method, :uri],
  :cassette_name => "Converter::FromWoeIdToGeocode"
} do

  it "converts :woe_id -> :geocode" do
    query = Barometer::Query.new('615702')
    query.format = :woe_id

    converter = Barometer::Converter::FromWoeIdToGeocode.new(query)
    converted_query = converter.call

    converted_query.q.should == 'Paris, France'
    converted_query.format.should == :geocode
    converted_query.country_code.should be_nil
    converted_query.geo.should be_nil
  end

  it "uses a previous coversion (if needed) on the query" do
    query = Barometer::Query.new('40.697488,-73.979681')
    query.format = :coordinates
    query.add_conversion(:woe_id, '615702')

    converter = Barometer::Converter::FromWoeIdToGeocode.new(query)
    converted_query = converter.call

    converted_query.q.should == 'Paris, France'
    converted_query.format.should == :geocode
    converted_query.country_code.should be_nil
    converted_query.geo.should be_nil
  end

  it "does not convert any other format" do
    query = Barometer::Query.new('90210')
    query.format = :short_zipcode

    converter = Barometer::Converter::FromWoeIdToGeocode.new(query)
    converter.call.should be_nil
  end
end