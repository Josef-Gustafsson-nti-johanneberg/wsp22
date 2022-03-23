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

def role(id)
  db = open_database
  result = db.execute('SELECT role FROM users WHERE id = (?)',id).first
  if result == nil
    return nil
  else
    return result["role"]
  end
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
  slim(:index,locals:{resturants:result})
end

get('/showlogin') do
  slim(:login)
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
        redirect('/')
      else
        "Fel lösenord"
      end
    end
end

get('/destroy')do
  session.destroy
  redirect('/')
end

# recenssioner
get('/recenssioner/'){
  # if role(session[:id]) == "Admin"
    db = open_database
    result = db.execute('SELECT * FROM recenssioner')
    slim(:'recenssion/index',locals:{recenssioner:result})  
  # else
  #   redirect('/showlogin')
  # end
}

get('/recenssioner/new'){
  # if role(session[:id]) != nil
    db = open_database
    result = db.execute('SELECT name FROM resturants')
    slim(:'recenssion/new',locals:{resturant_name:result})
  # else
  #   redirect('/showlogin')
  # end
}

post('/recenssioner'){
  resturang = params[:resturang]
  titel = params[:titel]
  recenssion = params[:recenssion]
  rating = params[:rating]
  bild = params[:bild] 
  user_id = session[:id]

  db = open_database
  db.execute('INSERT INTO recenssioner (user_id,resturant,stars,picture,title,recenssion) VALUES (?,?,?,?,?,?)',user_id,resturang,rating,bild,titel,recenssion)
  redirect('/recenssioner/') 
}

get('/recenssion/:recenssion/edit')do
  recenssion = params[:recenssion]
  db = open_database
  result = db.execute('SELECT * FROM recenssioner WHERE title = ?', recenssion).first
  slim(:'recenssion/edit',locals:{recenssion:result})
end

post('/recenssion/:recenssion/update')do
  id = params[:id]
  titel = params[:titel]
  recenssion = params[:beskrivning]
  rating = params[:rating]
  bild = params[:bild] 
  user_id = session[:id]
  db = open_database
  db.execute("UPDATE recenssioner WHERE id = #{title} SET name=?, location=?,picture=?,description=?,catagory_id=?",resturant,plats,bild,beskrivning,kategori)
  redirect('/')
end

#users
get('/users/new') do
  slim(:'users/new')
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
    id = db.execute('SELECT id FROM users WHERE user_name = ?',username).first
    session[:id] = id["id"]
    redirect('/')
  else
    "lösenorden matchade inte"
  end

end

# Resturanger

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

get('/resturant/')do
  # if role(session[:id]) == "Admin"
    db = open_database
    result = db.execute('SELECT * FROM resturants')
    slim(:'resturants/index',locals:{resturants:result})
  # else
  #   redirect('/showlogin')
  # end
end
get('/resturant/new')do
  # if role(session[:id]) != nil
    slim(:'resturants/new')
  # else
  #   redirect('/showlogin')
  # end
end

get('/resturant/:resturant')do
  db = open_database
  resturant = params[:resturant]
  ratings = db.execute('SELECT * FROM recenssioner WHERE resturant=?', resturant)
  result = db.execute('SELECT * FROM resturants WHERE name = ?', resturant).first
  slim(:'resturants/show',locals:{resturant:result, ratings:ratings})
end

get('/resturant/:resturant/edit')do
  resturant = params[:resturant]
  db = open_database
  result = db.execute('SELECT * FROM resturants WHERE name = ?', resturant).first
  slim(:'resturants/edit',locals:{resturant:result})
end

post('/resturant/:resturant/update')do
  resturant = params[:resturant]
  beskrivning = params[:beskrivning]
  kategori = params[:catagory]
  plats = params[:plats]
  bild = params[:bild]
  db = open_database
  db.execute("UPDATE resturants WHERE name = #{resturant} SET name=?, location=?,picture=?,description=?,catagory_id=?",resturant,plats,bild,beskrivning,kategori)
  redirect('/')
end

post('/resturant/:resturant/delete')do
  resturant = params[:resturant]
  db = open_database
  db.execute('DELETE FROM resturants WHERE name = ?',resturant)
  redirect('/resturant/')
end