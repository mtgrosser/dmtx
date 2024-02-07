module Dmtx
  # See https://www.gs1.org/standards/gs1-datamatrix-guideline/25
  class GS1DataMatrix < DataMatrix
    FNC1 = "\u001D".freeze # ASCII 29, INFORMATION SEPARATOR THREE, group separator
    FNC1_CODEWORD = 232

    def encodings(msg)
      { asci: ascii_encode(msg) }
    end

    def ascii_encode(t)
      bytes, result = t.bytes, []
      while c = bytes.shift
        if !bytes.empty? && c > 47 && c < 58 && bytes.first > 47 && bytes.first < 58
          result << (c - 48) * 10 + bytes.shift + 82
        elsif c > 127
          result << 235
          result << ((c - 127) & 255)
        elsif c == FNC1.bytes.first
          result << FNC1_CODEWORD
        else
          result << c + 1
        end
      end
      result
    end
  end
end
