# frozen_string_literal: true

# clase modelo que representa la relacion entre documents y users
class DocumentsUser < Sequel::Model(:documents_users)
  many_to_one :document
  many_to_one :user
end
