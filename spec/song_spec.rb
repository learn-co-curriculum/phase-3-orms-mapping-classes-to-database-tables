require "spec_helper"

describe Song do
  let(:hello) { Song.new(name: "Hello", album: "25") }
  let(:ninety_nine_problems) { Song.new(name: "99 Problems", album: "The Black Album") }

  before do
    DB[:conn].execute("DROP TABLE IF EXISTS songs;")
  end

  context "when initialized with a name and an album" do
    let(:gold_digger) { Song.new(name: "Gold Digger", album: "Late Registration") }

    it 'the name attribute can be accessed' do
      expect(gold_digger.name).to eq("Gold Digger")
    end

    it 'the album attribute can be accessed' do
      expect(gold_digger.album).to eq("Late Registration")
    end

    it 'sets the initial value of id to nil' do
      expect(gold_digger.id).to eq(nil)
    end
  end

  describe ".create_table" do
    it 'creates the songs table in the database' do
      Song.create_table
      table_check_sql = "SELECT tbl_name FROM sqlite_master WHERE type='table' AND tbl_name='songs';"
      expect(DB[:conn].execute(table_check_sql)[0]).to eq(['songs'])
    end
  end

  describe "#save" do
    before do
      Song.create_table
    end

    it 'saves an instance of the Song class to the database' do
      Song.create_table
      hello.save
      expect(DB[:conn].execute("SELECT * FROM songs")).to eq([[1, "Hello", "25"]])
    end

    it 'assigns the id of the song from the database to the instance' do
      Song.create_table
      hello.save
      expect(hello.id).to eq(1)
    end

    it 'returns the new object that it instantiated' do
      expect(hello.save).to eq(hello)
    end
  end

  describe ".create" do
    before do
      Song.create_table
    end

    it 'saves a song to the database' do
      Song.create(name: "Gold Digger", album: "Late Registration")
      expect(DB[:conn].execute("SELECT * FROM songs")).to eq([[1, "Gold Digger", "Late Registration"]])
    end

    it 'returns the new object that it instantiated' do
      gold_digger = Song.create(name: "Gold Digger", album: "Late Registration")
      expect(gold_digger).to be_a(Song)
    end
  end
end
