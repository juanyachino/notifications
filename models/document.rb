# frozen_string_literal: true

require 'ostruct'
# Clase que representa la entidad Document
class Document < Sequel::Model
  plugin :validation_helpers
  # attr_accessor :users, :documents, :is_admin
  def validate
    super
    validates_presence %i[name date uploader subject]
  end

  def index
    @documents = Document.all
  end

  def self.bring_all
    Document.all
  end

  def self.create(hash)
    doc = Document.new(name: hash[:filename],
                       date: hash[:date],
                       uploader: hash[:uploader],
                       subject: hash[:subject])
    doc if doc.save
  end
  one_to_many :users
  set_primary_key :id
end
