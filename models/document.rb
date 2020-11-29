# frozen_string_literal: true

require 'ostruct'
# Clase que representa la entidad Document
class Document < Sequel::Model
  plugin :validation_helpers
  # attr_accessor :users, :documents, :is_admin
  def validate
    super
    #validates_presence %i[name date uploader subject]
    validates_presence :name, message: "Se requiere un nombre"
    validates_presence :date, message: "Se requiere una fecha"
    validates_presence :uploader, message: "Se requiere un que nombre del cargador"
    validates_presence :subject, message: "Se requiere ingresar asunto"
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
      if !doc.valid?
        raise ArgumentError.new("Por favor debe completar todos los campos")
      else
        doc if doc.save
      end
  end
  one_to_many :users
  set_primary_key :id
end
