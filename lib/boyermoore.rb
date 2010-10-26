module BoyerMoore    

  def self.compute_prefix(str) 
    size = str.length
    k = 0
    result = [0]
    1.upto(size - 1) do |q|
      while (k > 0) && (str[k] != str[q])
        k = result[k-1]
      end
      k += 1 if(str[k] == str[q])
      result[q] = k
    end
    result
  end

  def self.prepare_badcharacter_heuristic(str)
    result = {}
    0.upto(str.length - 1) do |i|
      result[str[i]] = i
    end
    result
  end

  def self.prepare_goodsuffix_heuristic(normal)
    size = normal.size
    result = []
    # left = normal[0]
    # right = normal[size]
    # reversed = []
    # tmp = reversed + size   # huh
    puts "---"
    # pp left
    # pp right

    # reverse string
    reversed = normal.dup.reverse
    prefix_normal = compute_prefix(normal)
    prefix_reversed = compute_prefix(reversed)

    # pp prefix_normal
    # pp prefix_reversed

    0.upto(size) do |i|
      result[i] = size - prefix_normal[size-1]
    end

    0.upto(size-1) do |i|
      j = size - prefix_reversed[i]
      k = i - prefix_reversed[i]+1
      result[j] = k if result[j] > k
    end
    # pp result
    result
  end

  def self.search(haystack, needle)
    needle_len = needle.size
    haystack_len = haystack.size

    return nil if haystack_len == 0
    return haystack if needle_len == 0

    badcharacter = self.prepare_badcharacter_heuristic(needle)
    goodsuffix   = self.prepare_goodsuffix_heuristic(needle)

    s = 0
    while s <= haystack_len - needle_len
      j = needle_len
      while (j > 0) && (needle[j-1] == haystack[s+j-1])
        j -= 1
      end

      pp j

      if(j > 0)
        k = badcharacter[haystack[s+j-1]]
        k = -1 unless k
        if (k < j) && (m = j-k-1) > goodsuffix[j]
          s += m
        else
          s += goodsuffix[j]
        end
      else
        return s # ?
      end

    end
    return nil
  end



  # return the position of needle in haystack, or nil if not found
  def self.search_old(haystack, needle)# {{{

    # Maps a position in needle to a number of bytes to shift 
    # should the preceding byte differ  
    skip = []  
    
    # Maps characters in needle to their last index in needle
    occ = Hash.new {-1}
    
    return unless needle.size > 0;  
    
    #Preprocess #1: init occ[]  
    needle[0..-2].each_with_index{|c,i| occ[c]=i}  
    
    #Preprocess #2: init skip[]  
    needle.size.times do |i|  
      value=0  
      while (value < needle.size && !needlematch(needle, i, value)) do  
        value+=1  
      end  
      skip[needle.size] = value  
    end  
    
    #Search  
    hpos=0  
    while (hpos <= haystack.size - needle.size) do  
      npos = needle.size  
      
      # traverse the needle in reverse, if all bytes match we have a winner  
      while (needle[npos] == haystack[npos+hpos]) do
        return hpos if npos==0  
        npos -= 1;  
      end  

      # otherwise shift, either based on skip[] or based on occ[]  
      pp [skip[npos], npos, hpos, haystack[npos+hpos], occ[haystack[npos+hpos]]]
      hpos += max(skip[npos], npos - occ[haystack[npos+hpos]]);
      pp hpos
    end  
  end# }}}
  private# {{{
    def self.needlematch(needle, length, offset)  
      # puts "---------"
      # pp [needle, length, offset]
      #cut off offset bytes from needle  
      needle_begin = needle.first(needle.length-offset)  
      # pp [needle_begin, needle_begin.length, length]
      
      #if both needle and needle_begin contain at least length+1 bytes 
      if (needle_begin.length > length)
        # puts "here:"
        # pp [needle[-length-1], needle_begin[-length-1]]
        # pp [needle[-length-1] != needle_begin[-length-1]]
        # pp [needle.last(length), needle_begin.last(length)]
        # pp [needle.last(length) == needle_begin.last(length)]
        (needle[-length-1] != needle_begin[-length-1]) && (needle.last(length) == needle_begin.last(length))
      else  
        # puts "else:"
        # pp [needle_begin.length]
        # pp [needle.last(needle_begin.length), needle_begin]
        # pp [needle.last(needle_begin.length) == needle_begin]
        needle.last(needle_begin.length) == needle_begin  
      end  
    end
# }}}
end

# example

if $0 == __FILE__
  needle='abcab'
  ['12abcabc', 'abcgghhhaabcabccccc', '123456789abc123abc', 'aabbcc'].each do |hay|
    puts "#{BoyerMoore.search(hay, needle)} -- #{hay.index(needle)}"
  end
end
