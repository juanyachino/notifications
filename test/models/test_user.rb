require File.expand_path '../../test_helper.rb', __FILE__
require 'minitest/autorun'

class UserTest < Minitest::Unit::TestCase
	MiniTest::Unit::TestCase

	def test_name_existence
		# Arrange
		@user = User.new
		# Act
		@user.name = nil
		# Assert
		assert_equal @user.valid?, false
	end

	def test_create_user
  	user = User.new(name: 'testUser',
  					email: 'test@test.com', 
  					username: 'test',
  					password: '123456')
  	assert_equal user.valid?, true
	end

	def test_create_user_presence_name
 		u = User.new(email: 'test@test.com', 
 					 username: 'test',
 					 password: '123456')
  	assert_equal u.valid?, false
	end

	def test_create_user_presence_email
 		u = User.new(name: 'testUser',
 					 username: 'test',
 					 password: '123456')
  	assert_equal u.valid?, false
	end

	def test_validate_email
  	@user = User.new(name: 'testUser',
  					 email: 'testtest.com',
  					 username: 'test',
  					 password: '123456')
  	assert_equal @user.valid?, false
	end

	def test_validate_other_email
  	@user = User.new(name: 'testUser',
  					 email: 'test@testcom',
  					 username: 'test',
  					 password: '123456')
  	assert_equal @user.valid?, false
	end
end
