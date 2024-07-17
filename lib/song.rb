class Song

  attr_accessor :name, :album, :id

  def initialize(name:, album:, id: nil)
    @id = id
    @name = name
    @album = album
  end

  def self.create_table
    sql =  <<-SQL
      CREATE TABLE IF NOT EXISTS songs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        album TEXT
      )
      SQL
    DB[:conn].execute(sql)
  end

  def save
    sql = <<-SQL
      INSERT INTO songs (name, album)
      VALUES (?, ?)
    SQL

   DB[:conn].execute(sql, [self.name, self.album])

   self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM songs")[0][0]

   self
  end

  def self.create(name:, album:)
    song = Song.new(name: name, album: album)
    song.save
  end
end
