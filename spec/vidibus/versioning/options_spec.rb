require 'spec_helper'

describe 'Options' do
  describe 'Article.versioning_options' do
    it 'should be {:editing_time => 300}' do
      expect(Article.versioning_options).to eq({:editing_time => 300})
    end
  end

  describe 'Book.versioning_options' do
    it 'should be {}' do
      expect(Book.versioning_options).to eq({})
    end
  end
end