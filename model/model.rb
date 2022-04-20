module Model

    def open_database
        db = SQLite3::Database.new('db/databas.db')
        db.results_as_hash = true
        return db
    end

    def select_all_from_resturants
        db = open_database
        return db.execute('SELECT * FROM resturants')
    end

    def right_persson(recenssion, user_id)
        db = open_database
        recenssion_user_id = db.execute('SELECT user_id FROM recenssioner WHERE title = ?', recenssion).first
        return recenssion_user_id["user_id"] == user_id
    end

    def get_all_from_user(input_user_name)
        db = open_database
        return db.execute('SELECT * FROM users WHERE user_name = (?)',input_user_name).first
    end

    def incert_into_users(klass,username,password,role)
        db = open_database
        password_digest = BCrypt::Password.create(password)
        klass_id = db.execute('SELECT id FROM class WHERE name = (?)',klass).first
        db.execute('INSERT INTO users (user_name,password,role,class_id) VALUES (?,?,?,?)',username,password_digest,role,klass_id["id"].to_i)
        return db.execute('SELECT id FROM users WHERE user_name = ?',username).first
    end

    def select_all_from_recenssioner(condition, is)
        db = open_database
        if condition != nil
        return db.execute("SELECT * FROM recenssioner WHERE #{condition} = ?",is)
        else
        return db.execute('SELECT * FROM recenssioner')
        end
    end

    def delete_resturant(resturant)
        db = open_database
        db.execute('DELETE FROM resturants WHERE name = ?',resturant)
    end

    def select_name_from_resturants()
        db = open_database
        return db.execute('SELECT name FROM resturants')
    end

    def incert_into_recenssion(user_id,resturang,rating,path,titel,recenssion)
        db = open_database
        db.execute('INSERT INTO recenssioner (user_id,resturant,stars,picture,title,recenssion) VALUES (?,?,?,?,?,?)',user_id,resturang,rating,path,titel,recenssion)
    end



    def password_match(pwdigest, password)
        return BCrypt::Password.new(pwdigest) == password
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
    # En komentar
    def innerjoin(id)
        db = open_database
        db.results_as_hash = false
        return db.execute('SELECT category.name FROM resturnat_category_relation INNER JOIN category ON resturnat_category_relation.category_id = category.id WHERE resturant_id = (?)',id)
      end

    def delete_recensson(recenssion)
        db = open_database
        db.execute('DELETE FROM recenssioner WHERE title = ?',recenssion)
    end

    def update_recenssion(rating,bild,title,recenssion,id)
        db = open_database
        db.execute("UPDATE recenssioner SET stars=?,picture=?,title=?,recenssion=? WHERE id = #{id}",rating,bild,title,recenssion)
    end
end
