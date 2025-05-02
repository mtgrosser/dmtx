require_relative 'test_helper'

class DmtxTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Dmtx::VERSION
  end

  def test_generate_data_matrix
    dmtx = Dmtx::DataMatrix.new('TEST')
    assert_equal %w[101010101010
                    101100010011
                    100010101010
                    111000001101
                    100100111110
                    111111110111
                    111011101110
                    100100110101
                    111001010000
                    101011110101
                    101001011010
                    111111111111].join, dmtx.to_i.to_s(2)
  end

  def test_generate_data_matrix_png
    dmtx = Dmtx::DataMatrix.new('Chunky Bacon')
    assert dmtx.to_png.to_s.start_with?("\x89PNG".force_encoding('BINARY'))
  end

  def test_generate_data_matrix_svg
    dmtx = Dmtx::DataMatrix.new('Chunky Bacon')
    assert dmtx.to_svg.to_s.start_with?('<svg xmlns')
  end

  def test_gs1_data_matrix_encodings
    # See example 2 at https://www.gs1.org/standards/gs1-datamatrix-guideline/25#2-Encoding-data+2-3-Human-readable-interpretation-(HRI)
    data = "#{Dmtx::DataMatrix::FNC1.chr}01095011010209171719050810ABCD1234#{Dmtx::DataMatrix::FNC1.chr}2110"
    dmtx = Dmtx::DataMatrix.new(data, encoding: :gs1)
    assert_equal :gs1, dmtx.encoding
    assert_equal 232, dmtx.encoded_message.first
  end

  def test_size_override_with_small_data
    # Test that small data can be encoded in a larger matrix
    small_data = "\x1d42012345\x1d12345678901234567890"
    default_dmtx = Dmtx::DataMatrix.new(small_data, encoding: :gs1)
    large_dmtx = Dmtx::DataMatrix.new(small_data, encoding: :gs1, data_size_override: 22)

    # Verify the sizes are different
    refute_equal [default_dmtx.width, default_dmtx.height], [large_dmtx.width, large_dmtx.height]

    assert_equal [18, 18], [default_dmtx.width, default_dmtx.height]
    # Verify the forced size
    assert_equal [20, 20], [large_dmtx.width, large_dmtx.height]
  end
end
