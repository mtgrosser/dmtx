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
    data = "#{Dmtx::GS1DataMatrix::FNC1}01095011010209171719050810ABCD1234#{Dmtx::GS1DataMatrix::FNC1}2110"
    encodings = Dmtx::GS1DataMatrix.new(data).encodings(data)
    assert_equal %i[asci], encodings.keys
    assert_equal 232, encodings[:asci].first
  end
end
