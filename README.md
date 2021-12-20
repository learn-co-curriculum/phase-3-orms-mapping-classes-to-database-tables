# Mapping Ruby Classes to a Database

## Learning Goals

- Write code that maps a Ruby class to a database table
- Write code that inserts data regarding an instance of a class into a database
  table row

## Introduction

When building an ORM to connect our Ruby program to a database, we equate a
**class** with a database **table** and the **instances** that the class
produces to **rows** in that table.

Why map classes to tables? Our end goal is to persist information regarding our
objects to a database. In order to persist that data efficiently and in an
organized manner, we need to first map or equate our Ruby class to a database
table.

## Writing an ORM

Let's say we are building a music player app that allows users to store their
music and browse their songs by song.

This program will have a `Song` class. Each song instance will have a name and
an album attribute. The starter code for this class is in the `lib/song.rb`
file:

```ruby
class Song

  attr_accessor :name, :album

  def initialize(name:, album:)
    @name = name
    @album = album
  end

end
```

Here we have an `attr_accessor` for `name` and `album`. In order to "map" this
`Song` class to a songs database table, we need to create our database, then we
need to create our songs table. In building an ORM, it is conventional to
pluralize the name of the class to create the name of the table. Therefore, the
`Song` class equals the "songs" table.

### Creating the Database

Before we can create a songs table we need to create our music database. Whose
responsibility is it to create the database? It is not the responsibility of our
`Song` class. Remember, classes are mapped to _tables inside a database_, not to
the database as a whole. We may want to build other classes that we equate with
other database tables later on.

It is the responsibility of our program as a whole to create and establish the
database. Accordingly, you'll see our Ruby programs set up such that they have a
`config` directory that contains an `environment.rb` file. In our application,
the file looks like this:

```ruby
require 'bundler'
Bundler.require

require_relative '../lib/song'

DB = { conn: SQLite3::Database.new("db/music.db") }
```

Here we set up a constant, `DB`, that is equal to a hash that contains our
connection to the database. In our `lib/song.rb` file, we can therefore access
the `DB` constant and the database connection it holds like this:

```ruby
DB[:conn]
```

The starter code for these files is set up, so you can explore it and code along
with the rest of this lesson.

### Creating the Table

According to the ORM convention in which a class is mapped to or equated with a
database table, we need to create a songs table. We will accomplish this by
writing a class method in our `Song` class that creates this table.

**To "map" our class to a database table, we will create a table with the same
name as our class and give that table column names that match the
`attr_accessor`s of our class.**

Update the `Song` class as follows so that it maps instance attributes to table
columns:

```ruby
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

end
```

Let's break down this code.

#### The `id` Attribute

Notice that we are initializing an individual `Song` instance with an `id`
attribute that has a default value of `nil`. Why are we doing this? First of
all, songs need an `id` attribute only because they will be saved into the
database and we know that each table row needs an `id` value which is the
primary key.

When we create a new song with the `Song.new` method, we _do not set that song's
id_. A song gets an `id` only when it gets saved into the database (more on
inserting songs into the database later). We therefore set the default value of
the `id` argument for the `#initialize` equal to `nil`, so that we can create new
song instances that do not have an `id` value. We'll leave that up to the
database to handle later on.

Why leave it up to the database? Remember that in the world of relational
database, the `id` of a given record must be unique. If we could replicate a
record's `id`, we would have a very disorganized database. Only the database
itself, through the magic of SQL, can ensure that the `id` of each record is
unique.

#### The `.create_table` Method

Above, we created a class method, `.create_table`, that crafts a SQL statement
to create a songs table and give that table column names that match the
attributes of an individual instance of `Song`. Why is the `.create_table`
method a class method? Well, it is _not_ the responsibility of an individual
song to create the table it will eventually be saved into. It is the job of the
class as a whole to create the table that it is mapped to.

> **Top-Tip:** For strings that will take up multiple lines in your text editor,
> use a [heredoc](https://en.wikipedia.org/wiki/Here_document) to create a
> string that runs on to multiple lines. `<<-` +
> `special word meaning "End of Document"` + `the string, on multiple lines` +
> `special word meaning "End of Document"`. You don't have to use a heredoc,
> it's just a helpful tool for crafting long strings in Ruby. Back to our
> regularly scheduled programming...

Now that our songs table exists, we can learn how to save data regarding
individual songs into that table.

You can try out this code now to create the table in the `db/music.db` file.
Check out the code in the `bin/run` file:

```rb
#!/usr/bin/env ruby

require 'pry'
require_relative '../config/environment'

binding.pry
"pls"
```

In this file, we're requiring in the `environment.rb` file (which loads the code
for our database connection, as well as the `Song` class), and has a
`binding.pry` to set a breakpoint where you can enter a Pry session.

Run `ruby bin/run` to enter Pry, then run the `Song.create_table` method:

```rb
Song.create_table
# => []
```

Creating a table doesn't return any data, so SQLite returns an empty array from
the last line of our method (`DB[:conn].execute(sql)`). If you'd like to confirm
that the table was created successfully, you can run a special `PRAGMA` command
to show the information about the `songs` table:

```rb
DB[:conn].execute("PRAGMA table_info(songs)")
# => [[0, "id", "INTEGER", 0, nil, 1], [1, "name", "TEXT", 0, nil, 0], [2, "album", "TEXT", 0, nil, 0]]
```

The output isn't easy to read, but you'll see the different column names (`id`,
`name`, `album`) along with their data types (`INTEGER`, `TEXT`, `TEXT`).
Success!

## Mapping Class Instances to Table Rows

When we say that we are saving data to our database, what data are we referring
to? If individual instances of a class are "mapped" to rows in a table, does
that mean that the instances themselves, these individual Ruby objects, are
saved into the database?

Actually, **we are not saving Ruby objects in our database.** We are going to
take the individual attributes of a given instance, in this case a song's name
and album, and save _those attributes that describe an individual song_ to the
database as one, single row.

For example, let's say we have a song:

```ruby
gold_digger = Song.new(name: "Gold Digger", album: "Late Registration")

gold_digger.name
# => "Gold Digger"

gold_digger.album
# => "Late Registration"
```

This song has its two attributes, `name` and `album`, set equal to the above
values. In order to save the song `gold_digger` into the songs table, we will
use the name and album of the song to create a new row in that table. The SQL
statement we want to execute would look something like this:

```sql
INSERT INTO songs (name, album)
VALUES ("Gold Digger", "Late Registration");
```

What if we had another song that we wanted to save?

```ruby
hello = Song.new(name: "Hello", album: "25")

hello.name
# => "Hello"

hello.album
# => "25"
```

In order to save `hello` into our database, we do not insert the Ruby object
stored in the `hello` variable. Instead, we use `hello`'s name and album values
to create a new row in the songs table:

```sql
INSERT INTO songs (name, album)
VALUES ("Hello", "25");
```

We can see that the operation of saving the attributes of a particular song into
a database table is common enough. Every time we want to save a record, though,
we are repeating the same exact steps and using the same code. The only things
that are different are the values that we are inserting into our songs table.
Let's abstract this functionality into an instance method, `#save`.

### Inserting Data into a table with the `#save` Method

Let's build an instance method, `#save`, that saves a given instance of our
`Song` class into the songs table of our database.

```ruby
class Song

  # ... rest of song methods

  def save
    sql = <<-SQL
      INSERT INTO songs (name, album)
      VALUES (?, ?)
    SQL

    DB[:conn].execute(sql, self.name, self.album)

  end
end
```

Let's break down the code in this method.

#### The `#save` Method

In order to `INSERT` data into our songs table, we need to craft a SQL `INSERT`
statement. Ideally, it would look something like this:

```sql
INSERT INTO songs (name, album)
VALUES songs_name, songs_album
```

Above, we used the heredoc to craft our multi-line SQL statement. How are we
going to pass in, or interpolate, the name and album of a given song into our
heredoc?

We use something called **bound parameters**.

#### Bound Parameters

Bound parameters protect our program from getting confused by
[SQL injections](https://en.wikipedia.org/wiki/SQL_injection) and special
characters. Instead of interpolating variables into a string of SQL, we are
using the `?` characters as placeholders. Then, the special magic provided to us
by the SQLite3-Ruby gem's `#execute` method will take the values we pass in as
an argument and apply them as the values of the question marks.

#### How it works

So, our `#save` method inserts a record into our database that has the name and
album values of the song instance we are trying to save. We are not saving the
Ruby object itself. We are creating a new row in our songs table that has the
values that characterize that song instance.

**Important:** Notice that we _didn't_ insert an ID number into the table with
the above statement. Remember that the `INTEGER PRIMARY KEY` datatype will
assign and auto-increment the id attribute of each record that gets saved.

## Creating Instances vs. Creating Table Rows

The moment in which we create a new `Song` instance with the `#initialize`
method is _different than the moment in which we save a representation of that
song to our database_. The `#initialize` method creates a new instance of the
song class, a new Ruby object. The `#save` method takes the attributes that
characterize a given song and saves them in a new row of the songs table in our
database.

At what point in time should we actually save a new record? While it is possible
to save the record right at the moment the new object is created, i.e. in the
`#initialize` method, this is not a great idea. We don't want to force our
objects to be saved every time they are created, or make the creation of an
object dependent upon/always coupled with saving a record to the database. As
our program grows and changes, we may find the need to create objects and not
save them. A dependency between instantiating an object and saving that record
to the database would preclude this or, at the very least, make it harder to
implement.

So, we'll keep our `#initialize` and `#save` methods separate:

```ruby
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

    DB[:conn].execute(sql, self.name, self.album)

  end

end
```

Now, we can create and save songs like this. Try this out by running
`ruby bin/run` and running this code in the Pry session (make sure to exit out
of Pry in order to reload the code if you left it open earlier):

```ruby
hello = Song.new(name: "Hello", album: "25")
# => #<Song:0x00007fed21935128 @album="25", @id=nil, @name="Hello">
hello.save
# => []
ninety_nine_problems = Song.new(name: "99 Problems", album: "The Black Album")
# => #<Song:0x00007fed218c6200 @album="The Black Album", @id=nil, @name="99 Problems">
ninety_nine_problems.save
# => []
```

That last line of the `#save` method return an empty array once more since
`INSERT`ing new rows in a database doesn't return any data, but you can check if
all the records were indeed saved by running this in your Pry session:

```rb
pry(main)> DB[:conn].execute("SELECT * FROM songs;")
# => [[1, "Hello", "25"], [2, "99 Problems", "The Black Album"]]
```

### Giving Our `Song` Instance an `id`

When we `INSERT` the data concerning a particular `Song` instance into our
database table, we create a new row in that table. That row would look something
like this:

| id | name | album |
| --- | --- | --- |
| 1 | Hello | 25 |

Notice that the database table's row has a column for `name`, `album` and also
`id`. Recall that we created our table to have a column for the primary key, ID,
of a given record. So, as each record gets inserted into the database, it is
given an ID number automatically.

In this way, our `hello` instance is stored in the database with the name and
album that we gave it, _plus_ an ID number that the database assigns to it.

We want our `hello` instance to completely reflect the database row it is
associated with so that we can retrieve it from the table later on with ease.
So, once the new row with `hello`'s data is inserted into the table, let's grab
the `ID` of that newly inserted row and assign it to be the value of `hello`'s
`id` attribute.

```ruby
class Song

  attr_accessor :name, :album, :id

  def initialize(name:, album:, id: nil)
    @id = id
    @name = name
    @album = album
  end

  # ... rest of song methods

  def save
    sql = <<-SQL
      INSERT INTO songs (name, album)
      VALUES (?, ?)
    SQL

    # insert the song
    DB[:conn].execute(sql, self.name, self.album)

    # get the song ID from the database and save it to the Ruby instance
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM songs")[0][0]

    # return the Ruby instance
    self
  end
end
```

At the end of our `#save` method, we use a SQL query to grab the value of the
`id` column of the last inserted row, and set that equal to the given song
instance's `id` attribute. Don't worry too much about how that SQL query works
for now, we'll learn more about it later. The important thing to understand is
the process of:

- Instantiating a new instance of the `Song` class.
- Inserting a new row into the database table that contains the information
  regarding that instance.
- Grabbing the `id` of that newly inserted row and assigning the given `Song`
  instance's `id` attribute equal to the `id` of its associated database table
  row.

Let's revisit our code that instantiated and saved some songs by running
`ruby bin/run` again and entering this in Pry:

```ruby
hello = Song.new(name: "Hello", album: "25")
# => #<Song:0x00007fed21935128 @album="25", @id=nil, @name="Hello">
hello.save
# => #<Song:0x00007fb61d202a58 @album="25", @id=3, @name="Hello">
ninety_nine_problems = Song.new(name: "99 Problems", album: "The Black Album")
# => #<Song:0x00007fed218c6200 @album="The Black Album", @id=nil, @name="99 Problems">
ninety_nine_problems.save
# => #<Song:0x00007fb61d14c820 @album="The Black Album", @id=4, @name="99 Problems">
```

Here we:

- Create the songs table.
- Create two new song instances.
- Use the `Song#save` method to persist them to the database.

This approach still leaves a little to be desired, however. Here, we have to
first create the new song and then save it, every time we want to create and
save a song. This is repetitive and tedious. As programmers (you might
remember), we are lazy. If we can accomplish something with fewer lines of code
we do it. **Any time we see the same code being used again and again, we think
about abstracting that code into a method.**

Since first creating an object and then saving a record representing that object
is so common, let's write a method that does just that.

### The `.create` Method

This method will wrap the code we used above to create a new `Song` instance and save it.

```ruby
class Song
  # ... rest of song methods

  def self.create(name:, album:)
    song = Song.new(name: name, album: album)
    song.save
  end
end
```

Here, we use keyword arguments to pass a name and album into our `.create`
method. We use that name and album to instantiate a new song. Then, we use the
`#save` method to persist that song to the database.

Notice that at the end of the method, we are returning the `song` instance that
we instantiated. The return value of `.create` should always be the object that
we created. Why? Imagine you are working with your program and you create a new
song:

```ruby
Song.create(name: "Hello", album: "25")
```

Now, we would have to run a separate query on our database to grab the record
that we just created. That is way too much work for us. It would be much easier
for our `.create` method to simply return the new object for us to work with:

```ruby
song = Song.create(name: "Hello", album: "25")
# => #<Song:0x007f94f2c28ee8 @id=1, @name="Hello", @album="25">

song.name
# => "Hello"

song.album
# => "25"
```

Excellent! Run `learn test` now to pass the tests and submit the assignment.

## Conclusion

The important concept to grasp here is the idea that we are _not_ saving Ruby
objects into our database. We are using the attributes of a given Ruby object to
create a new row in our database table.

Think of it like making butter cookies. You have a cookie cutter, which in our
case would be our class. It describes what a cookie should look like. Then you
use it to cut out a cookie, or instantiate a class object. But that's not
enough, you have to show it to your friends. So you take a picture of it and
post to your MyFace account and share it with everybody else, like how your
database can share information with other parts of your program.

The picture doesn't do anything to the cookie itself, but merely captures
certain aspects of it. It's a butter cookie, it looks fresh and delicious, and
it has little sprinkles on it. Those aspects are captured in the picture, but
the cookie and the picture are still two different things. After you eat the
cookie, or in our case after you delete the Ruby object, the database will not
change at all until the record is deleted, and vice versa.
