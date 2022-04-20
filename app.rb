require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

def right_persson(recenssion, user_id)
  db = open_database
  recenssion_user_id = db.execute('SELECT user_id FROM recenssioner WHERE title = ?', recenssion).first
  return recenssion_user_id["user_id"] == user_id
end

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
  def number_to_stars(star_number)
    stars = ""
    for i in 1..star_number do
      stars += "★"
    end
    return stars
  end
end

helpers do
  def resturant_id_to_category(id)
    db = open_database
    db.results_as_hash = false
  return db.execute('SELECT category.name FROM resturnat_category_relation INNER JOIN category ON resturnat_category_relation.category_id = category.id WHERE resturant_id = (?)',id)
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
  if role(session[:id]) == "Admin"
    db = open_database
    result = db.execute('SELECT * FROM recenssioner')
    header = "Alla recensioner"
    slim(:'recenssion/index',locals:{recenssioner:result, title:header})
    elsif session[:id] != nil
      db = open_database
      result = db.execute('SELECT * FROM recenssioner WHERE user_id = ?',session[:id])
      header = "Dina recensioner"
      slim(:'recenssion/index',locals:{recenssioner:result, title:header})
    else
    redirect('/showlogin')
  end
}

get('/recenssioner/new'){
  if role(session[:id]) != nil
    db = open_database
    result = db.execute('SELECT name FROM resturants')
    slim(:'recenssion/new',locals:{resturant_name:result})
  else
    redirect('/showlogin')
  end
}

post('/recenssioner'){
  resturang = params[:resturang]
  titel = params[:titel]
  recenssion = params[:recenssion]
  rating = params[:rating]
  user_id = session[:id]
  if params[:image] && params[:image][:filename]
    filename = params[:image][:filename]
    file = params[:image][:tempfile]
    path = "./public/uploaded_pictures/#{filename}"
    File.open(path, 'wb') do |f|
      f.write(file.read)
    end
  end
  path = "/uploaded_pictures/#{filename}"
  db = open_database
  db.execute('INSERT INTO recenssioner (user_id,resturant,stars,picture,title,recenssion) VALUES (?,?,?,?,?,?)',user_id,resturang,rating,path,titel,recenssion)
  redirect('/recenssioner/') 
}

get('/recenssion/:recenssion/edit')do
  recenssion = params[:recenssion]
  if right_persson(recenssion, session[:id])  || role(session[:id])
    db = open_database
    result = db.execute('SELECT * FROM recenssioner WHERE title = ?', recenssion).first
    slim(:'recenssion/edit',locals:{recenssion:result})
  else
    "error"
  end
end

post('/recenssion/:id/update')do
  id = params[:id]
  title = params[:titel]
  recenssion = params[:beskrivning]
  rating = params[:rating]
  bild = params[:bild] 
  user_id = session[:id]
  db = open_database
  db.execute("UPDATE recenssioner SET stars=?,picture=?,title=?,recenssion=? WHERE id = #{id}",rating,bild,title,recenssion)
  redirect('/')
end

post('/recenssion/:recenssion/delete')do
  recenssion = params[:recenssion]
  if right_persson(recenssion, session[:id])  || role(session[:id])
    db = open_database
    db.execute('DELETE FROM recenssioner WHERE title = ?',recenssion)
    redirect('/recenssioner/')
  else
    "error"
  end
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
  antal = params[:amount].to_i
  kategori = params[:sak]
  plats = params[:plats]
  bild = params[:bild]
  db = open_database

  if params[:image] && params[:image][:filename]
    filename = params[:image][:filename]
    file = params[:image][:tempfile]
    path = "./public/uploaded_pictures/#{filename}"
    File.open(path, 'wb') do |f|
      f.write(file.read)
    end
  end
  path = "/uploaded_pictures/#{filename}"
  db.execute('INSERT INTO resturants (name,location,picture,description) VALUES (?,?,?,?)',resturant,plats,path,beskrivning)
  id = db.execute('SELECT id FROM resturants WHERE name = ?',resturant).first
  db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id["id"],kategori)
  p "jag först här"
  p "jag först här"
  p "jag först här"
  p "jag först här"
  p "jag först här"
  p antal
  p antal
  p antal
  p antal

  if antal == 2
    kategori1 = params[:catagory1]
    db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id["id"],kategori1)
  elsif antal == 3
    p "jag är här"
    p "jag är här"
    p "jag är här"
    p "jag är här"
    p "jag är här"
    p "jag är här"
    p "jag är här"
    kategori1 = params[:catagory1]
    db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id["id"],kategori1)
    kategori2 = params[:catagory2]
    db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id["id"],kategori2)
  end

  

  redirect('/')
  
end

get('/resturant/')do
  if role(session[:id]) == "Admin"
    db = open_database
    result = db.execute('SELECT * FROM resturants')
    slim(:'resturants/index',locals:{resturants:result})
  else
    redirect('/showlogin')
  end
end
get('/resturant/new')do
  if role(session[:id]) != nil
    slim(:'resturants/new')
  else
    redirect('/showlogin')
  end
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