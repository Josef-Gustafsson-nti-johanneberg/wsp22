require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require './model/model.rb'

time_array = []

enable :sessions

include Model #wat dis?

# en test sak nu
#
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
    return innerjoin(id)
  end
end

def cooldown(time_array, time)
  time_array << time
  if time_array.length >=3 && time_array[-1]-time_array[-2] < 10
    return true
  else
    return false
  end
end

#Visar förstasidan på school-food som visar upp appa resturanger
#
get('/') do
  result = select_all_from_resturants()
  slim(:index,locals:{resturants:result})
end

# Visar upp inloggnings sidan där användaren får logga in
# 
get('/showlogin') do
  text = ""
  slim(:login,locals:{text:text})
end

# Loggar in användaren om användaren skriver in rätt användarnamn och lösenord. Om användaren skriver in ett användarnamn som inte finns så kommer ett felmedelande att det itne finns och om användaren skriver in fel lösenord som kommer också ett felmeddelande om det
# 
# @param [String] username, Användarnamnet som användaren skrev in
# @param [String] password, Lösenordet som användaren skrev in
post('/login')do
  time = Time.now.to_i
  input_user_name = params[:user_name].downcase
  password = params[:password]
  användare = get_all_from_user(input_user_name)
  if användare == nil
    text = "Användarnamnet finns inte"
  else
    pwdigest = användare['password']
    id = användare['id']

    if password_match(pwdigest, password)
      if cooldown(time_array, time)
        text = "För många försök, vänta 10 sekunder"
        slim(:login,locals:{text:text})
      else
        session[:id] = id
        redirect('/')
      end
    else
      text = "Fel lösenord"      
      if cooldown(time_array, time)
        text = "För många försök, vänta 10 sekunder"
        slim(:login,locals:{text:text})
      end
    end
  end
  slim(:login,locals:{text:text})
end

get('/destroy')do
  session.destroy
  redirect('/')
end



# recenssioner
get('/recenssioner/'){
  if role(session[:id]) == "Admin"
    result = select_all_from_recenssioner(nil, nil)
    header = "Alla recensioner"
    slim(:'recenssion/index',locals:{recenssioner:result, title:header})
    elsif session[:id] != nil
      result = select_all_from_recenssioner(session[:id])
      header = "Dina recensioner"
      slim(:'recenssion/index',locals:{recenssioner:result, title:header})
    else
    redirect('/showlogin')
  end
}



get('/recenssioner/new'){
  if role(session[:id]) != nil
    result = select_name_from_resturants
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
  incert_into_recenssion(user_id,resturang,rating,path,titel,recenssion)
  redirect('/recenssioner/') 
}

get('/recenssion/:recenssion/edit')do
  text = ""
  recenssion = params[:recenssion]
  if right_persson(recenssion, session[:id]) || role(session[:id])
    result = select_all_from_recenssioner("title", recenssion).first
    slim(:'recenssion/edit',locals:{recenssion:result,text:text})
  else
    text = "Vänligen logga in först"
    slim(:login,locals:{text:text})
  end
end

post('/recenssion/:id/update')do
  id = params[:id]
  title = params[:titel]
  recenssion = params[:beskrivning]
  rating = params[:rating]
  bild = params[:bild] 
  user_id = session[:id]
  if rating == ""
    text = "Fyll i alla fält"
    result = select_all_from_recenssioner("id", id).first
    slim(:'recenssion/edit',locals:{recenssion:result,text:text})
  else
    update_recenssion(rating,bild,title,recenssion,id)
    redirect('/recenssioner/')
  end
end

post('/recenssion/:recenssion/delete')do
  recenssion = params[:recenssion]
  if right_persson(recenssion, session[:id]) || role(session[:id])
    delete_recensson(recenssion)
    redirect('/recenssioner/')
  else
    text = "Vänligen logga in först"
    slim(:login,locals:{text:text})
  end
end

#users
get('/users/new') do
  text = ""
  slim(:'users/new',locals:{text:text})
end

post('/users/new')do
  username = params[:username].downcase
  password = params[:password]
  password_confirm = params[:password_confirm]
  klass = params[:klass]
  role = params[:role]
  användare = get_all_from_user(username)
  if användare != nil
    text = "Användarnamnet finns redan"
    slim(:'users/new',locals:{text:text})
  elsif (password == password_confirm)
    id = incert_into_users(klass,username,password,role)
    session[:id] = id["id"]
    redirect('/')
  else
    text = "Lösenorden matchade inte"
    slim(:'users/new',locals:{text:text})
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
  if antal == 2
    kategori1 = params[:catagory1]
    db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id["id"],kategori1)
  elsif antal == 3
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


post('/resturant/:resturant/delete')do
  resturant = params[:resturant]
  delete_resturant(resturant)
  redirect('/resturant/')
end