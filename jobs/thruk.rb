require 'httparty'
require 'nokogiri'
require 'time'
require 'uri'

class Thruk
  include HTTParty

  uri = URI.parse(ENV['THRUK_URI'] || 'http://localhost')
  base_uri uri.host

  def initialize(u, p)
    @auth = {:username => u, :password => p}
  end

  def alerts(request_uri, options={})
    options.merge!({:basic_auth => @auth})
    self.class.get(request_uri, options)
  end
end

SCHEDULER.every '15s', :first_in => 0 do
  request_uri = '/thruk/cgi-bin/status.cgi?servicestatustypes=28&style=detail&sortoption=4&hoststatustypes=15&hostgroup=all&view_mode=json&sorttype=2'
  thruk = Thruk.new(ENV['THRUK_USER'], ENV['THRUK_PASSWORD'])
  response = thruk.alerts(request_uri)

  if response.code != 200
    puts "Thruk backend communication error (status-code: #{response.code})\n#{response.body}"
  else
    alerts = response.parsed_response

    unless alerts.any?
      # when everuthing is OK, populate dashboard w/ random check
      request_uri = '/thruk/cgi-bin/status.cgi?sortoption=4&view_mode=json&sorttype=2&host=all'
      response = thruk.alerts(request_uri)
      alerts = response.parsed_response
    end

    alerts.map! do |alert|
      state = case alert['state']
        when 0 then 'OK'
        when 1 then 'WARNING'
        when 2 then 'CRITICAL'
        else 'UNKNOWN'
      end

      begin
        time = Time.at(alert['last_check'].to_i)
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
  request_uri = '/thruk/cgi-bin/status.cgi?host=all'
  document = Nokogiri::HTML(thruk.alerts(request_uri).body)
  send_event 'summary', {
    items: {
      services_ok: document.css('table.serviceTotals:nth-child(1) tr:nth-child(2) td:nth-child(1)').first.text,
      services_warning: document.css('table.serviceTotals:nth-child(1) tr:nth-child(2) td:nth-child(2)').first.text,
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
