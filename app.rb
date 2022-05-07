require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require './model/model.rb'

time_array = []

enable :sessions

include Model #wat dis?

# Omvandlar ett heltal till en sträng med lika många stjärnor
# 
# @param [integer] star_number heltal på hur många stjärnor som ska skickas tillbaka
# 
# @return [string] En sträng returneras med stjärnor
helpers do 
  def number_to_stars(star_number)
    stars = ""
    for i in 1..star_number do
      stars += "★"
    end
    return stars
  end
end

# En hjälpfunktion som kan kommas år ifrån en slimfil
# 
# @param [integer] id heltal på ett id
# 
# @return [string] kategorin på en resturang
helpers do
  def resturant_id_to_category(id)
    return innerjoin(id)
  end
end

# En funktion som kollar hur långt det är mellan olika inlogg som har gjorts
# 
# @param [array] time_array En array som inehåller de olika tidspunkterna som någon har försökt att logga in
# @param [integer] time Ett heltal på vad tiden är vid inloggningsförsöket
# 
# @return [boolean] returnerar true eller false på om en cooldown behövs
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
# @see Model#select_all_from_resturants
get('/') do
  result = select_all_from_resturants()
  slim(:index,locals:{resturants:result})
end

# Visar upp inloggnings sidan där användaren får logga in
# 
get('/showlogin/') do
  text = ""
  slim(:login,locals:{text:text})
end

# Loggar in användaren om användaren skriver in rätt användarnamn och lösenord. Om användaren skriver in ett användarnamn som inte finns så kommer ett felmedelande att det itne finns och om användaren skriver in fel lösenord som kommer också ett felmeddelande om det. Om användaren skriver fel lösenord för många gånger så måste hen vänta 10 sekunder innan nästa försök.
# 
# @param [String] username, Användarnamnet som användaren skrev in
# @param [String] password, Lösenordet som användaren skrev in
# @see Model#get_all_from_user
# @See#cooldown
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

# Tömmer sessions när man loggar ut
# 
get('/destroy')do
  session.destroy
  redirect('/')
end

# En sida som visa alla recensioner om man är admin eller visar bara de recensioner som man själv har skrivit.
# 
# @see Model#select_all_from_recenssioner
# @see Model#role
get('/recenssioner/'){
  if role(session[:id]) == "Admin"
    result = select_all_from_recenssioner(nil, nil)
    header = "Alla recensioner"
    slim(:'recenssion/index',locals:{recenssioner:result, title:header})
    elsif session[:id] != nil
      result = select_all_from_recenssioner("user_id",session[:id])
      header = "Dina recensioner"
      slim(:'recenssion/index',locals:{recenssioner:result, title:header})
    else
    redirect('/showlogin')
  end
}

# Sidan där man kan skapa nya recenssioner om man är inloggad
# 
# @see Model#select_name_from_resturants
# @see Model#role
get('/recenssioner/new'){
  if role(session[:id]) != nil
    result = select_name_from_resturants
    slim(:'recenssion/new',locals:{resturant_name:result})
  else
    redirect('/showlogin/')
  end
}

# Skapar den recenssion som användaren vill göra
# 
# @param [string] :resturang, vilken resturang användaren recenserar
# @param [string] :title, titlen på recenssionen
# @param [string] :recenssion, själva brödtexten i recenssionen
# @param [integer] :rating, Ett tal mellan ett och fem som bedömmer resturangen
# @param [integer] :id, användarid som skapade recensionen
# @param [string] :image, bilden man laddade upp till recensionen
# @param [string] :filename, filnamnet på bilden som laddedes upp
# @param [string] :tempfile, är vart den bilden man ladde upp ligger på datort temporät
# @see Model#incert_into_recenssioner
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

# Sidan där man kan redigera en recenssion
# 
# @param [string] :recenssion, är namnet på den recensison som man vill redigera
# @see Model#right_persson
# @see Model#select_all_from_recenssioner
# @see Model#role
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

# Uppdaterar recenssionen i databasen
# 
# @param [integer] :id, recenssion id 
# @param [string] :title, titlen på recenssionen
# @param [string] :recenssion, själva brödtexten i recenssionen
# @param [integer] :rating, Ett tal mellan ett och fem som bedömmer resturangen
# @param [string] :bild, är sökvägen till bilden som användaren laddade upp
# #see Model#select_all_from_recenssioner
# #see Model#update_recenssion
# @see Model#role
# @see Model#right_persson
post('/recenssion/:id/update')do
  id = params[:id]
  title = params[:titel]
  recenssion = params[:beskrivning]
  rating = params[:rating]
  bild = params[:bild] 
  user_id = session[:id]
  if right_persson(title, session[:id]) || role(session[:id])
    if rating == ""
      text = "Fyll i alla fält"
      result = select_all_from_recenssioner("id", id).first
      slim(:'recenssion/edit',locals:{recenssion:result,text:text})
    else
      update_recenssion(rating,bild,title,recenssion,id)
      redirect('/recenssioner/')
    end
  else
    text = "Vänligen logga in först"
    slim(:login,locals:{text:text})
  end

end

# Tar bort en recenssion och leder användaren till recenssions sidan, om användaren inte får ta bort den så omleds användaren till login sidan
# 
# @param [string] :recenssion, är titlen på recenssionen
# @see Model#right_persson
# @see Model#delete_recenssion
# @see Model#role
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

# Visar sidan där man kan skapa nya användare
# 
get('/users/new') do
  text = ""
  slim(:'users/new',locals:{text:text})
end

# Skapar en ny användare och skickar användaren till startsidan som inloggad, om användarnamnet redan finns så kommer ett felmedelande att det redan finns, om lösenorden inte stämmer överens så kommer också ett felmedelande om att de inte matchar
# 
# @param [string] :username, användarnamnet man skrev in, till små bokstäver så att det inte är versal känsligt
# @param [string] :password, lösenordet som använderen skrev in
# @param [string] :password_confirm, upprepade lösenordet som användaren skrev in
# @param [string] :klass, klassen om användren klickade i
# @param [string] :role, rollen som anvnädaren fick välja
# @see Model#get_all_from_user
# @see Model#incert_into_user
post('/users')do
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

# Skapar en resturan med anvädar input data och leder till startsidan
# 
# @param [string] :resturant, namnet på resturangen
# @param [string] :beskrivning, en beskrivning på resturangen
# @param [integer] :amount, hur många kategorier som användaren lägger till på resturangen
# @param [integer] :catagory, ett kattegori id
# @param [integer] :catagory1, ett kattegori2 id
# @param [integer] :catagory2, ett kattegori3 id
# @param [string] :plats, vart resturangen ligger
# @param [string] :image, bilden man laddade upp till resturangen
# @param [string] :filename, filnamnet på bilden som laddedes upp
# @param [string] :tempfile, är vart den bilden man ladde upp ligger på datort temporät
# @see Model#incert_into_resturants 
# @see Model#get_id_from_resturants
# @see Model#incert_into_resturnat_category_relation
post('/resturant')do
  resturant = params[:resturant]
  beskrivning = params[:beskrivning]
  antal = params[:amount].to_i
  kategori = params[:catagory]
  plats = params[:plats]
  if params[:image] && params[:image][:filename]
    filename = params[:image][:filename]
    file = params[:image][:tempfile]
    path = "./public/uploaded_pictures/#{filename}"
    File.open(path, 'wb') do |f|
      f.write(file.read)
    end
  end
  path = "/uploaded_pictures/#{filename}"
  incert_into_resturants(resturant,plats,path,beskrivning)
  id = get_id_from_resturants(resturant)
  incert_into_resturnat_category_relation(id["id"],kategori)
  if antal == 2
    kategori1 = params[:catagory1]
    incert_into_resturnat_category_relation(id["id"],kategori1)
  elsif antal == 3
    kategori1 = params[:catagory1]
    incert_into_resturnat_category_relation(id["id"],kategori1)
    kategori2 = params[:catagory2]
    incert_into_resturnat_category_relation(id["id"],kategori2)
  end
  redirect('/')
end

# Sida som visar upp alla resturanger för admin så admin kan redigera och ta bort resturanger
# 
# @see Model#select_all_from_resturants
# @see Model#role
get('/resturant/')do
  if role(session[:id]) == "Admin"
    result = select_all_from_resturants()
    slim(:'resturants/index',locals:{resturants:result})
  else
    redirect('/showlogin/')
  end
end

# Sida där man kan skapa nya resturanger om man är admin
# @see Model#role
get('/resturant/new')do
  if role(session[:id]) == "Admin"
    slim(:'resturants/new')
  else
    redirect('/showlogin/')
  end
end

# En sida som visar upp en spesefic resturang samt tillhörande recenssioner.
# 
# @params [string] :resturant, resturang namnet
# @see Model#select_all_from_resturants_where_resturant_name
# @see Model#select_all_from_recenssioner
get('/resturant/:resturant')do
  resturant = params[:resturant]
  result = select_all_from_resturants_where_resturant_name(resturant)
  ratings = select_all_from_recenssioner("resturant", resturant)
  slim(:'resturants/show',locals:{resturant:result, ratings:ratings})
end

# Tar bort en resturang och skickar användaren till resturang sidan
# 
# @params [string] :resturant, resturang namnet
# @see Model#delete_resturant
post('/resturant/:resturant/delete')do
  resturant = params[:resturant]
  delete_resturant(resturant)
  redirect('/resturant/')
end