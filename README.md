# ORM: Mapping Ruby Classes to Database Tables

## Objectives

1. Map a Ruby class to a database table and an instance of a class to a table row.
2. Write code that maps a Ruby class to a database table. 
3. Write code that inserts data regarding an instance of a class into a database table row. 

## Mapping a Class to a Table

When building an ORM to connect our Ruby program to a database, we equate a class with a database table and the instances that the class produces to rows in that table. 

Why map classes to tables? Our end goal is to persist information regarding songs to a database. In order to persist that data efficiently and in an organized manner, we need to first map or equate our Ruby class to a database table. 

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

Here we have an `attr_accessor` for `name` and `album`. In order to "map" this `Song` class to a songs database table, we need to create our database, then we need to create our songs table. In building an ORM, it is conventional to pluralize the name of the class to create the name of the table. Therefore, the `Song` class equals the "songs" table.

### Creating the Database

Before we can create a songs table we need to create our music database. Whose responsibility is it to create the database? It is not the responsibility of our `Song` class. Remember, classes are mapped to *tables inside a database*, not to the database as a whole. We may want to build other classes that we equate with other database tables later on. 

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

Now that our hypothetical database is set up in our hypothetical program, let's move on to our `Song` class and its equivalent database table. 

### Creating the Table

According to the ORM convention in which a class is mapped to or equated with a database table, we need to create a songs table. We will accomplish this by writing a class method in our `Song` class that creates this table. 

**To "map" our class to a database table, we will create a table with the same name as our class and give that table column names that match the `attr_accessor`s of our class.**

Here's an example of a `Song` class that maps instance attributes to table columns:

```ruby
class Song

  attr_accessor :name, :album, :id
  
  def initialize(name, album, id=nil)
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

end
```

Let's break down this code.

#### The `id` Attribute

Notice that we are initializing an individual `Song` instance with an `id` attribute that has a default value of `nil`. Why are we doing this? First of all, songs need an `id` attribute only because they will be saved into the database and we know that each table row needs an `id` value which is the primary key. 

When we create a new song with the `Song.new` method, we *do not set that song's id*. A song gets an `id` only when it gets saved into the database (more on inserting songs into the database later). We therefore set the default value of the `id` argument that the `#initialize` method takes equal to `nil`, so that we can create new song instances that *do not have an `id` value. We'll leave that up to the database to handle later on. Why leave it up to the database? Remember that in the world of relational database, the `id` of a given record must be unique. If we could replicate a record's `id`, we would have a very disorganized database. Only the database itself, through the magic of SQL, can ensure that the `id` of each record is unique. 

#### The `.create_table` Method

Above, we created a class method, `.create_table`, that crafts a SQL statement to create a songs table and give that table column names that match the attributes of an individual instance of `Song`. Why is the `.create_table` method a class method? Well, it is *not* the responsibility of an individual song to create the table it will eventually be saved into. It is the job of the class as a whole to create the table that it is mapped to. 

**Top-Tip:** For strings that will take up multiple lines in your text editor, use a [heredoc](https://en.wikipedia.org/wiki/Here_document) to create a string that runs on to multiple lines. To create a heredoc, we use:

`<<-` + `name of language contained in our multiline statement` + `the string, on multiple lines` + `name of language`. 

You don't have to use a heredoc, it's just a helpful tool for crafting long strings in Ruby. Back to our regularly scheduled programming...

Now that our songs table exists, we can learn how to save data regarding individual songs into that table. 

## Mapping Class Instances to Table Rows

When we say that we are saving data to our database, what data are we referring to? If individual instances of a class are "mapped" to rows in  a table, does that mean that the instances themselves, these individual Ruby objects, are saved into the database?

Actually, **we are not saving Ruby objects in our database.** We are going to take the individual attributes of a given instance, in this case a song's name and album, and save *those attributes that describe an individual song* to the database, as one, single row.

For example, let's say we have a song:

```ruby
gold_digger = Song.new("Gold Digger", "Late Registration")

gold_digger.name
# => "Gold Digger"

gold_digger.album
# => "Late Registration" 
```

This song has it's two attributes, `name` and `album`, set equal to the above values. In order to save the song `gold_digger` into the songs table, we will use the name and album of the song to create a new row in that table. The SQL statement we want to execute would look something like this:

```ruby
INSERT INTO songs (name, album) VALUES ("Gold Digger", "Late Registration")
```

What if we had another song that we wanted to save?

```ruby
hello = Song.new("Hello", "25")

hello.name 
# => "Hello"

hello.album
# => "25"
```

In order to save `hello` into our database, we do not insert the Ruby object stored in the `hello` variable. Instead, we use `hello`'s name and album values to create a new row in the songs table:

```ruby
INSERT INTO songs (name, album) VALUES ("Hello", "25")
```

We can see that the operation of saving the attributes of a particular song into a database table is common enough. Every time we want to save a record, though, we are repeating the same exact steps and using the same code. The only thing that is different are the values that we are inserting into our songs table. Let's abstract this functionality into an instance method, `#save`. 

### Inserting Data into a table with the `#save` Method

Let's built an instance method, `#save`, that saves a given instance of our `Song` class into the songs table of our database. 

```ruby
class Song

  def save
    sql = <<- SQL
      INSERT INTO songs (name, album) 
      VALUES (?, ?)
    SQL
    
    DB[:conn].execute(sql, self.name, self.album)
    
  end
end
``` 

Let's break down the code in this method. 

#### The `#save` Method

In order to `INSERT` data into our songs table, we need to craft a SQL `INSERT` statement. Ideally, it would look something like this:

```sql
INSERT INTO songs (name, album)
VALUES <the given song's name>, <the given song's album>
```

Above, we used the heredoc to craft our multi-line SQL statement. How are we going to pass in, or interpolate, the name and album of a given song into our heredoc? 

We use something called **bound parameters**. 

#### Bound Parameters

Bound parameters protect our program from getting confused by [SQL injections](https://en.wikipedia.org/wiki/SQL_injection) and special characters. Instead of interpolating variables into a string of SQL, we are using the `?` characters as placeholders. Then, the special magic provided to us by the SQLite3-Ruby gem's `#execute` method will take the values we pass in as an argument and apply them as the values of the question marks. 

#### How it works

So, our `#save` method inserts a record into our database that has the name and album values of the song instance we are trying to save. We are not saving the Ruby object itself. We are creating a new row in our songs table that has the values that characterize that song instance. 

**Important:** Notice that we *didn't* insert an ID number into the table with the above statement. Remember that the `INTEGER PRIMARY KEY` datatype will assign and auto-increment the id attribute of each record that gets saved.

## Creating Instances vs. Creating Table Rows

The moment in which we create a new `Song` instance with the `#new` method is *different than the moment in which we save a representation of that song to our database*. The `#new` method creates a new instance of the song class, a new Ruby object. The `#save` method takes the attributes that characterize a given song and save it to the songs table in our database as its own table row. 

At what point in time should we actually save a new record? While it is possible to save the record right at the moment the new object is created, i.e. in the `#initialize` method, this is not a great idea. We don't want to force our objects to be saved every time they are created, or make the creation of an object dependent upon/always coupled with saving a record to the database. As our program grows and changes, we may find the need to create objects and not save them. A dependency between instantiating an object and saving that record to the database would preclude this or, at the very least, make it harder to implement. 

So, we'll keep our `#initialize` and `#save` methods separate:

```ruby
class Song
 
  attr_accessor :name, :album, :id
  
  def initialize(name, album, id=nil)
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
    
    DB[:conn].execute(sql, self.name, self.album)
    
  end

end
```

Now, we can create and save songs like this:

```ruby
Song.create_table
hello = Song.new("Hello", "25")
ninety_nine_problems = Song.new("99 Problems", "The Black Album")

hello.save
ninety_nine_problems.save
```

#### Giving Our `Song` Instance an `id` 

When we `INSERT` the data concerning a particular `Song` instance into out database table, we create a new row in that table. That row would look something like this:

| ID | Name | Album|
|----|------|------|
| 1  | Hello| 25     |

Notice that the database table's row has a column for `Name`, `Album` and also `ID`. Recall that we created our table to have a column for the primary key, ID, of a given record. So, as each record gets inserted into the database, it is given an ID number automatically. 

In this way, our `hello` instance is stored in the database with the name and album that we gave it, *plus* an ID number that the database assigns to it. 

We want our `hello` instance to completely reflect the database row it is associated it, so that we can retrieve it from the table later on with ease. So, once the new row with `hello`'s data is inserted into the table, let's grab the `ID` of that newly inserted row and assign it to be the value of `hello`'s `id` attribute. 

```ruby
class Song

  attr_accessor :name, :album, :id
  
  def initialize(name, album, id=nil)
    @id = id
    @name = name
    @album = album
  end

  def save
    sql = <<- SQL
      INSERT INTO songs (name, album) 
      VALUES (?, ?)
    SQL
    
    DB[:conn].execute(sql, self.name, self.album)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM students")[0][0]
    
  end
```

At the end of our `save` method, we use a SQL query to grab the value of the `ID` column of the last inserted row, and set that equal to the given song instance's `id` attribute. Don't worry too much about how that SQL query works for now, we'll learn more about it later. The important thing to understand is the process of:

* Instantiating a new instance of the `Song` class
* Inserting a new row into the database table that contains the information regarding that instance
* Grabbing the `ID` of that newly inserted row and assigned the given `Song` instance's `id` attribute equal to the `ID` of its associated database table row. 

Let's revisit our code that instantiated and saved some songs:

```ruby
Song.create_table
hello = Song.new("Hello", "25")
ninety_nine_problems = Song.new("99 Problems", "The Black Album")

hello.save
ninety_nine_problems.save
```

Here we:

* Create the songs table. 
* Create two new song instances. 
* Use the `song.save` method to persist them to the database.

This approach still leaves a little to be desired, however. Here, we have to first create the new song and then save it, every time we want to create and save a song. This is repetitive and tedious. As programmers (you might remember), we are lazy. If we can accomplish something with fewer lines of code we do it. **Any time we see the same code being used again and again, we think about abstracting that code into a method.**

Since first creating an object and then saving a record representing that object is so common. Let's write a method that does just that. 

### The `#create` Method

This method will wrap the code we used above to create a new `Song` instance and save it. 

```ruby
class Song
  ...

  def self.create(name:, album:)
    song = Song.new(name, album)
    song.save
    song
  end
end
```

Here, we use keyword arguments to pass a name and album into our `#create` method. We use that name and album to instantiate a new song. Then, we use the `#save` method to persist that song to the database. 

Notice that at the end of the method, we are returning the `song` instance that we instantiated. The return value of `#create` should always be the object that we created. Why? Imagine you are working with your program and you create a new song:

```ruby
Song.create(name: "Hello", album: "25")
```

Now, we would have to run a separate query on our database to grab the record that we just created. That is way too much work for us. It would be much easier for our `#create` method to simply return the new object for us to work with:

```ruby
song = Song.create(name: "Hello", album: "25")
# => #<Song:0x007f94f2c28ee8 @id=1, @name="Hello", @album="25">

song.name
# => "Hello"

song.album
# => "25"
```

## Conclusion

The important concept to grasp here is the idea that we are *not* saving Ruby objects into our database. We are using the attributes of a given Ruby object to create a new row in our database table. 

Think of it like a game of legos. You have a brand new lego box set to create a lego spaceship. The box comes with legos and instructions. The instructions are like the class: they are the directions for creating new spaceships. The box is like the database: it stores your legos.

You follow the instructions and create a new spaceship object out of individual legos. Then, your parents tell you it is time for bed and you need to put away your legos. You dismantle your spaceship back into its constituent parts and store them in the box––your database. The box doesn't fit the *entire assembled spaceship*, you have to break it down into the pieces out of which you made it and store those instead. 

<p data-visibility='hidden'>View <a href='https://learn.co/lessons/orm-mapping-to-tables' title='ORM: Mapping Ruby Classes to Database Tables'>ORM: Mapping Ruby Classes to Database Tables</a> on Learn.co and start learning to code for free.</p>
