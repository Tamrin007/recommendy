require 'sinatra'
require 'uri'
require 'mysql2'
require './bot.rb'
require './genre_tree.rb'

get '/' do
    if params["hub.verify_token"] != ENV["FACEBOOK_ACCESS_TOKEN"]
        return "Error, wrong validation token"
    end
    params["hub.challenge"]
end

post '/' do
    p "post received"
    p data = JSON.parse(request.body.read)

    if data["object"] == "page"
        p data["entry"].class
        data["entry"].each do |page_entry|
            page_id = page_entry["id"];
            time_of_event = page_entry["time"];

            page_entry["messaging"].each do |messaging_event|
                initTree()
                if messaging_event["message"]
                    recieved_message(messaging_event)
                elsif messaging_event["postback"]
                    received_postback(messaging_event)
                else
                    p "Webhook received unknown messaging_event: #{messaging_event}"
                end
            end
        end
    end

    'ok'
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
