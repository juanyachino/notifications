class User < Sequel::Model
	plugin :validation_helpers
  def validate
    super
    validates_presence [:name, :email, :username, :password]
    validates_unique [:username]
  end
  one_to_many :documents
  many_to_many :init
  set_primary_key :id
end
