ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def with_env(overrides)
      previous_values = overrides.keys.index_with { |key| ENV[key] }

      overrides.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end

      yield
    ensure
      previous_values.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end
    end
  end

  class ActionDispatch::IntegrationTest
    def sign_in_as(user, password: "password123")
      post session_path, params: { session: { email: user.email, password: password } }
    end

    def turbo_stream_headers
      { "ACCEPT" => Mime[:turbo_stream].to_s }
    end
  end
end
