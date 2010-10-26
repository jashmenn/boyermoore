require 'boyermoore'
require 'token-stream'

needle='abcab'
['12abcabc', 'abcgghhhaabcabccccc', '123456789abc123abc', 'aabbcc'].each do |hay|
  puts "#{BoyerMoore.search(hay, needle)} -- #{hay.index(needle)}"
end
