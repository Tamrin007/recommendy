require 'httparty'

ACCESS_TOKEN = ENV["PAGE_ACCESS_TOKEN"]
URL = "https://graph.facebook.com/v2.6/me/messages?access_token=#{ACCESS_TOKEN}"

def recieved_message(event)
    client = db_initialize()
    if !client
        "Connection failer"
    end

    sender_id = event["sender"]["id"]
    recipient_id = event["sender"]["id"]
    time_of_event = event["timestamp"]
    message = event["message"]

    p "Received message for user #{sender_id} and page #{recipient_id} at #{time_of_event} with message: "
    p message.to_s

    message_id = message["mid"]

    message_text = message["text"];
    message_attachments = message["attachments"]

    if message_text
        case message_text
        when "image" then
            # image
        when "button" then
            # button
        when "generic" then
            # generic
        when "receipt"
            # receipt
        else
            send_text_message(sender_id, message_text)
        end
    elsif message_attachments
        send_text_message(sender_id, "Message with attachment received")

        message_attachments.each do |attachment|
            p type = attachment["type"]
            p payload = attachment["payload"]
            case type
            when 'location'
                send_text_message(sender_id, pick_lat_and_long(payload["coordinates"]))
                insert_latlng(sender_id, payload["coordinates"], client)
            else
                send_text_message(sender_id, "It is not location.")
            end
        end
    end
end

def send_text_message(recipient_id, message_text)
    message_data = {
        :recipient => {
            :id => recipient_id
        },
        :message => {
            :text => message_text
        }
    }

    call_send_api(message_data)
end

def call_send_api(message_data)
    p message_data.to_json
    @result = HTTParty.post(URL, :body => message_data.to_json, :headers => {'Content-Type' => 'application/json'})
end

def pick_lat_and_long(location)
    p "lat: " + location["lat"].to_s + ", long: " + location["long"].to_s
end

def insert_latlng(sender_id, location, client)
    query = %{insert into a_team_users (id, user_latlng) values (?, GeomFromText('POINT(? ?)')) on duplicate key update user_latlng=GeomFromText('POINT(? ?)')}
    stmt = client.prepare(query)
    stmt.execute(sender_id, location["lat"].to_s, location["long"].to_s, location["lat"].to_s, location["long"].to_s)
end

def db_initialize
    uri = URI.parse(ENV["DATABASE_URL"])
    host = uri.host
    user = uri.user
    password =uri.password
    db = uri.path.gsub!(/\//, '')
    client = Mysql2::Client.new(:host => host, :username => user, :password => password, :database => db)
end
