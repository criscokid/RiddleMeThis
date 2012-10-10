class Riddle
  include MongoMapper::Document
  key :riddle, String
  key :location, Array
  key :auth_key, String
  key :username, String
  timestamps!
  ensure_index [[:location, '2d']]

  validates_presence_of :riddle
  validates_presence_of :location
  validates_presence_of :auth_key
  validates_presence_of :username

  def latitude
    location[1]
  end

  def longitude
    location[0]
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

  def self.find_all_local(lat, long, key)
    maxDistance = 10.0 / EARTH_RADIUS
    where(location: { '$nearSphere' => [long, lat], '$maxDistance' => maxDistance}, 
      auth_key:key)
  end

  def self.check_answer(lat, long, id)
    riddle = Riddle.find(id)
    if riddle and riddle.distance_away([lat, long]) <= 0.0378788
      riddle
    else
      nil
    end
  end
end

class AuthKey
  include MongoMapper::Document
  key :key, String
end

class Answer
  include MongoMapper::Document
  key :username, String
  key :auth_key, String
  key :location, Array
  timestamps!
  ensure_index [[:location, '2d']]

  validates_presence_of :auth_key
  validates_presence_of :location
  validates_presence_of :username

  def self.leaders_for_area(lat, long, key)
    maxDistance = 10.0 / EARTH_RADIUS
    answers = where(location: { '$nearSphere' => [long, lat], '$maxDistance' => maxDistance}, 
      auth_key:key)
    answers.group_by{|a| a.username}.map{|name, points| { "#{name}" => points.size }}.flatten
  end
end

class Numeric
  def to_rad
    self * Math::PI / 180
  end
end