module Barometer
  module Requester
    class Yahoo
      def initialize(metric=true)
        @metric = metric
      end

      def get_weather(query)
        puts "fetch yahoo weather: #{query.q}" if Barometer::debug?

        response = _get(query)

        output = Barometer::Utils::XmlReader.parse(response, "rss", "channel")
        Barometer::Utils::Payload.new(output)
      end

      private

      attr_reader :metric

      def _get(query)
        Barometer::Utils::Get.call(
          "http://weather.yahooapis.com/forecastrss",
          _format_request(query)
        )
      end

      def _format_request(query)
        { :u => _unit_type }.merge(_format_query(query))
      end

      def _format_query(query)
        if query.format == :woe_id
          { :w => query.q }
        else
          puts "[WARNING] - using Yahoo Weather! with #{query.format} is deprecated" if Barometer::debug?
          { :p => query.q }
        end
      end

      def _unit_type
        metric ? 'c' : 'f'
      end
    end
  end
end
