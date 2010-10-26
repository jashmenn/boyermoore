#############################################################
# Boyer-Moore for Ruby                                      #
# Author: Arne Brasseur (myfirstname@firstnamelastname.net) #
#                                                           #
# Licence: public domain                                    #
#                                                           #
#############################################################

# Some helpers

class String  

  # Take first n characters
  def first(n=1)  
    self.unpack('U*').first(n).pack('U*')
  end  

  # Take last n characters
  def last(n=1)  
    self.unpack('U*').last(n).pack('U*')
  end  
end

module Kernel

  # Shorthand
  def max(i1,i2); i1 > i2 ? i1 : i2; end
end


# This implementation is based on the C implementation found
# on Wikipedia. The purpose is mostly educational, since 
# String#index has the same functionality. If you want String#index
# to use this algorithm, include this module in String.
#
# It is assumed your strings are UTF-8, $KCODE is ignored.

module BoyerMoore    

  # return the position of needle in haystack, or nil if not found
  def self.search(haystack, needle)

    # Work on Arrays containing Unicode codepoint indices
    needle, haystack = needle.unpack('U*'), haystack.unpack('U*')
    
    # Maps a position in needle to a number of bytes to shift 
    # should the preceding byte differ  
    skip = []  
    
    # Maps characters in needle to their last index in needle
    occ = Hash.new {-1}
    
    return unless needle.length > 0;  
    
    #Preprocess #1: init occ[]  
    needle[0..-2].each_with_index{|c,i| occ[c]=i}  
    
    #Preprocess #2: init skip[]  
    needle.length.times do |i|  
      value=0  
      while (value < needle.length && !needlematch(needle, i, value)) do  
        value+=1  
      end  
      skip[needle.length-i-1] = value  
    end  
    
    #Search  
    hpos=0  
    while (hpos <= haystack.length - needle.length) do  
      npos = needle.length-1  
      
      # traverse the needle in reverse, if all bytes match we have a winner  
      while (needle[npos] == haystack[npos+hpos]) do
        return hpos if npos==0  
        npos -= 1;  
      end  

      # otherwise shift, either based on skip[] or based on occ[]  
      hpos += max(skip[npos], npos - occ[haystack[npos+hpos]]);
    end  
  end

  # Alternative index method for String
  def index(needle)
    BoyerMoore.search(self, needle)
  end
  
  private
    def self.needlematch(needle, length, offset)  
      #cut off offset bytes from needle  
      needle_begin = needle.first(needle.length-offset)  
      
      #if both needle and needle_begin contain at least length+1 bytes 
      if (needle_begin.length > length)  
        needle[-length-1] != needle_begin[-length-1]  &&  
          needle.last(length) == needle_begin.last(length)  
      else  
        needle.last(needle_begin.length) == needle_begin  
      end  
    end

end

#class String
#  include BoyerMoore
#end

# example

if $0 == __FILE__
  needle='abcab'
  ['12abcabc', 'abcgghhhaabcabccccc', '123456789abc123abc', 'aabbcc'].each do |hay|
    puts "#{BoyerMoore.search(hay, needle)} -- #{hay.index(needle)}"
  end
end
