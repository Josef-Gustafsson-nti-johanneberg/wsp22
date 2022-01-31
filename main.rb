require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
    # db = SQLite3::Database.new('db/databas.db')
    # db.results_as_hash = true
    # result = db.execute('SELECT * FROM resurants')
    slim(:index)
    # slim(:index,locals:{todos:result})
end

get('/showlogin') do
    slim(:login)
end

post('/login'){
    username = params[:username]
    password = params[:password]
    
    # db = SQLite3::Database.new('db/databas.db')
    # db.results_as_hash = true
    # result = db.execute('SELECT * FROM users WHERE username = ?',username).first
    # pwdigest = result['pwdigest']
    # id = result['id']
    # if BCrypt::Password.new(pwdigest) == password
    #   session[:id] = id
      redirect('/show')
    # else
    #   "Fel lösenord"
    # end
  
  }

