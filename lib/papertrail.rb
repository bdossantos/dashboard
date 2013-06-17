require 'net/https'
require 'json'
require 'uri'

class Papertrail
  API = 'https://papertrailapp.com/api/v1/events/search.json'

  def initialize(search)
    @search = URI.escape(search)
  end

  def fetch(min_id = '')
    uri = URI.parse(API + "?q='#{@search}'&min_id=#{min_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request.initialize_http_header({'X-Papertrail-Token' => ENV['PAPERTRAIL_TOKEN']})
    response = http.request(request)
    
    return JSON.parse(response.body)
  end
end
