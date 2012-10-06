EARTH_RADIUS = 3959.0

class AITPContest < Sinatra::Base
  register Sinatra::Contrib

  before do
    if !params[:auth_key] || !AuthKey.first(key: params[:auth_key])
      halt 403, 'Invalid auth key.'
    end
  end

  configure do
    mongo_url = ENV['MONGOHQ_URL']

    MongoMapper.connection = Mongo::Connection.from_uri mongo_url
    MongoMapper.database = URI.parse(mongo_url).path.gsub(/^\//, '')
    require './models'
  end

  post "/create_riddle" do
    riddle = params[:riddle]
    auth_key = params[:auth_key]
    latitude = params[:latitude]
    longitude = params[:longitude]
    username = params[:username]

    riddle = Riddle.new(riddle: riddle, location:[longitude.to_f, latitude.to_f], 
      auth_key: auth_key, username: username)

    respond_to do |f|
      if riddle.save
        f.json{ riddle.to_json }
        f.xml { riddle.to_xml }
      else
        f.json { halt 500, riddle.errors.to_json }
        f.xml { halt 500, riddle.errors.to_xml }
      end
    end
  end

  post '/answer' do
    auth_key = params[:auth_key]
    riddle_id = params[:riddle_id]
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f
    username = params[:username]

    riddle = Riddle.check_answer(latitude, longitude, riddle_id)

    respond_to do |f|
      if riddle
        ans = Answer.new(auth_key: auth_key, username: username, location:[longitude, latitude])
        if ans.save
          f.json{ ans.to_json }
          f.xml { ans.to_xml }
        else
          f.json{ ans.errors.to_json }
          f.xml { ans.errors.to_xml }
        end
      else
        halt 404
      end
    end
  end

  get '/local_riddles' do
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f
    auth_key = params[:auth_key]
    
    riddles = Riddle.find_all_local(latitude, longitude, auth_key).to_a
    respond_to do |f|
      f.json { riddles.to_json({only: [:id, :riddle], methods:[:latitude, :longitude]}) }
      f.xml { riddles.to_xml({only: [:id, :riddle], methods:[:latitude, :longitude]}) }
    end
  end
end