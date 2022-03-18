require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

def open_database
    db = SQLite3::Database.new('db/databas.db')
    db.results_as_hash = true
    return db
end

helpers do
  def category_id_to_category(id)
    db = open_database
    return db.execute('SELECT name FROM category WHERE id = (?)',id)

  end
end

get('/') do
  db = open_database
  result = db.execute('SELECT * FROM resturants')
  slim(:index,locals:{todos:result})
end

get('/showlogin') do
    slim(:login)
end

get('/register') do
  slim(:register)
end

get('/admin') do
  db = open_database
  result = db.execute('SELECT * FROM resturants')
  slim(:resturant,locals:{todos:result})
end

post('/users/new')do
  username = params[:username].downcase
  password = params[:password]
  password_confirm = params[:password_confirm]
  klass = params[:klass]
  role = params[:role]
  
  db = open_database
  användare = db.execute('SELECT user_name FROM users WHERE user_name = (?)',username).first
  if användare != nil
    "Användarnamnet finns redan"
  elsif (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = open_database
    klass_id = db.execute('SELECT id FROM class WHERE name = (?)',klass).first
    db.execute('INSERT INTO users (user_name,password,role,class_id) VALUES (?,?,?,?)',username,password_digest,role,klass_id["id"].to_i)
    redirect('/')
  else
    "lösenorden matchade inte"
  end

end

post('/resturant')do
  resturant = params[:resturant]
  beskrivning = params[:beskrivning]
  kategori = params[:catagory]
  plats = params[:plats]
  bild = params[:bild]

  db = open_database
  db.execute('INSERT INTO resturants (name,location,picture,description,catagory_id) VALUES (?,?,?,?,?)',resturant,plats,bild,beskrivning,kategori)
  redirect('/')
  
end

get('/recession'){
  db = open_database
  slim(:resturant,locals:{todos:result})
}

post('/delete_resturant/:resturant')do
  resturant = params[:resturant]
  db = open_database
  db.execute('DELETE FROM resturants WHERE name = ?',resturant)
  redirect('/admin')
end

post('/login')do
    user_name = params[:user_name].downcase
    password = params[:password]
    db = open_database
    användare = db.execute('SELECT user_name FROM users WHERE user_name = (?)',user_name).first
    if användare == nil
      "Användarnamnet finns inte"
    else
      db = open_database
      result = db.execute('SELECT * FROM users WHERE user_name = ?',user_name).first
      pwdigest = result['password']
      id = result['id']
      if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        redirect('/show')
      else
        "Fel lösenord"
      end
    end
  end