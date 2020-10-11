require File.expand_path '../../test_helper.rb', __FILE__
require 'minitest/autorun'

class DocumentTest < Minitest::Unit::TestCase
	MiniTest::Unit::TestCase

	def test_document_existence
		# Arrange
		@document = Document.new
		# Act
		@document.name = nil
		# Assert
		assert_equal @document.valid?, false
	end

	def test_create_invalid_document
  		@document = Document.new(name:' , date:',
  								 uploader:' , subject:')
  		assert_equal @document.valid?, false
	end

	def test_create_document
		@document = Document.new(name:'test.pdf',
								 date:'14-09-2020',
								 uploader:'userTest',
								 subject:'Coment test' )
		assert_equal @document.valid?, true
	end 

	def test_create_invalid_field_document 
		@document = Document.new(date:'14-09-2020',
								 uploader:'userTest',
								 subject:'Coment test' )
		assert_equal @document.valid?, false
	end

	def test_format_file_document
		@docment = Document.new(name:'test.pgn',
								date:'14-09-2020',
								uploader:'userTest',
								subject:'Coment test' )
		assert_equal @document.valid?, false
	end	
end