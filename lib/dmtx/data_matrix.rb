# Translated to Ruby from datamatrix-svg
# https://github.com/datalog/datamatrix-svg

require 'builder'
require 'chunky_png'

module Dmtx
  class DataMatrix
    attr_reader :width, :height, :encoded_message, :encoding
  
    C40 = [230,
           31, 0, 0,
           32, 9, 29,
           47, 1, 33,
           57, 9, 44,
           64, 1, 43,
           90, 9, 51,
           95, 1, 69,
           127, 2, 96,
           255, 1,  0]
  
    TEXT = [239,
            31, 0,  0,
            32, 9, 29,
            47, 1, 33,
            57, 9, 44,
            64, 1, 43,
            90, 2, 64,
            95, 1, 69,
            122, 9, 83,
            127, 2, 96,
            255, 1,  0]
  
    X12 = [238,
           12, 8,  0,
           13, 9, 13,
           31, 8,  0,
           32, 9, 29,
           41, 8,  0,
           42, 9, 41,
           47, 8,  0,
           57, 9, 44,
           64, 8,  0,
           90, 9, 51,
           255, 8,  0]
    
    # See https://www.gs1.org/standards/gs1-datamatrix-guideline/25
    FNC1 = 29
    FNC1_CODEWORD = 232
    
    DEFAULT_ENCODINGS = %i[ascii c40 txt x12 edifact base gs1].freeze
    ENCODINGS = (%i[gs1] + DEFAULT_ENCODINGS).freeze
    
    def initialize(msg, rect: false, encoding: nil)
      @m = []
      @width = 0
      @height = 0
      raise ArgumentError, "illegal encoding #{encoding.inspect}" if encoding && !ENCODINGS.include?(encoding)
      @encoding, @encoded_message = encode_message(msg, encoding)
      raise EncodingError, "illegal payload" unless @encoded_message
      encode(@encoded_message, rect)
    end
    
    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} #{width}x#{height}@#{encoding}>"
    end
    
    def to_i
      (0..(height - 1)).inject(0) { |i, y| (0..(width - 1)).inject(i) { |j, x| (j << 1) | (bit?(x,y) ? 1 : 0) } }
    end
    
    def to_s(pad: 2)
      (0..(height - 1)).inject('') do |s, y|
        (0..(width - 1)).inject(s) { |t, x| t << (bit?(x,y) ? '██' : '  ') } << "\n"
      end
    end
    
    def to_svg(dim: 256, pad: 2, bgcolor: nil, color: '#000')
      raise ArgumentError, 'illegal dimension' unless dim > 0
      raise ArgumentError, 'illegal padding' unless pad >= 0
      color ||= '#000'
      path = ''
      sx = width + pad * 2
      sy = height + pad * 2
      mx = [1, 0, 0, 1, pad, pad]
      y = height
      while y > 0
        y -= 1
        x = width
        while x > 0
          x -= 1
          path << "M#{x},#{y}h1v1h-1v-1z" if bit?(x,y)
        end
      end
      builder = Builder::XmlMarkup.new
      builder.tag! 'svg', xmlns: 'http://www.w3.org/2000/svg',
        viewBox: [0, 0, sx, sy].join(' '),
        width: dim * sx / sy,
        height: dim,
        fill: color,
        'shape-rendering' => 'crispEdges',
        version: '1.1' do |svg|
        svg.path fill: bgcolor, d: "M0,0v#{sy}h#{sx}V0H0Z" if bgcolor
        svg.path transform: "matrix(#{mx.map(&:to_s).join(',')})", d: path
      end
      builder.target!
    end
    
    def to_png(mod: 8, pad: 2, bgcolor: nil, color: '#000')
      raise ArgumentError, 'module size too small' unless mod > 0
      raise ArgumentError, 'padding too small' unless pad >= 0
      color = color ? ChunkyPNG::Color(color) : ChunkyPNG::Color('black')
      bgcolor = bgcolor ? ChunkyPNG::Color(bgcolor) : ChunkyPNG::Color::TRANSPARENT
      width_px = mod * (width + pad * 2)
      height_px = mod * (height + pad * 2)
      png = ChunkyPNG::Image.new(width_px, height_px, bgcolor)
      sx = sy = mod * pad
      (0..(height - 1)).each do |y|
        (0..(width - 1)).each do |x|
          png.rect(sx + x * mod, sy + y * mod, sx + (x + 1) * mod, sy + (y + 1) * mod, color, color) if bit?(x,y)
        end
      end
      png
    end
    
    private
    
    def bit!(x, y)
      @m[y] ||= []
      @m[y][x] = 1
    end
  
    def bit?(x, y)
      @m[y] && @m[y][x]
    end
  
    def ascii_encode(t)
      bytes, result = t.bytes, []
      while c = bytes.shift
        if !bytes.empty? && c > 47 && c < 58 && bytes.first > 47 && bytes.first < 58
          result << (c - 48) * 10 + bytes.shift + 82
        elsif c > 127
          result << 235
          result << ((c - 127) & 255)
        else
          result << c + 1
        end
      end
      result
    end

    def gs1_encode(t)
      bytes, result = t.bytes, []
      while c = bytes.shift
        if !bytes.empty? && c > 47 && c < 58 && bytes.first > 47 && bytes.first < 58
          result << (c - 48) * 10 + bytes.shift + 82
        elsif c > 127
          result << 235
          result << ((c - 127) & 255)
        elsif c == FNC1
          result << FNC1_CODEWORD
        else
          result << c + 1
        end
      end
      result
    end
  
    def base_encode(t)
      bytes, result = t.bytes, [231]
      result << (37 + (bytes.size / 250) & 255) if bytes.size > 250
      result << (bytes.size % 250 + 149 * (result.size + 1) % 255 + 1 & 255)
      bytes.each { |c| result << (c + 149 * (result.size + 1) % 255 + 1 & 255) }
      result
    end
  
    def edifact_encode(t)
      bytes = t.bytes
      return [] if bytes.any? { |c| c < 32 || c > 94 }
      l = (bytes.size + 1) & -4
      cw = 0
      result = l > 0 ? [240] : []
      (0..(l - 1)).each do |i|
        ch = i < l - 1 ? bytes[i] : 31
        cw = cw * 64 + (ch & 63)
        if i & 3 == 3
          result << (cw >> 16)
          result << (cw >> 8 & 255)
          result << (cw & 255)
          cw = 0
        end
      end
      return result if l > bytes.size
      result.concat ascii_encode(bytes[(l == 0 ? 0 : l - 1)..-1].to_a.pack('C*'))
    end
  
    def text_encode(t, s)
      cc = cw = 0
      bytes, result = t.bytes, [s[0]]
      l = bytes.size
      push = lambda do |v|
        cw = 40 * cw + v
        cc += 1
        if cc == 3
          result << ((cw += 1) >> 8)
          result << (cw & 255)
          cc = cw = 0
        end
      end
      i = 0
      while i < l
        break if 0 == cc && i == l - 1
        ch = bytes[i]
        if ch > 127 && 238 != result[0]
          push.(1)
          push.(30)
          ch -= 128
        end
        j = 1
        j += 3 while ch > s[j]
        x = s[j + 1]
        return [] if 8 == x || (9 == x && 0 == cc && i == l - 1)
        break if x < 5 && cc == 2 && i == l - 1
        push.(x) if x < 5
        push.(ch - s[j + 2])
        i += 1
      end
      push.(0) if 2 == cc && 238 != result[0]
      result << 254
      result.concat ascii_encode(bytes[(i - cc)..-1].to_a.pack('C*')) if cc > 0 || i < l
      result
    end
    
    def c40_encode(t)
      text_encode(t, C40)
    end
    
    def txt_encode(t)
      text_encode(t, TEXT)
    end
    
    def x12_encode(t)
      text_encode(t, X12)
    end
    
    def encode_message(msg, encoding)
      (encoding ? [encoding] : DEFAULT_ENCODINGS)
        .map { |name| [name, send("#{name}_encode", msg)] }
        .reject { |_, encoded| encoded.empty? }
        .min_by { |_, encoded| encoded.size }
    end
    
    def encode(enc, rct)
      el = enc.size
      nc = nr = 1
      j = -1
      b = 1
      rs = []
      rc = []
      lg = []
      ex = []
      if rct && el < 50
        k = [16,  7, 28, 11, 24, 14, 32, 18, 32, 24, 44, 28]
        begin
          w = k[j += 1]
          h = 6 + (j & 12)
          l = w * h / 8
        end while l - k[j += 1] < el
        nc = 2 if w > 25
      else
        w = h = 6
        i = 2
        k = [5, 7, 10, 12, 14, 18, 20, 24, 28, 36, 42, 48, 56, 68, 84, 112, 144, 192, 224, 272, 336, 408, 496, 620]
        begin
          j += 1
          return [0, 0] if j == k.size
          i = 4 + i & 12 if w > 11 * i
          w = h += i
          l = (w * h) >> 3
        end while l - k[j] < el
        nr = nc = 2 * (w / 54) + 2 if w > 27
        b = 2 * (l >> 9) + 2 if l > 255
      end
      s = k[j]
      fw = w / nc
      fh = h / nr
      # first padding
      if el < l - s
        enc[el] = 129
        el += 1
      end
      # more padding
      while el < l - s
        enc[el] = (((149 * (el += 1)) % 253) + 130) % 254 # WTF
      end
      s /= b
      # log / exp table of Galois field
      i, j = 0, 1
      while i < 255
        ex[i] = j
        lg[j] = i
        j += j
        j ^= 301 if j > 255
        i += 1
      end
      # RS generator polynomial
      rs[s], i = 0, 1
      while i <= s
        j = s - i
        rs[j] = 1
        while j < s
          rs[j] = rs[j + 1] ^ ex[(lg[rs[j]] + i) % 255]
          j += 1
        end
        i += 1
      end
      # RS correction data for each block
      c = 0
      while c < b
        i = 0
        while i <= s
          rc[i] = 0
          i += 1
        end
        i = c
        while i < el
          j = 0
          x = rc[0] ^ enc[i]
          while j < s
            rc[j] = rc[j + 1] ^ (x.nonzero? ? ex[(lg[rs[j]] + lg[x]) % 255] : 0)
            j += 1
          end
          i += b
        end
        # interleaved correction data
        i = 0
        while i < s
          enc[el + c + i * b] = rc[i]
          i += 1
        end
        c += 1
      end
      # layout perimeter finder pattern
      # horizontal
      i = 0
      while i < h + 2 * nr
        j = 0
        while j < w + 2 * nc
          bit!(j, i + fh + 1)
          bit!(j, i) if j & 1 == 0
          j += 1
        end
        i += fh + 2
      end
      # vertical
      i = 0
      while i < w + 2 * nc
        j = 0
        while j < h
          bit!(i, j + (j / fh) * 2 + 1)
          bit!(i + fw + 1, j + (j / fh) * 2) if j & 1 == 1
          j += 1
        end
        i += fw + 2
      end
      s, c, r = 2, 0, 4
      b =  [0, 0, -1, 0, -2, 0, 0, -1, -1, -1, -2, -1, -1, -2, -2, -2]
      # diagonal steps
      i = 0
      while i < l
        if r == h - 3 && c == -1
          # corner A layout
          k = [w, 6 - h,
               w, 5 - h,
               w, 4 - h,
               w, 3 - h,
               w - 1, 3 - h,
               3,     2,
               2,     2,
               1,     2]
        elsif r == h + 1 && c == 1 && w & 7 == 0 && h & 7 == 6
          # corner D layout
          k = [w - 2,     -h,
               w - 3,     -h,
               w - 4,     -h,
               w - 2, -1 - h,
               w - 3, -1 - h,
               w - 4, -1 - h,
               w - 2, -2,
               -1,    -2]
        else
          if r == 0 && c == w - 2 && (w & 3).nonzero?
            # corner B: omit upper left
            r -= s
            c += s
            next
          end
          if r < 0 || c >= w || r >= h || c < 0
            # outside
            s = -s
            r += 2 + s / 2
            c += 2 - s / 2
            while r < 0 || c >= w || r >= h || c < 0
              r -= s
              c += s
            end
          end
          if r == h - 2 && c == 0 && (w & 3).nonzero?
            # corner B layout
            k = [w - 1, 3 - h,
                 w - 1, 2 - h,
                 w - 2, 2 - h,
                 w - 3, 2 - h,
                 w - 4, 2 - h,
                 0,     1,
                 0,     0,
                 0,    -1]
          elsif r == h - 2 && c == 0 && w & 7 == 4
            # corner C layout
            k = [w - 1, 5 - h,
                 w - 1, 4 - h,
                 w - 1, 3 - h,
                 w - 1, 2 - h,
                 w - 2, 2 - h,
                 0,     1,
                 0,     0,
                 0,    -1]
          elsif r == 1 && c == w - 1 && w & 7 == 0 && h & 7 == 6
            # omit corner D
            r -= s
            c += s
            next
          else
            # nominal L-shape layout
            k = b
          end
        end
        # layout each bit
        el = enc[i]
        i += 1
        j = 0
        while el > 0
          if (el & 1).nonzero?
            x = c + k[j]
            y = r + k[j + 1]
            # wrap around
            if x < 0
              x += w
              y += 4 - ((w + 4) & 7)
            end
            if y < 0
              y += h
              x += 4 - ((h + 4) & 7)
            end
            # region gap
            bit!(x + 2 * (x / fw) + 1, y + 2 * (y / fh) + 1)
          end
          j += 2
          el >>= 1
        end
        r -= s
        c += s
      end
      # unfilled corner
      i = w
      while (i & 3).nonzero?
        bit!(i, i)
        i -= 1
      end
      @width = w + 2 * nc
      @height = h + 2 * nr
    end
  end
end