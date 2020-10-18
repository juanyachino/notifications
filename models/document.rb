# frozen_string_literal: true
require 'ostruct'
class Document < Sequel::Model
	plugin :validation_helpers
  #attr_accessor :users, :documents, :is_admin
  def validate
    super
    validates_presence [:name, :date, :uploader, :subject]
  end
  def index
     @documents = Document.all
  end
  def self.get_all
      Document.all 
  end
  one_to_many :users
  set_primary_key :id
end
