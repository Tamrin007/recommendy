require 'uri'
require 'mysql2'

# 使い方
=begin
include GenreTree

initTree()
p find_two_child_nodes_or_restaurant('日本料理')
p DBAccess.new().find_image_url('日本料理')
p find_two_child_nodes_or_restaurant('牛タン')
=end

def db_initialize()
    uri = URI.parse(ENV["DATABASE_URL"])
    host = uri.host
    user = uri.user
    password = uri.password
    db = uri.path.gsub!(/\//, '')
    client = Mysql2::Client.new(:host => host, :username => user, :password => password, :database => db)
end

module GenreTree
  class DBAccess
    def initialize()
      @client = db_initialize()
    end

    def find_image_url(genre_name)
      statement = @client.prepare('select image_url from hackathon_report as repo inner join hackathon_image as img on repo.report_id=img.report_id where restaurant_id in (select restaurant_id from hackathon_restaurant where category_name=?) order by rand() limit 1;')
      results = statement.execute(genre_name)

      row_size = results.size
      row_index = rand(row_size)

      image_url = ""
      results.each{|row|
        row.each{|key, value|
         image_url = value
        }
      }

      image_url
    end

    def find_restaurant(genre_name)
      statement = @client.prepare('select restaurant_name from hackathon_restaurant where category_name=? order by rand() limit 1;')
      results = statement.execute(genre_name)

      row_size = results.size
      row_index = rand(row_size)

      restaurant_name = ""
      results.each{|row|
        row.each{|key, value|
         restaurant_name = value
        }
      }

      restaurant_name
    end
  end

  class Node
    attr_reader :id, :name, :child_ids

    def initialize(id, name, child_ids)
      @id = id
      @name = name
      @child_ids = child_ids
      @db_access = DBAccess.new()
    end

    def to_genre_dto
      image_url = @db_access.find_image_url(@name)
      GenreDTO.new(@name, image_url) # TODO
    end

    def to_restaurant_dto
      restaurant_name = @db_access.find_restaurant(@name)
      image_url = @db_access.find_image_url(@name)
      RestaurantDTO.new(restaurant_name, image_url)
    end
  end

  class GenreDTO
    attr_reader :node, :image_url

    def initialize(node, image_url)
      @node = node
      @image_url = image_url
    end
  end

  class RestaurantDTO
    attr_reader :name, :image_url

    def initialize(name, image_url)
      @name = name
      @image_url = image_url
    end
  end

  def initTree()
    @genre_tree = [
      Node.new(1, "カフェ", []),
      Node.new(2, "居酒屋", [6, 21]),
      Node.new(3, "ラーメン", [22]),
      Node.new(4, "イタリア料理", [52]),
      Node.new(5, "焼肉", [35, 38, 51]),
      Node.new(6, "焼き鳥", []),
      Node.new(7, "中華料理", [3]),
      Node.new(8, "ビストロ", []),
      Node.new(9, "ダイニングバー", []),
      Node.new(10, "フランス料理", [8]),
      Node.new(11, "魚介・海鮮料理", [15]),
      Node.new(12, "そば（蕎麦）", []),
      Node.new(13, "カレー", []),
      Node.new(14, "バー", [9, 24, 27]),
      Node.new(15, "寿司", []),
      Node.new(16, "洋食", [8, 10, 20, 26, 36, 52]),
      Node.new(17, "とんかつ", []),
      Node.new(18, "パン屋", [26, 52]),
      Node.new(19, "うどん", []),
      Node.new(20, "ステーキ", []),
      Node.new(21, "立ち飲み", []),
      Node.new(22, "つけ麺", []),
      Node.new(23, "スイーツ", [42]),
      Node.new(24, "ワインバー", []),
      Node.new(25, "喫茶店", [1]),
      Node.new(26, "ハンバーガー", []),
      Node.new(27, "ビアバー", []),
      Node.new(28, "和食のご飯・おかず", [12, 15, 19, 39, 40, 49]),
      Node.new(29, "韓国料理", []),
      Node.new(30, "タイ料理", []),
      Node.new(31, "割烹・小料理屋", [15, 39]),
      Node.new(32, "パスタ", []),
      Node.new(33, "インド料理", [13]),
      Node.new(34, "餃子", []),
      Node.new(35, "ジンギスカン", []),
      Node.new(36, "ハンバーグ", []),
      Node.new(37, "日本料理", [28, 31, 49]),
      Node.new(38, "ホルモン", []),
      Node.new(39, "天ぷら", []),
      Node.new(40, "お好み焼き", []),
      Node.new(41, "鉄板焼き", []),
      Node.new(42, "ケーキ屋", []),
      Node.new(43, "甘味処", []),
      Node.new(44, "もつ鍋", []),
      Node.new(45, "定食", []),
      Node.new(46, "バイキング", []),
      Node.new(47, "ベトナム料理", []),
      Node.new(48, "スペイン料理", []),
      Node.new(49, "懐石料理", []),
      Node.new(50, "台湾料理", []),
      Node.new(51, "牛タン", []),
      Node.new(52, "ピザ", []),
      Node.new(53, "その他", [8, 12, 17, 18, 23, 29, 30, 41, 43, 45, 46, 47, 48, 50])
    ]

    @first_genre_candidate_ids = [16, 37]
  end

  def get_first_genre_dtos()
    @first_genre_candidate_ids
  end

  def find_node(id)
    @genre_tree.select{|node| node.id == id}
  end

  def find_node_by_name(name)
    @genre_tree.select{|node| node.name == name}
  end

  def find_two_child_nodes_or_restaurant(name)
    node = find_node_by_name(name)[0]
    find_two_child_nodes_or_restaurant_(node.id)
  end

  def find_two_child_nodes_or_restaurant_(id)
    parent_nodes = find_node(id)

    if parent_nodes.size <= 0
      nil
    end

    parent_node = parent_nodes[0]
    child_num = parent_node.child_ids.size

    if child_num == 1
      return find_two_child_nodes_or_restaurant_(parent_node.child_ids[0])
    elsif child_num == 0
      return [parent_node.to_restaurant_dto(), nil]
    end

    a_index = get_distinct_rand(child_num, nil)
    a_node = find_node(parent_node.child_ids[a_index])[0]

    b_index = get_distinct_rand(child_num, a_index)
    b_node = find_node(parent_node.child_ids[b_index])[0]

    [a_node.to_genre_dto, b_node.to_genre_dto]
  end

  def get_distinct_rand(max, other)
    candidate = rand(max)

    if candidate == other
      return get_distinct_rand(max, other)
    end

    candidate
  end
end
