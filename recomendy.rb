require 'sinatra'
require 'uri'
require 'mysql2'
require 'httparty'

access_token = ENV["PAGE_ACCESS_TOKEN"]
URL = "https://graph.facebook.com/v2.6/me/messages?access_token=#{access_token}"

get '/' do
    if params["hub.verify_token"] != ENV["FACEBOOK_ACCESS_TOKEN"]
        return "Error, wrong validation token"
    end
    params["hub.challenge"]
end

post '/' do
    body = request.body.read
    payload = JSON.parse(body)

    sender = payload["entry"].first["messaging"].first["sender"]["id"]
    puts message = payload["entry"].first["messaging"].first["message"]
    puts text = message["text"] unless message["text"].nil?

    unless message.nil?
        @result = HTTParty.post(URL, :body => {:recipient => {:id => sender}, :message => {:text => text}}.to_json,:headers => {'Content-Type' => 'application/json'})
    end

    puts location = message["attachments"].first["payload"]["coordinates"] if message["attachments"].first["type"] == "location"
    # response = "lat: %s, lan: %s" % [location["lat"], location["lan"]]
    response = "位置情報"

    unless message.nil?
        @result = HTTParty.post(URL, :body => {
            :recipient => {
                :id => sender
            }, :message => {
                :text => response
            }
        }.to_json,:headers => {
            'Content-Type' => 'application/json'
        })
    end
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
