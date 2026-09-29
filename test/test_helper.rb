# frozen_string_literal: true

# Not Rails.root.join(...): under Rails 7.2 the test files are loaded before
# the Rails environment is up (rails test runs as a separate process).
require File.expand_path('../../../test/test_helper', __dir__)
