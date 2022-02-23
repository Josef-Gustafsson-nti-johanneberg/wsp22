require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
    db = SQLite3::Database.new('db/databas.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM resturants')
    # slim(:index)
    slim(:index,locals:{todos:result})
end

get('/showlogin') do
    slim(:login)
end

get('/register') do
  slim(:register)
end

post('/users/new'){
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  klass = params[:klass]
  role = params[:role]
  p role

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/databas.db')
    db.results_as_hash = true
    temp = db.execute('SELECT id FROM class WHERE name = (?)',klass).first
    p temp
    db.execute('INSERT INTO users (user_name,password,role,class_id) VALUES (?,?,?,?)',username,password_digest,role,temp["id"].to_i)
    redirect('/')
  else
    "lösenorden matchade inte"
  end

}


post('/login'){
    user_name = params[:user_name]
    password = params[:password]
    
    db = SQLite3::Database.new('db/databas.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM users WHERE user_name = ?',user_name).first
    pwdigest = result['password']
    id = result['id']
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect('/show')
    else
      "Fel lösenord"
    end
  
  }

