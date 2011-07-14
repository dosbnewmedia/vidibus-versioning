require "spec_helper"

describe Vidibus::Versioning::Mongoid do
  let(:book_attributes) {{:title => "title 1", :text => "text 1"}}
  let(:new_book) {Book.new(book_attributes)}
  let(:book) {Book.create(book_attributes)}
  let(:book_with_two_versions) {book.update_attributes(:title => "title 2", :text => "text 2"); book}
  let(:book_with_three_versions) {book_with_two_versions.update_attributes(:title => "title 3", :text => "text 3"); book}
  let(:book_with_four_versions) {book_with_three_versions.update_attributes(:title => "title 4", :text => "text 4"); book}

  def reset_book
    Book.versioned_attributes = []
    Book.versioning_options = {}
  end

  describe "#version" do
    it "should not change self" do
      book = book_with_two_versions
      book.freeze
      expect {book.version(1)}.not_to raise_error(TypeError)
    end

    it "should set versioned attributes that are nil" do
      book = Book.create!(:title => "Moby Dick")
      book.update_attributes!(:text => "Call me Ishmael.")
      book.reload.versions.first.versioned_attributes.to_a.should eql({"title" => "Moby Dick"}.to_a)
      previous = book.version(:previous)
      previous.title.should eql("Moby Dick")
      previous.text.should be_nil
    end

    it "should not set attributes that are not versioned" do
      stub_time("2011-07-14 16:00")
      article = Article.create!(:title => "Moby Dick", :published => false)
      stub_time("2011-07-14 17:00")
      article.update_attributes!(:text => "Call me Ishmael.", :published => true)
      article.version(:previous).published.should be_true
    end

    context "without arguments" do
      it "should raise an argument error" do
        expect {book.version}.to raise_error(ArgumentError)
      end
    end

    context "with argument 1" do
      context "if only one version is available" do
        it "should return a copy of the record itself " do
          version = book.version(1)
          version.should eql(book)
          version.object_id.should_not eql(book.object_id)
        end
      end

      context "if several versions are available" do
        it "should return version 1 of the record" do
          version = book_with_two_versions.version(1)
          version.title.should eql("title 1")
          version.version_number.should eql(1)
        end
      end
    end

    context "with argument 2" do
      context "if only one version is available" do
        it "should return a new version of the record" do
          book.version(2).should be_a_new_version
        end

        it "should apply the object's current attributes, but with version number 2 and the version update time" do
          now = stub_time("2011-07-14 14:00")
          expected_attributes = book.attributes.merge("version_number" => 2, "version_updated_at" => now)
          book.version(2).attributes.sort.should eql(expected_attributes.sort)
        end
      end

      context "if several versions are available" do
        it "should return version 2 of the record" do
          version = book_with_two_versions.version(2)
          version.title.should eql("title 2")
          version.version_number.should eql(2)
          version.should_not be_a_new_version
        end
      end
    end

    context "with argument :new" do
      context "if only one version is available" do
        it "should return a new version of the record" do
          book.version(:new).should be_a_new_version
        end

        it "should apply the object's current attributes" do
          book.version(:new).title.should eql("title 1")
        end

        it "should set version number 2" do
          book.version(:new).version_number.should eql(2)
        end
      end

      context "if two versions are available and the current version is 1" do
        before {book_with_two_versions.migrate!(1)}

        it "should return a new version of the record" do
          book_with_two_versions.version(:new).should be_a_new_version
        end

        it "should apply the object's current attributes" do
          book_with_two_versions.version(:new).title.should eql("title 1")
        end

        it "should set version number 3" do
          book_with_two_versions.version(:new).version_number.should eql(3)
        end
      end
    end

    context "with argument :next" do
      context "if only one version is available" do
        it "should return a new version of the record" do
          book.version(:next).should be_a_new_version
        end

        it "should apply the object's current attributes" do
          book.version(:next).title.should eql("title 1")
        end

        it "should set version number 2" do
          book.version(:next).version_number.should eql(2)
        end
      end

      context "if several versions are available and the current version is 1" do
        it "should return version 2 of the record" do
          book_with_two_versions.migrate!(1)
          version = book_with_two_versions.version(:next)
          version.should_not be_a_new_version
          version.title.should eql("title 2")
          version.version_number.should eql(2)
        end
      end
    end

    context "with argument :previous" do
      it "should return version 1, if current version is 2" do
        book_with_two_versions.version(:previous).version_number.should eql(1)
      end

      it "should return a copy of self, if current version is 1" do
        book_with_two_versions.migrate!(1)
        book.version(:previous).version_number.should eql(1)
      end
    end

    context "with arguments 2, :title => 'new 2'" do
      context "if version 2 does not exist yet" do
        it "should initialize a new version with given attributes" do
          version = book.version(2, :title => "new")
          version.version_number.should eql(2)
          version.title.should eql("new")
          version.text.should eql("text 1")
          version.should be_a_new_version
        end
      end

      context "if version 2 does exist" do
        it "should set given attributes on version 2" do
          book_with_two_versions.migrate!(1)
          version = book_with_two_versions.version(2, :title => "new")
          version.version_number.should eql(2)
          version.title.should eql("new")
          version.title_changed?.should be_true
        end
      end
    end
  end

  describe "#version!" do
    context "without arguments" do
      it "not change self" do
        book.freeze
        expect {book.version!}.not_to raise_error(TypeError)
      end
    end

    context "with arguments" do
      it "should change the current object to a new version with given attributes" do
        book.version!(:next, :title => "new")
        book.version_number.should eql(2)
        book.title.should eql("new")
        book.text.should eql("text 1")
        book.should be_a_new_version
      end
    end
  end

  describe "#migrate!" do
    it "should call #save!" do
      book_with_two_versions
      mock(book_with_two_versions).save!
      book_with_two_versions.migrate!(1)
    end

    it "should overwrite local changes" do
      book_with_two_versions.title = "something new"
      book_with_two_versions.migrate!(1)
      book_with_two_versions.reload
      book_with_two_versions.title.should eql("title 1")
      book_with_two_versions.versions[1].versioned_attributes["title"].should eql("title 2")
    end

    context "without arguments" do
      it "should persist attributes given on loaded version on versioned object" do
        version = book_with_two_versions.version(1)
        version.migrate!
        version.reload
        version.version_number.should eql(1)
        version.title.should eql("title 1")
      end

      it "should store the current object's attributes as new version" do
        versioned_attributes = book_with_two_versions.versioned_attributes.dup
        book_with_two_versions.version(1).migrate!
        book_with_two_versions.version(2).versioned_attributes.should eql(versioned_attributes)
      end

      it "should return nil on success" do
        book_with_two_versions.version(1).migrate!.should be_nil
      end

      it "should raise a MigrationError unless a version has been loaded or given" do
        expect {book.migrate!}.to raise_error(Vidibus::Versioning::MigrationError)
      end

      it "should raise a MigrationError if the version number is the current one" do
        expect {book_with_two_versions.version(2).migrate!}.to raise_error(Vidibus::Versioning::MigrationError)
      end
    end

    context "with version number" do
      it "should apply the version given" do
        book_with_two_versions.migrate!(1)
        book_with_two_versions.reload
        book_with_two_versions.version_number.should eql(1)
        book_with_two_versions.versioned_attributes.should eql(book_with_two_versions.versions.first.versioned_attributes)
      end

      it "should raise a MigrationError if the version number is the current one" do
        expect {book.migrate!(1)}.to raise_error(Vidibus::Versioning::MigrationError)
      end
    end

    context "on the current version of a record" do
      it "should store the attributes as new version" do
        book_with_two_versions.migrate!(1)
        book_with_two_versions.reload
        book_with_two_versions.versions.should have(2).versions
        book_with_two_versions.versions[1].versioned_attributes["title"].should eql("title 2")
        book_with_two_versions.versions[1].number.should eql(2)
      end
    end

    context "on a rolled back record" do
      before do
        stub_time("2011-07-01 01:00 UTC")
        book
        stub_time("2011-07-01 02:00 UTC")
        book.update_attributes(:title => "title 2", :text => "text 2")
        stub_time("2011-07-01 04:00 UTC")
        book_with_two_versions.undo!
        stub_time("2011-07-01 04:00 UTC")
        book_with_two_versions.reload
      end

      it "should not create a new version object" do
        book_with_two_versions.versions.should have(2).versions
        book_with_two_versions.migrate!(:next)
        book_with_two_versions.reload.versions.should have(2).versions
      end

      it "should ensure that each version's creation time reflects the time of update" do
        book_with_two_versions.migrate!(:next)
        book_with_two_versions.versions[0].created_at.should eql(Time.parse("2011-07-01 01:00 UTC").localtime)
        book_with_two_versions.versions[1].created_at.should eql(Time.parse("2011-07-01 02:00 UTC").localtime)
      end
    end

    context "on a record containing a future version" do
      before do
        stub_time("2011-07-01 01:00 UTC")
        book
        stub_time("2011-07-01 02:00 UTC")
        version = book.version(:next)
        version.update_attributes!(:title => "THE FUTURE!", :updated_at => Time.parse("2012-01-01 00:00 UTC"))
        stub_time("2011-07-01 03:00 UTC")
        book.reload
      end

      it "should create a new version object of the old version" do
        book.versions.should have(1).version
        book.migrate!(:next)
        book.versions.should have(2).versions
        book.versions.last.number.should eql(1)
        book.versions.last.versioned_attributes["title"].should eql("title 1")
      end

      it "should ensure that each version's creation time reflects the time of update" do
        book.migrate!(:next)
        book.reload
        book.versions[0].created_at.should eql(Time.parse("2012-01-01 00:00 UTC").localtime)
        book.versions[1].created_at.should eql(Time.parse("2011-07-01 01:00 UTC").localtime)
      end
    end
  end

  describe "#undo!" do
    it "should call #version!(:previous) and #migrate!" do
      mock(book).version!(:previous)
      mock(book).migrate!
      book.undo!
    end
  end

  describe "#redo!" do
    it "should call #version!(:next) and #migrate!" do
      mock(book).version!(:next)
      mock(book).migrate!
      book.redo!
    end
  end

  describe "#version_object" do
    it "should be nil by default" do
      book.version_object.should be_nil
    end

    it "should return the currently loaded version object" do
      book_with_two_versions.version(1).version_object.should eql(book_with_two_versions.versions.first)
    end

    it "should be nil for the current version" do
      book_with_two_versions.version(2).version_object.should be_nil
    end

    it "should return a new version object for a new version" do
      book_with_two_versions.version(:new).version_object.should be_a_new_record
    end
  end

  describe "#reload_version" do
    it "should reload the object" do
      version = book_with_two_versions.version(1)
      version.title = "invalid"
      version.reload_version
      version.title.should_not eql("invalid")
    end

    it "should apply the version attributes" do
      version = book_with_two_versions.version(1)
      mock(version).version(1)
      version.reload_version
    end

    it "should just reload the record if no version was loaded before" do
      mock(book_with_two_versions).reload {book_with_two_versions}
      book_with_two_versions.reload_version
    end
  end

  describe "#new_version?" do
    it "should return true if version is a new one" do
      book.version(2).new_version?.should be_true
    end

    it "should return if version is the current one" do
      book.version(1).new_version?.should be_false
    end

    it "should return false if version already exists" do
      book_with_two_versions.version(1).new_version?.should be_false
    end
  end

  describe "#updated_at" do
    let(:book_with_two_versions) do
      stub_time("2011-07-01 00:01 UTC") {book}
      stub_time("2011-07-01 00:02 UTC") {book.update_attributes(:title => "title 2", :text => "text 2")}
      book
    end

    before do
      book_with_two_versions
      stub_time("2011-07-01 00:03 UTC")
    end

    it "should contain the time the record was edited" do
      book_with_two_versions.updated_at.should eql(Time.parse("2011-07-01 00:02 UTC"))
    end

    context "with a loaded version" do
      it "should return the time the version was created at" do
        book_with_two_versions.version(1).updated_at.should eql(Time.parse("2011-07-01 00:01 UTC"))
      end
    end
  end

  describe "#save" do
    context "without a version loaded" do
      it "should work as expected for versioned object" do
        book.title = "new title"
        book.save
        book.reload.title.should eql("new title")
      end
    end

    context "with a version loaded" do
      let(:version) {book_with_two_versions.version(1)}

      it "should return false if record is invalid" do
        version.title = nil
        version.save.should be_false
      end

      it "should not update the version object if the record is invalid" do
        version.title = nil
        version.save
        version.reload.versions.first.versioned_attributes["title"].should_not be_nil
      end

      it "should return true if saving succeeds" do
        version.save.should be_true
      end

      it "should not update the versioned object" do
        version.title = "new title"
        version.save
        version.reload.title.should_not eql("new title")
      end

      it "should update the version object" do
        version.title = "new title"
        version.save
        version.reload.versions.first.versioned_attributes["title"].should eql("new title")
      end
    end
  end

  describe "#save!" do
    it "should call #save" do
      mock(book).save {true}
      book.save!
    end

    it "should return nil if saving succeeds" do
      stub(book).save {true}
      book.save!.should be_nil
    end

    it "should raise a validation error if saving fails" do
      stub(book).save {false}
      expect {book.save!}.to raise_error(::Mongoid::Errors::Validations)
    end
  end

  describe "#delete" do
    context "without a version loaded" do
      it "should delete the record" do
        book.delete
        expect {book.reload}.to raise_error(::Mongoid::Errors::DocumentNotFound)
      end

      it "should remove all versions of the record" do
        book_with_two_versions.delete
        Vidibus::Versioning::Version.all.should have(:no).versions
      end
    end

    context "with a version loaded" do
      let(:version) {book_with_three_versions.version(1)}

      it "should delete the version" do
        version.delete
        version.reload.versions.should have(1).version
      end

      it "should keep the versioned object if deleting fails" do
        stub.any_instance_of(Vidibus::Versioning::Version).delete {false}
        version.delete
        version.reload
      end
    end
  end

  describe "#destroy" do
    context "without a version loaded" do
      it "should destroy the record" do
        book.destroy
        expect {book.reload}.to raise_error(::Mongoid::Errors::DocumentNotFound)
      end

      it "should remove all versions of the record" do
        book_with_two_versions.destroy
        Vidibus::Versioning::Version.all.should have(:no).versions
      end
    end

    context "with a version loaded" do
      let(:version) {book_with_three_versions.version(1)}

      it "should destroy the version" do
        version.destroy
        version.reload.versions.should have(1).version
      end

      it "should keep the versioned object if deleting fails" do
        stub.any_instance_of(Vidibus::Versioning::Version).destroy {false}
        version.destroy
        version.reload
      end
    end
  end

  describe "#versioned_attributes" do
    context "without versioned attributes defined" do
      it "should return all attributes except the unversioned ones" do
        book.versioned_attributes.should eql(book.attributes.except(Book.unversioned_attributes))
      end
    end

    context "with versioned attributes defined" do
      it "should return the versioned attributes only" do
        Book.versioned_attributes = ["title"]
        book = Book.new(book_attributes)
        book.versioned_attributes.should eql({"title" => "title 1"})
      end

      after {reset_book}
    end
  end

  describe "#version_updated_at" do
    let(:article) do
      stub_time("2011-07-14 13:00")
      record = Article.create(:title => "title 1", :text => "text 1")
      stub_time("2011-07-14 14:00")
      record
    end

    it "should return the time of the last update by default" do
      article.version_updated_at.should eql(article.updated_at)
    end

    it "should return the time on which versioned attributes were updated" do
      article.update_attributes(:title => "Something new")
      article.reload.version_updated_at.should eql(Time.parse("2011-07-14 14:00"))
    end

    it "should not change unless versioned attributes get changed" do
      article.update_attributes(:title => "Something new")
      stub_time("2011-07-14 15:00")
      article.update_attributes(:published => true)
      article.reload.version_updated_at.should eql(Time.parse("2011-07-14 14:00"))
    end
  end

  describe ".versioned_attributes" do
    it "should be an empty array by default" do
      Book.versioned_attributes.should eql([])
    end

    it "should reflect fields defined by .versioned" do
      Book.versioned(:title)
      Book.versioned_attributes.should eql(["title"])
    end

    after {reset_book}
  end

  describe ".versioning_options" do
    it "should be an empty hash by default" do
      Book.versioning_options.should eql({})
    end

    it "should reflect options defined by .versioned" do
      Book.versioned(:editing_time => 300)
      Book.versioning_options.should eql({:editing_time => 300})
    end

    after {reset_book}
  end

  describe ".unversioned_attributes" do
    it "should return _id, _type, uuid, updated_at, created_at, version_number, and version_updated_at" do
      Book.unversioned_attributes.should eql(%w[_id _type uuid updated_at created_at version_number version_updated_at])
    end
  end
end
