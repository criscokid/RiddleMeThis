EARTH_RADIUS = 3959.0

class AITPContest < Sinatra::Base
  configure do
    mongo_url = ENV['MONGOHQ_URL']

    MongoMapper.connection = Mongo::Connection.from_uri mongo_url
    MongoMapper.database = URI.parse(mongo_url).path.gsub(/^\//, '')
  end

  post "/create_riddle" do
    riddle = params[:riddle]
    auth_key = params[:auth_key]
    latitude = params[:latitude]
    longitude = params[:longitude]

    riddle = Riddle.new(riddle: riddle, location:[longitude.to_f, latitude.to_f], auth_key: auth_key)
    riddle.save
  end

  post '/answer' do
    auth_key = params[:auth_key]
    riddle_id = params[:riddle_id]
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f
    maxDistance = 0.0378788 / EARTH_RADIUS

    riddle = Riddle.find(riddle_id)

    puts riddle.distance_away([latitude, longitude])
    if riddle and riddle.distance_away([latitude, longitude]) <= 0.0378788
      { success: true }.to_json
    else
      { success: false }.to_json
    end
  end

  get '/local_riddles' do
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f
    maxDistance = 10.0 / EARTH_RADIUS
    Riddle.where( 
      location: { '$nearSphere' => [longitude, latitude], '$maxDistance' => maxDistance}).to_json(
      only: [:id, :riddle], 
      methods:[:latitude, :longitude]
    )
  end
end

class Riddle
  include MongoMapper::Document
  key :riddle, String
  key :location, Array
  key :auth_key, String
  timestamps!
  ensure_index [[:location, '2d']]

  def latitude
    location[0]
  end

  def longitude
    location[1]
  end

 def distance_away(loc)
     lon1, lat1 = location
     lat2, lon2 = loc
     dLat = (lat2-lat1).to_rad;
     dLon = (lon2-lon1).to_rad;
     a = Math.sin(dLat/2) * Math.sin(dLat/2) +
         Math.cos(lat1.to_rad) * Math.cos(lat2.to_rad) *
         Math.sin(dLon/2) * Math.sin(dLon/2);
     c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
     d = EARTH_RADIUS * c; # Multiply by 6371 to get Kilometers
  end
end

class Numeric
  def to_rad
    self * Math::PI / 180
  end
end