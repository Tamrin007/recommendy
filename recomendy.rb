require 'sinatra'
require 'uri'
require 'mysql2'
require './bot.rb'

get '/' do
    if params["hub.verify_token"] != ENV["FACEBOOK_ACCESS_TOKEN"]
        return "Error, wrong validation token"
    end
    params["hub.challenge"]
end

post '/' do
    data = JSON.parse(request.body.read)

    if data["object"] == "page"
        data["enrty"].each do |page_entry|
            page_id = pageEntry["id"];
            time_of_event = page_entry["time"];

            page_entry["messaging"].each do |messaging_event|
                if messaging_event["message"]
                    recieved_message(messaging_event)
                else
                    puts "Webhook received unknown messaging_event: #{messaging_event}"
                end
            end
        end
    end

    # puts location = message["attachments"].first["payload"]["coordinates"] if message["attachments"].first["type"] == "location"
    # # response = "lat: %s, long: %s" % [location["lat"], location["long"]]
    # response = "位置情報"
    #
    # unless message.nil?
    #     @result = HTTParty.post(URL, :body => {
    #         :recipient => {
    #             :id => sender
    #         }, :message => {
    #             :text => response
    #         }
    #     }.to_json,:headers => {
    #         'Content-Type' => 'application/json'
    #     })
    # end
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
