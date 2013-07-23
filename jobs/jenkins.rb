require 'httparty'

class Jenkins
  include HTTParty

  uri = URI.parse(ENV['JENKINS_URI'] || 'http://localhost')
  base_uri uri.host

  def initialize(u, p)
    @auth = {:username => u, :password => p}
  end

  def jobs(options={})
    options.merge!({:basic_auth => @auth})
    self.class.get('/api/json', options).parsed_response['jobs']
  end

  def build_infos(job_name, options={})
    options.merge!({:basic_auth => @auth})
    self.class.get("/job/#{URI.encode(job_name)}/lastBuild/api/json", options)\
    .parsed_response
  end
end

SCHEDULER.every '60s', :first_in => 0 do
  jobs = []
  jenkins = Jenkins.new('dashboard', 'Oonee6coocie')
  jenkins.jobs.each do |j|
    info = jenkins.build_infos(j['name'])
    begin
      info['who'] = info['actions'][0]['causes'][0]['shortDescription']
      info['date'] = Time.at(info['timestamp'].to_i)
    rescue
      next
    end

    info['date'] = Time.at(info['timestamp'].to_i)
    jobs << info
  end
  send_event 'jenkins', { items: jobs.shuffle.first(4) }
end
