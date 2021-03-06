module Barometer
  module Query
    module Service
      class YahooGeocode
        def self.call(query)
          converted_query = query.get_conversion(:woe_id, :weather_id)
          return unless converted_query
          puts "reverse #{converted_query.format}: #{converted_query.q}" if Barometer::debug?

          response =  Barometer::Utils::Get.call(
            'http://weather.yahooapis.com/forecastrss',
            _format_query(converted_query)
          )
          Barometer::Utils::XmlReader.parse(response, 'rss', 'channel')
        end

        def self.parse_geocode(response)
          [response['location']['@city'], response['location']['@region'], response['location']['@country']].
            select{|r|!r.empty?}.join(', ')
        end

        def self.parse_coordinates(response)
          [response['item']['lat'], response['item']['long']].select{|r|!r.empty?}.join(',')
        end

        private

        def self._format_query(query)
          if query.format == :woe_id
            { :w => query.q }
          else
            puts "[WARNING] - converting #{query.format} -> geocode is deprecated by Yahoo! Weather" if Barometer::debug?
            { :p => query.q }
          end
        end
      end
    end
  end
end
