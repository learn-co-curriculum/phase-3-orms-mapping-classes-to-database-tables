# ORM: Mapping Ruby Classes to Database Tables

## Objectives

1. Understand the concept of mapping a Ruby class to a database table and an instance of a class to a table row.
2. Learn how to write code that maps a Ruby class to a database table. 
3. Learn how to write code that inserts data regarding an instance of a class into a database table row. 

## Mapping a Class to a Table

When building an ORM to connect our Ruby program to a database, we equate a class with a database table and the instances that the class produces to rows in that table. 

Let's say we are building a music player app that allows users to store their music and browse their songs by song.

This program will have a `Song` class. Each song instance will have a name and an album attribute. 

```ruby
class Song

  attr_accessor :name, :album
  
  def initialize(name, album)
    @name = name
    @album = album
  end

end
```

Here we have an `attr_accessor` for `name` and `album`. In order to "map" this `Song` class to a songs database table, we need to create our database, then we need to create our songs table. 

### Creating the Database

Before we can create a songs table we need to create our music database. Whose responsibility is it create the database? It is not the responsibility of our `Song` class. Remember, classes are mapped to *tables inside a database*, not to the database as a whole. We may want to build other classes that we equate with other database tables later on. 

It is the responsibility of our program as a whole to create and establish the database. Accordingly, you'll see our Ruby programs set up such that they have a `config` directory that contains an `environment.rb` file. This file will look something like this:

```ruby
require 'sqlite3'
require_relative '../lib/song.rb'

DB = {:conn => SQLite3::Database.new("db/music.db")}
```

Here we set up a constant, `DB`, that is equal to a hash that contains our connection to the database. In our `lib/song.rb` file, we can therefore access the `DB` constant and the database connection it holds like this:

```ruby
DB[:conn]
```

So, as we move through this reading, let's assume that our hypothetical program has just such a `config/environment.rb` file and that the `DB[:conn]` constant refers to our connection to the database. 

Now that our hypothetical database is set up in our hypothetical program, let's move on to our `Song` class and it's equivalent database table. 

### Creating the Table

According to the ORM convention in which a class is mapped to or equated with a database table, we need to create a songs table. We will accomplish this by writing a class method in our `Song` class that creates this table. 

**To "map" our class to a database table, we will create a table with the same name as our class and give that table column names that match the `attr_accessor`s of our class.**

Here's an example of a `Song` class that maps instance attributes to table columns:

```ruby
class Song

  attr_accessor :name, :album
  
  attr_reader :id
  
  def initialize(name, album, id=nil)
    @id = id
    @name = name
    @album = album
  end
  
  def self.create_table
    sql =  <<- SQL 
      CREATE TABLE IF NOT EXISTS songs (
        id PRIMARY KEY INTEGER, 
        name TEXT, 
        album TEXT
        )
        SQL
    DB[:conn].execute(sql) 
  end

end
```

Let's break down this code.

#### The `id` Attribute

Notice that we are initializing an individual `Song` instance with an `id` attribute that has a default value of `nil`. Why are we doing this? First of all, songs need an `id` attribute only because they will saved into the database and we know that each table row needs an `id` value which is the primary key. 

When we create a new song with the `Song.new` method, we *do not set that song's id*. A song gets an `id` only when it gets saved into the database (more on inserting songs into the database later). We therefore set the default value of the `id` argument that the `#initialize` method takes equal to `nil`, so that we can create new song instances that *do not have an `id` value. We'll leave that up to the database to handle later on. 

Similarly, we do not have an `attr_accessor` for `id`, because we never want to set or change a song's `id` manually. The database alone is responsible for setting a song's `id`. We'll learn how later on. 

#### The `#create_table` Method

Above, we created a class method, `#create_table`, that crafts a SQL statement to create a songs table and give that table column names that match the attributes of an individual instance of `Song`. Why is the `#create_table` method a class method? Well, it is *not* the responsibility of an individual song to create the table it will eventually be saved into. It is the job of the class as a whole to create the table that it is mapped to. 

**Top-Tip:** For strings that will take up multiple lines in your text editor, use a [heredoc](https://en.wikipedia.org/wiki/Here_document) to create a string that runs on to multiple lines. To create a heredoc, we use:

`<<-` + `name of language contained in our multiline statement` + `the string, on multiple lines` + `name of language`. 

You don't have to use a heredoc, it's just a helpful too for crafting long strings in Ruby. Back to our regularly scheduled programming...

Now that our songs table exists, we can learn how to save data regarding individual songs into that table. 

## Mapping Class Instances to Table Rows: Writing a `#save` method to `INSERT` data into the table

When we say that we are saving data to our database, what data are we referring to? If individual instances of a class are "mapped" to rows in  a table, does that mean that the instances themselves, these individual Ruby objects, are saved into the database?

Actually, **we are not saving Ruby objects in our database.** We are going to take the individual attributes of a given instance, in this case a song's name and album, and save *those attributes that describe an individual song* to the database, as one, single row.

Let's built an instance method, `#save`, that saves a given instance of our `Song` class into the songs table of our database:

```ruby
class Song

  def save
    sql = <<- SQL
      INSERT INTO songs (name, album) 
      VALUES (?, ?)
    SQL
    
    DB[:conn].execute(sql, #{self.name}, #{self.album})
    
  end
end
``` 

Let's break down the code in this method. 

### The `#save` Method

In order to `INSERT` data into our songs table, we need to craft a SQL `INSERT` statement. Ideally, it would look something like this:

```sql
INSERT INTO songs (name, album)
VALUES <the given song's name>, <the given song's album>
```

Above, we used the heredoc to craft our multi-line SQL statement. How are we going to pass in, or interpolate, the name and album of a given song into our heredoc? 

We use something called **bound parameters**. 

#### Bound Parameters

Bound parameters protect our program from getting confused by SQL injections and special characters. Instead of interpolating variables into a string of SQL, we are using the `?` characters as placeholders. Then, the special magic provided to us by the SQLite3-Ruby gem's `#execute` method will take the values we pass in as an argument and apply them as the values of the question marks. 

#### How it works

So, our `#save` method inserts a record into our database that has the name and album values of the song instance we are trying to save. We are not saving the Ruby object itself. We are creating a new row in our songs table that has the values that characterize that song instance. 

**Important:** Notice that we *didn't* insert an ID number into the table with the above statement. Remember that the `INTEGER PRIMARY KEY` datatype will assign and auto-increment the id attribute of each record that gets saved.

## Creating Instances vs. Creating Table Rows

The moment in which we create a new `Song` instance with the `#new` method is *different than the moment in which we save a representation of that song to our database*. The `#new` method creates a new instance of the song class, a new Ruby object. The `#save` method takes the attributes that characterize a given song and save it to the songs table in our database as its own table row. 

We can make our own decisions about when and where to call the `#save` method. You could choose to call that method *inside the initialize method*, to automatically save a song's information to the database as soon as that new song instance is created. Or, we could collect all of our song instances in an class variable, `@@all`, and save the members of that collection at a later time. 

Let's take a look at that option now:

```ruby
class Song
  
  @@all = []

  attr_accessor :name, :album
  
  attr_reader :id
  
  def initialize(name, album, id=nil)
    @id = id
    @name = name
    @album = album
    @@all << self
  end
  
  def self.create_table
    sql =  <<-SQL 
      CREATE TABLE IF NOT EXISTS songs (
        id PRIMARY KEY INTEGER, 
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
    
    DB[:conn].execute(sql, #{self.name}, #{self.album})
    
  end
  
  def self.all
    @@all
  end

end
```

Now, we can create and save songs like this:

```ruby
Song.create_table
Song.new("Hello", "25")
Song.new("99 Problems", "The Black Album")

Song.all.each do |song|
  song.save
end
```

Here we:

* Create the songs table. 
* Create two new song instances. 
* Iterate over our collection of song instances stored in `Song.all` and use the `song.save` method to persist them to the database. 

## Conclusion

The important concept to grasp here, and it's not easy, is the idea that we are *not* saving Ruby objects into our database. We are using the attributes of a given Ruby object to create a new row in our database table. 

Think of it like a game of legos. You have a brand new lego box set to create a lego spaceship. The box comes with legos and instructions. The instructions are like the class, they are the directions for creating new spaceships. The box is like the database, it stores your legos.

You follow the instructions and create a new spaceship object out of individual legos. Then, your parents tell you it is time for bed and you need to put away your legos. You dismantle your spaceship back into its constituent parts and store them in the box––your database. The box doesn't fit the *entire assembled spaceship*, you have to break it down into the pieces out of which you made it and store those instead. 





