require 'httparty'
require './genre_tree.rb'

include GenreTree

ACCESS_TOKEN = ENV["PAGE_ACCESS_TOKEN"]
URL = "https://graph.facebook.com/v2.6/me/messages?access_token=#{ACCESS_TOKEN}"

def recieved_message(event)
    client = $mysql
    if !client
        "Connection failer"
    end
    initTree()

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
        message_attachments.each do |attachment|
            p type = attachment["type"]
            p payload = attachment["payload"]
            case type
            when 'location'
                send_text_message(sender_id, "位置情報を確認しました！")
                send_text_message(sender_id, "付近のレストランの中からオススメを2軒ずつ何度かピックアップいたします！")
                send_text_message(sender_id, "数回繰り返しますと、あなたにピッタリのレストランが見つかります！")
                results = insert_latlng(sender_id, payload["coordinates"], client)

                # 初回のボタン生成
                first_dtos = get_first_genre_dtos
                nodes = [find_node(first_dtos[0])[0], find_node(first_dtos[1])[0]]
                p nodes
                p nodes[0].name

                images = nodes.map{|node| node.to_genre_dto}.map{|dto|
                    {
                            :attachment => {
                            :type => "image",
                            :payload => {
                                :url => dto.image_url
                            }
                        }
                    }
                }

                images.each{|image|
                    send_image(sender_id, image)
                }


                buttons = {
                    :attachment => {
                        :type => "template",
                        :payload => {
                            :template_type => "button",
                            :text => "まずはこちらの2軒から好きの方をお選び下さい！",
                            :buttons => [{
                                :type => "postback",
                                :title => nodes[0].name,
                                :payload => nodes[0].name
                            }, {
                                :type => "postback",
                                :title => nodes[1].name,
                                :payload => nodes[1].name
                            }]
                        }
                    }
                }
                send_button(sender_id, buttons)
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

def send_button(recipient_id, buttons)
    message_data = {
        :recipient => {
            :id => recipient_id
        },
        :message => buttons
    }

    call_send_api(message_data)
end

def send_image(recipient_id, image_url)
    message_data = {
        :recipient => {
            :id => recipient_id
        },
        :message => image_url
    }
end

def call_send_api(message_data)
    p message_data.to_json
    @result = HTTParty.post(URL, :body => message_data.to_json, :headers => {'Content-Type' => 'application/json'})
end

def pick_lat_and_long(location)
    p "lat: " + location["lat"].to_s + ", long: " + location["long"].to_s
end

def insert_latlng(sender_id, location, client)
    point = "POINT(#{location["lat"].to_s} #{location["long"].to_s})"
    query = %{
        insert into a_team_users (id, user_latlng)
        values (?, GeomFromText(?))
        on duplicate key update user_latlng=GeomFromText(?)
    }
    stmt = client.prepare(query)
    result = stmt.execute(sender_id, point, point)
end

def received_postback(event)
    client = db_initialize()
    if !client
        "Connection failer"
    end

    sender_id = event["sender"]["id"]
    recipient_id = event["sender"]["id"]
    time_of_event = event["timestamp"]
    message = event["message"]
    payload = event["postback"]["payload"]

    p "Received postback for user #{sender_id} and page #{recipient_id} with payload #{payload} at #{time_of_event}"

    send_text_message(sender_id, "#{payload} ですね！");
    send_text_message(sender_id, "次はこちらの2軒から好きな方をお選び下さい！");

    node_a, node_b = find_two_child_nodes_or_restaurant(payload)

    if node_b == nil
        # restaurant_dto
        dto = node_b
        images = [{
            {
                :attachment => {
                    :type => "image",
                    :payload => {
                        :url => dto.image_url
                    }
                }
            }
        }]

    else
        # genre_dto * 2
        dtos = [node_a, node_b]
        images = dtos.map{|dto|
                    {
                        :attachment => {
                            :type => "image",
                            :payload => {
                                :url => dto.image_url
                            }
                        }
                    }
                }
    end

    images.each{|image|
        send_image(sender_id, image)
    }

    buttons = {
        :attachment => {
            :type => "template",
            :payload => {
                :template_type => "button",
                :text => "まずはこちらの2軒から好きの方をお選び下さい！",
                :buttons => [{
                    :type => "postback",
                    :title => "左のお店",
                    :payload => "左のお店"
                }, {
                    :type => "postback",
                    :title => "右のお店",
                    :payload => "右のお店"
                }]
            }
        }
    }
    send_button(sender_id, buttons)
end
