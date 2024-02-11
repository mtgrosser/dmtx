require_relative 'dmtx/version'
require_relative 'dmtx/data_matrix'

module Dmtx
  class Error < StandardError; end
  class EncodingError < Error; end
end
