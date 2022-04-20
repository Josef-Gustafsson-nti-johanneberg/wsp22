
# get('/resturant/:resturant/edit')do
#   resturant = params[:resturant]
#   db = open_database
#   result = db.execute('SELECT * FROM resturants WHERE name = ?', resturant).first
#   kategori = db.execute('SELECT category_id FROM resturnat_category_relation WHERE resturant_id = ?',result["id"])[0]
#   kategori1 = db.execute('SELECT category_id FROM resturnat_category_relation WHERE resturant_id = ?',result["id"])[1]
#   kategori2 = db.execute('SELECT category_id FROM resturnat_category_relation WHERE resturant_id = ?',result["id"])[2]

#   selected = {
#     "1" => "",
#     "2" => "",
#     "3" => "",
#     "4" => "",
#     "5" => "",
#     "6" => "",
#     "7" => ""
#   }
#   selected[kategori["category_id"].to_i] = "selected"
#   p selected
#   p selected
#   p selected
 

#   slim(:'resturants/edit',locals:{resturant:result, selected:selected})
# end

# post('/resturant/:id/update')do
#   id = params[:id]
#   resturant = params[:resturant]
#   beskrivning = params[:beskrivning]
#   antal = params[:amount].to_i
#   kategori = params[:catagory]
#   plats = params[:plats]
#   bild = params[:bild]
#   db = open_database
#   db.execute("UPDATE resturants SET name=?, location=?,picture=?,description=? WHERE id = #{id}" ,resturant,plats,bild,beskrivning)


#   id = db.execute('SELECT id FROM resturants WHERE name = ?',resturant).first
#   db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id["id"],kategori)
#   if antal == 2
#     kategori1 = params[:catagory1]
#     db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id["id"],kategori1)
#   elsif antal == 3
#     kategori1 = params[:catagory1]
#     db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id["id"],kategori1)
#     kategori2 = params[:catagory2]
#     db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id["id"],kategori2)
#   end


#   redirect('/')
# end