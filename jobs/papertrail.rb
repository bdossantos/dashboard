require_relative '../lib/papertrail'

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
  json = papertrail.fetch

  SCHEDULER.every '4s' do
    json = papertrail.fetch(json['max_id'])
    last_x += 1
    points << { x: last_x, y: json['events'].count  }
    send_event search.downcase.strip.gsub(' ', '_').gsub(/[^\w-]/, ''), 
              { points: points }

    points = [] if last_x % 15 == 0
  end
end
