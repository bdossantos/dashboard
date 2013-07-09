require 'httparty'
require 'uri'

class Papertrail
  def initialize(search)
    @search = URI.escape(search)
  end

  def search(min_id = '')
    response = HTTParty.get(
      "https://papertrailapp.com/api/v1/events/search.json?q='#{@search}'&min_id=#{min_id}",
      :headers => { 'X-Papertrail-Token' => ENV['PAPERTRAIL_TOKEN'] }
    )
    response.parsed_response
  end
end

searches = [
  'No such file or directory',
  'PHP',
  'segfault',
  'upstream timed out'
]

searches.each do |search|
  last_x, last_y = 0
  points = []

  papertrail = Papertrail.new search
  json = papertrail.search

  SCHEDULER.every '4s', :first_in => 0 do
    json = papertrail.search(json['max_id'])
    last_x += 1
    points << { x: last_x, y: json['events'].count  }
    send_event search.downcase.strip.gsub(' ', '_').gsub(/[^\w-]/, ''), 
              { points: points }

    points = [] if last_x % 15 == 0
  end
end
