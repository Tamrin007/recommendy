require 'sinatra'
require 'uri'
require 'mysql2'
require 'json'

get '/' do
    if params["hub.verify_token"] != ENV["FACEBOOK_ACCESS_TOKEN"]
        return "Error, wrong validation token"
    end
    params["hub.challenge"]
end

post '/' do
    request_endpoint = "https://graph.facebook.com/v2.6/me/messages?access_token=#{ENV["FACEBOOK_ACCESS_TOKEN"]}"

    request_body = JSON.parse(request.body.read)
    events = request_body["entry"][0]["messaging"]
    events.each do |event|
        sender = event["sender"]["id"]
        body = { recipient: { id: sender }, message: { text: 'hoge' } }
        RestClient.post request_endpoint, body.to_json, content_type: :json, accept: :json
    end
    'OK'
end

get "/mysql_test" do
    uri = URI.parse(ENV["DATABASE_URL"])

    host = uri.host
    user = uri.user
    password =uri.password
    db = uri.path.gsub!(/\//, '')

    client = Mysql2::Client.new(:host => host, :username => user, :password => password, :database => db)
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
