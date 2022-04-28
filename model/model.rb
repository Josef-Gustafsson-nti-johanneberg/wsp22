module Model
    # Öppnar databasen
    # 
    # @return [database] innehåller en koppling till databasen 
    def open_database
        db = SQLite3::Database.new('db/databas.db')
        db.results_as_hash = true
        return db
    end

    # Jämför om ett krypterat lösenord och ett lösenord matchat
    # 
    # @param [string] pwdigest Det krypterade lösenordet
    # @param [string] password Det inskrivna lösenordet
    # 
    # @return [boolean] om det matchar eller inte
    def password_match(pwdigest, password)
        return BCrypt::Password.new(pwdigest) == password
    end
    
    # kollar upp rollen som en användare med ett visst id har 
    # 
    # @param [integer] id Är id på den användare man vill kolla rollen på
    # 
    # @return [nil] om ingen användare hittades
    # @return [string] Med användar rollen om användaren finns
    def role(id)
        db = open_database
        result = db.execute('SELECT role FROM users WHERE id = (?)',id).first
        if result == nil
            return nil
        else
            return result["role"]
        end
    end

    # Hämtar all information från resturants tabellen
    # 
    # @return [hash]
    #   * :name [string] Namnet på resturangen
    #   * :id [integer] Id på resturangen
    #   * :location [string] Addresesn som resturangen ligger på
    #   * :picture [string] Sökvägen till bilden
    #   * :description [string] Brödtexten som beskriver resturangen
    # @return [nil] if not found
    def select_all_from_resturants
        db = open_database
        return db.execute('SELECT * FROM resturants')
    end

    # Hämtar all information från den första resturangen i resturants tabellen där resturants name är name
    # 
    # @param [string] name namnet på den resturang man vill hämta all data från
    # 
    # @return [hash]
    #   * :name [string] Namnet på resturangen
    #   * :id [integer] Id på resturangen
    #   * :location [string] Addresesn som resturangen ligger på
    #   * :picture [string] Sökvägen till bilden
    #   * :description [string] Brödtexten som beskriver resturangen
    # @return [nil] if not found
    def select_all_from_resturants_where_resturant_name(name)
        db = open_database
        result = db.execute('SELECT * FROM resturants WHERE name = ?', name).first
    end

    # Hämtar all information frpn users tabellen där user_name är input_user_name
    # 
    # @param [string] input_user_name Username på den man vill hämta information om
    # 
    # @return [hash]
    # * :password [string] användarens lösenor
    # * :user_name [string] användarens användarnamn
    # * :class_id [integer] användarens klass id
    # * :id [integer] användarens id
    # * :role [string] användarens roll
    # @return [nil] if not found
    def get_all_from_user(input_user_name)
        db = open_database
        return db.execute('SELECT * FROM users WHERE user_name = (?)',input_user_name).first
    end

    # Hämtar all information från recenssioner om man skickar in nil, annars skickar tillbaka det man specifecerar med where och is
    # 
    # @param [string] condition Man kan spesificera villken column man vill kolla efter
    # @param [string] is Vad en specefik column ska vara lika med
    # 
    # @return [hash]
    #   * :id [integer] Id på recenssionen
    #   * :user_id [integer] Id på den som skrev recenssionen
    #   * :resturant [string] Resturangen som recensionen handlar om
    #   * :stars [integer]  Hur många stjärnor resturangen får
    #   * :picture [string] Sökvägen till bilden
    #   * :title [string] Rubriken på recensionen
    #   * :recenssion [string] Brödtext med recension
    # @return [nil] if not found
    def select_all_from_recenssioner(condition, is)
        db = open_database
        if condition != nil
            return db.execute("SELECT * FROM recenssioner WHERE #{condition} = ?",is)
        else
            return db.execute('SELECT * FROM recenssioner')
        end
    end

    # Hämtar alla name från resturants tabellen
    # 
    # @return [hash]
    #  * :name[string] Namnet på resturangen
    # @return [nil] if not found
    def select_name_from_resturants()
        db = open_database
        return db.execute('SELECT name FROM resturants')
    end

    # Hämtar id från en resturang där name är resturant
    # 
    # @param [string] resturant Name på den resturant id man vill hämta
    # 
    # @return [hash]
    #  * :id [integer] Id på resturangen
    # @return [nil] if not found
    def get_id_from_resturants(resturant)
        db = open_database
        return db.execute('SELECT id FROM resturants WHERE name = ?',resturant).first
    end

    # Kollar om det är samma persson som har skrivit recenssionen som skickas med
    # 
    # @param [string] recenssion Är title på recenssionen
    # @param [integer] user_id Är id på användaren
    # 
    # @return [boolean] om de är samma eller inte
    def right_persson(recenssion, user_id)
        db = open_database
        recenssion_user_id = db.execute('SELECT user_id FROM recenssioner WHERE title = ?', recenssion).first
        return recenssion_user_id["user_id"] == user_id
    end

    # skapar en ny rad med information i users tabellen och skickar tillbaka id som den blev tilldelad
    #
    # @param [string] klass Är klassen som användaren går i
    # @param [string] username Är användarnamnet som användaren valde
    # @param [string] password Är lösenordet som användaren valde
    # @param [string] role Är rollen som användaren valde
    #
    # @return [integer] skickar tillbaka id på den nya användaren
    def incert_into_users(klass,username,password,role)
        db = open_database
        password_digest = BCrypt::Password.create(password)
        klass_id = db.execute('SELECT id FROM class WHERE name = (?)',klass).first
        db.execute('INSERT INTO users (user_name,password,role,class_id) VALUES (?,?,?,?)',username,password_digest,role,klass_id["id"].to_i)
        return db.execute('SELECT id FROM users WHERE user_name = ?',username).first
    end

    # skapar en ny rad med information i recenssioner tabellen
    #
    # @param [integer] user_id Är user_id som skapade recenssionen
    # @param [string] resturang Är resturang namnet som recenseras
    # @param [integer] rating Är ett tal mellan 1-5 som motsvarar hur många stjärnor resturangen fick
    # @param [string] path Är sökvägen till den bild som användes till recensionen
    # @param [string] recenssion Är brödtexten i recensionen
    def incert_into_recenssion(user_id,resturang,rating,path,titel,recenssion)
        db = open_database
        db.execute('INSERT INTO recenssioner (user_id,resturant,stars,picture,title,recenssion) VALUES (?,?,?,?,?,?)',user_id,resturang,rating,path,titel,recenssion)
    end

    # skapar en ny rad med information i resturants tabellen
    #
    # @param [string] resturant Resturang namnet
    # @param [string] plats Vart resturangen ligger
    # @param [string] path Sökvägen till tillhörande bild på resturangen
    # @param [string] beskrivning Beskrivning om resturangen
    def incert_into_resturants(resturant,plats,path,beskrivning)
        db = open_database
        db.execute('INSERT INTO resturants (name,location,picture,description) VALUES (?,?,?,?)',resturant,plats,path,beskrivning)
    end
      
    # skapar en ny rad med information i resturnat_category_relation tabellen
    #
    # @param [integer] id Är id på resturangen 
    # @param [integer] id Är id på kategorin 
    def incert_into_resturnat_category_relation(id,kategori)
        db = open_database
        db.execute('INSERT INTO resturnat_category_relation(resturant_id,category_id) VALUES (?,?)',id,kategori)
    end

    # Tar bort en resturang med namne resturant
    # 
    # @param [string] resturant Namnet på resturangen
    def delete_resturant(resturant)
        db = open_database
        db.execute('DELETE FROM resturants WHERE name = ?',resturant)
    end
    
    # Tar bort en recension med title recenssion
    # 
    # @param [string] resturant Namnet på resturangen
    def delete_recensson(recenssion)
        db = open_database
        db.execute('DELETE FROM recenssioner WHERE title = ?',recenssion)
    end

    # Hämtar category.name ifrån resturnat_category_relation tabellen där resturant_id är lika med id
    # 
    # @param [integer] id Id på den resturang som man vill hämta kategorier på
    # 
    # @return [hash]
    #  * :name[string] Namnet på kategorin
    def innerjoin(id)
        db = open_database
        db.results_as_hash = false
        return db.execute('SELECT category.name FROM resturnat_category_relation INNER JOIN category ON resturnat_category_relation.category_id = category.id WHERE resturant_id = (?)',id)
    end

    # Uppdaterar en rad i recenssion tabellen
    # 
    # @param [integer] rating Är ett tal mellan 1-5 som motsvarar hur många stjärnor resturangen fick
    # @param [string] bild Är sökvägen till den bild som användes till recensionen
    # @param [string] title Är titlen på recenssionen
    # @param [string] recenssion Är brödtexten i recensionen
    # @param [integer] id Är id på orginalrecensionen 
    def update_recenssion(rating,bild,title,recenssion,id)
        db = open_database
        db.execute("UPDATE recenssioner SET stars=?,picture=?,title=?,recenssion=? WHERE id = #{id}",rating,bild,title,recenssion)
    end
end