require 'httparty'

ACCESS_TOKEN = ENV["PAGE_ACCESS_TOKEN"]
URL = "https://graph.facebook.com/v2.6/me/messages?access_token=#{ACCESS_TOKEN}"

def recieved_message(event)
    sender_id = event["sender"]["id"]
    recipient_id = event["sender"]["id"]
    time_of_event = event["timestamp"]
    message = event["message"]

    puts "Received message for user #{sender_id} and page #{recipient_id} at #{time_of_event} with message: "
    puts message.to_s

    var messageId = message.mid;
    message_id = message["mid"]

    message_text = message["text"];
    message_attachments = message["attachments"]

    if message_text
        case message_text
        when 'image' then
            # image
        when 'button' then
            # button
        when 'generic' then
            # generic
        when 'receipt'
            # receipt
        else
            send_text_message(sender_id, message_text)
        end
    elsif message_attachments
        send_text_message(sender_id, "Message with attachment received")
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
    }.to_json

    call_send_api(message_data)
end

def call_send_api(message_data)
    puts @result = HTTParty.post(URL, :body => message_data, :headers => {'Content-Type' => 'application/json'})
    puts @result.class
end