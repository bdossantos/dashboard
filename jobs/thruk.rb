require 'net/http'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'time'
require 'uri'

SCHEDULER.every '15s' do
  uri = URI.parse(ENV['THRUK_URI'] || 'http://localhost')
  http = Net::HTTP.new(uri.host)
  request_uri = '/thruk/cgi-bin/status.cgi?servicestatustypes=28&style=detail&sortoption=4&hoststatustypes=15&hostgroup=all&view_mode=json&sorttype=2'
  request = Net::HTTP::Get.new(request_uri)
  request.basic_auth(ENV['THRUK_USER'], ENV['THRUK_PASSWORD'])
  response = http.request(request)

  if response.code != "200"
    puts "Thruk backend communication error (status-code: #{response.code})\n#{response.body}"
  else
    alerts = JSON.parse(response.body)
    
    unless alerts.nil? || alerts == 0
      # when everuthing is OK, populate dashboard w/ random check
      request_uri = '/thruk/cgi-bin/status.cgi?sortoption=4&view_mode=json&sorttype=2&host=all'
      response = http.request(request)
      alerts = JSON.parse(response.body)
    end

    alerts.map! do |alert|
      state = case alert['state']
        when 0 then 'OK'
        when 1 then 'WARNING'
        when 2 then 'CRITICAL'
        else 'UNKNOWN'
      end

      begin
        time = Time.at(alert['last_check']).to_datetime
      rescue
        time = 'N/A'
      end
      
      { 
        hostname: alert['host_name'], 
        detail: alert['plugin_output'],
        description: alert['description'],
        state: state,
        last_check: time,
      }
    end
    send_event 'thruk', { items: alerts.first(4) }
  end
  
  # Scrap summary
  url = "#{uri.scheme}://#{uri.host}/thruk/cgi-bin/status.cgi?host=all"
  document = Nokogiri::HTML(open(url, :http_basic_authentication => [ENV['THRUK_USER'], ENV['THRUK_PASSWORD']]))
  send_event 'summary', {
    items: {
      services_ok: document.css('.serviceTotalsOK').text,
      services_warning: document.css('.serviceTotalsWARNING').text,
      services_critical: document.css('table.serviceTotals:nth-child(1) tr:nth-child(2) td:nth-child(4)').first.text,
      services_pending: document.css('table.serviceTotals:nth-child(1) tr:nth-child(2) td:nth-child(5)').first.text,
      services_unknown: document.css('table.serviceTotals:nth-child(1) tr:nth-child(2) td:nth-child(3)').first.text,
      hosts_up: document.css('.hostTotalsUP').text,
      hosts_down: document.css('td.hostTotals:nth-child(2)').first.text,
      hosts_unreachable: document.css('td.hostTotals:nth-child(3)').first.text,
      hosts_pending: document.css('td.hostTotals:nth-child(4)').first.text,
    }
  }
end
