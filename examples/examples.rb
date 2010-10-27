$:.unshift(File.dirname(__FILE__) + "/../lib")
require 'boyermoore'

# search in strings
puts BoyerMoore.search("ANPANMAN", "ANP")   == 0
puts BoyerMoore.search("ANPANMAN", "ANPXX") == nil 
puts BoyerMoore.search("ANPANMAN", "MAN")   == 5
puts BoyerMoore.search("foobar", "bar")     == 3
puts BoyerMoore.search("foobar", "zar")     == nil 

# search arrays of tokens
puts BoyerMoore.search(["<b>", "hi", "</b>"], ["hi"]) == 1 
puts BoyerMoore.search(["bam", "foo", "bar"], ["foo", "bar"]) == 1 
puts BoyerMoore.search(["bam", "bar", "baz"], ["foo"]) == nil 

# search by regular expression
puts BoyerMoore.search(["Sing", "99", "Luftballon"], [/\d+/]) == 1
puts BoyerMoore.search(["Nate Murray", "5 Pine Street", "Los Angeles", "CA", "90210"], [/^\w{2}$/, /^\d{5}$/]) == 3 
