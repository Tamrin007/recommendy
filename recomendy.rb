require 'sinatra'
require 'uri'
require 'mysql2'

get '/' do
  uri = URI.parse(ENV["DATABASE_URL"])

  host = uri.host
  user = uri.user
  password =uri.password
  db = uri.path.gsub!(/\//, '')

  client = Mysql2::Client.new(:host => host, :user => user, :password => password, :dbname => db)
  if !client
      "Connection failer"
  end

  rows = []

  query = %q{select * from hackathon_report where restaurant_id = 100000703415}
  results = client.query(query)
  results.each do |row|
      rows.push("<p>--------------------</p>")
      row.each do |key, value|
           rows.push("<p>#{key} => #{value}\n</p>")
      end
  end
  rows
end
