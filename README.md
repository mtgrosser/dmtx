[![Gem Version](https://badge.fury.io/rb/dmtx.svg)](https://badge.fury.io/rb/dmtx)

# dmtx
Pure Ruby Data Matrix generator

## Installation

In your Gemfile:

```ruby
gem 'dmtx'
```

## Usage

```ruby
dmtx = Dmtx::DataMatrix.new('Chunky Bacon')

puts dmtx.to_s

██  ██  ██  ██  ██  ██  ██  ██  
██  ██████  ██  ██          ████
████  ██  ██████████████  ████  
██    ████  ██  ██████  ██    ██
██    ████    ██  ██    ██████  
██  ██████  ████████████    ████
██    ██  ████    ██    ██      
██      ██        ██████  ██  ██
██  ████      ████  ████████    
██  ████    ██    ████  ██  ████
████          ██████████████    
██  ██  ████  ████  ██  ██  ████
██    ████  ██    ██            
████████    ██  ██      ████  ██
██  ██  ██████    ██████    ██  
████████████████████████████████

dmtx.width
=> 16

dmtx.height
=> 16

# Generate SVG
dmtx.to_svg
=> "<svg xmlns= ..."

# SVG default options
dmtx.to_svg(dim: 256, pad: 2, bgcolor: nil, color: '#000')

# Generate PNG with given module pixel size
dmtx.to_png
=> <ChunkyPNG::Image 160x160>

# raw PNG data
dmtx.to_png.to_s
=> "\x89PNG..."

# PNG default options
dmtx.to_png(mod: 8, pad: 2, bgcolor: nil, color: '#000')

# Integer representation
dmtx.to_i
=> 77194835539484717974890203635482091341863808501307723137647139603919014133759

# Binary representation
dmtx.to_i.to_s(2)
=> "1010101010101010101110101000001111010111111101101001101011101001100110010100111010111011111100111001011001001000100010000111010110110001101111001011001001101011110000011111110010101101101010111001101001000000111100101000110110101110011100101111111111111111"
