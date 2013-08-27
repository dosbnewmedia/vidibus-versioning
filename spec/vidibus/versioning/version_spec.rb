require 'spec_helper'

describe Vidibus::Versioning::Version do
  let(:book) do
    Book.create(:title => 'Moby Dick')
  end
  let(:another_book) do
    Book.create(:title => '1984')
  end

  let(:subject) do
    Vidibus::Versioning::Version.new
  end

  describe '#number' do
    it 'should be nil by default' do
      subject.number.should be_nil
    end

    context 'with a versioned object' do
      before do
        subject.versioned = book
        subject.versioned_attributes = book.attributes
        subject.save!
      end

      it 'should be 1' do
        subject.number.should eq(1)
      end

      it 'should be 2 for next version of same object' do
        next_version = Vidibus::Versioning::Version.create({
          :versioned => book,
          :versioned_attributes => book.attributes
        })
        next_version.number.should eq(2)
      end

      it 'should be 1 for next version of different object' do
        next_version = Vidibus::Versioning::Version.create({
          :versioned => another_book,
          :versioned_attributes => another_book.attributes
        })
        next_version.number.should eq(1)
      end
    end
  end

  describe '#past?' do
    before do
      subject.versioned = book
      subject.versioned_attributes = book.attributes
      subject.save
    end

    it 'should be true if creation date is in the past' do
      subject.created_at = Time.now - 20000
      subject.past?.should be_true
    end

    it 'should be false if creation date is in the future' do
      subject.created_at = Time.now + 20000
      subject.past?.should be_false
    end

    it 'should be false if creation date has not been set' do
      subject.created_at = nil
      subject.past?.should be_false
    end
  end

  describe '#future?' do
    before do
      subject.versioned = book
      subject.versioned_attributes = book.attributes
      subject.save
    end

    it 'should be true if creation date is in the future' do
      subject.created_at = Time.now + 20000
      subject.future?.should be_true
    end

    it 'should be false if creation date is in the past' do
      subject.created_at = Time.now - 20000
      subject.future?.should be_false
    end

    it 'should be false if creation date has not been set' do
      subject.created_at = nil
      subject.future?.should be_false
    end
  end
end
