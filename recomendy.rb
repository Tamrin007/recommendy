require 'sinatra'
require 'uri'
require 'mysql2'

get '/' do
  uri = URI.parse(ENV["DATABASE_URL"])

  p "database url: "
  p uri

  host = uri.host
  user = uri.user
  password =uri.password
  db = uri.path.gsub!(/\//, '')

  # client = Mysql2::Client.new(:host => host, :username => user, :password => password, :database => db)
  # if !client
  #     "Connection failer"
  # end
  #
  # rows = []
  #
  # query = %q{select * from hackathon_report where restaurant_id = 100000703415}
  # results = client.query(query)
  # results.each do |row|
  #     rows.push("<p>--------------------</p>")
  #     row.each do |key, value|
  #          rows.push("<p>#{key} => #{value}\n</p>")
  #     end
  # end
  # rows
end

get "/callback" do
    if params["hub.verify_token"] != "EAADESXvPAzwBADFMPxnegfbUJ86jzgPW7vxw6nGuX9ZAy4Wwz0ubG67qRiWpfjMfNwQuofJQkbc1Msx5aNLMr5AZBmm5IFUKBLP7F30zHewXgmpyRqqeYCZBmWQT4k1jzRZAdM7G4M7J7dUrcPgfkiMJmas6BprQ2RLZCJiUljQZDZD"
        return "Error, wrong validation token"
    end
    params["hub.challenge"]
end
