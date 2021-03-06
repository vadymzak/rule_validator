Dir[File.dirname(File.absolute_path(__FILE__)) + '/../lib/**/*.rb'].each {|file| require file }
require 'jwt'
require 'test/unit'
require 'rack/test'

class MainTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    RuleValidator::Validator.new(
      JwtValidator::Validator.new(
        WhiteListValidator::Validator.new(
          MyApp.new)))
  end

  def setup
    @payload = { "user": 1 }
    @algo    = 'HS256'
    @secret  = 'secret'

    @valid_token   = JWT.encode @payload, @secret, @algo
    @invalid_token = JWT.encode @payload, 'something else', @algo
  end

  def test_status_200_with_domen_from_white_list_valid_token
    header 'Authorization', "Bearer #{@valid_token}"
    get 'http://dots.com/signin'

    assert_equal(last_response.status, 200)
  end

  def test_status_200_with_domen_from_white_list_invalid_token
    header 'Authorization', "Bearer #{@invalid_token}"
    get 'http://dots.com/signin'

    assert_equal(last_response.status, 200)
  end

  def test_status_401_with_domen_not_from_white_list_invalid_token_v2
    header 'Authorization', "Bearer #{@valid_token}"

    assert_raises(RuleValidator::Exceptions::RouteMissing) {get 'http://dots.com/tests'}
  end

  def test_status_401_with_domen_not_from_white_list_invalid_token
    header 'Authorization', "Bearer #{@invalid_token}"
    get 'http://dots.com/tests'

    assert_equal(last_response.status, 401)
  end

  def test_status_200_with_domen_from_tree_routes_valid_token
    header 'Authorization', "Bearer #{@valid_token}"
    get 'http://dots.com/account/workspaces/12/members/admin'

    assert_equal(last_response.status, 200)
  end
end
