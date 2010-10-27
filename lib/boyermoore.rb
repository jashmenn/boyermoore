# Hash impersonator that accepts regular expressions as keys.  But the regular
# expression lookups are slow, so don't use them (unless you have to). 
class RichHash
  def initialize
    @regexps = {}
    @regular = {}
  end

  def [](k)
    regular = @regular[k]
    return regular if regular
    if @regexps.size > 0
      @regexps.each do |regex,v| # linear search is going to be slow
        return v if regex.match(k) 
      end
    end
    nil
  end

  def []=(k,v)
    if k.kind_of?(Regexp)
      @regexps[k] = v
    else
      @regular[k] = v
    end
  end
end

# ported directly from this version wikipedia:
# http://en.wikipedia.org/w/index.php?title=Boyer%E2%80%93Moore_string_search_algorithm&diff=391986850&oldid=391398281
# it's not very rubyish but it works
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
    result = RichHash.new
    0.upto(str.length - 1) do |i|
      result[str[i]] = i
    end
    result
  end

  def self.prepare_goodsuffix_heuristic(normal)
    size = normal.size
    result = []

    # reverse string
    reversed = normal.dup.reverse
    prefix_normal = compute_prefix(normal)
    prefix_reversed = compute_prefix(reversed)

    0.upto(size) do |i|
      result[i] = size - prefix_normal[size-1]
    end

    0.upto(size-1) do |i|
      j = size - prefix_reversed[i]
      k = i - prefix_reversed[i]+1
      result[j] = k if result[j] > k
    end
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
      while (j > 0) && self.needle_matches?(needle[j-1], haystack[s+j-1])
        j -= 1
      end

      if(j > 0)
        k = badcharacter[haystack[s+j-1]]
        k = -1 unless k
        if (k < j) && (m = j-k-1) > goodsuffix[j]
          s += m
        else
          s += goodsuffix[j]
        end
      else
        return s
      end
    end
    return nil
  end

  def self.needle_matches?(needle, haystack)
    if needle.kind_of?(Regexp)
      needle.match(haystack) ? true : false 
    else
      needle == haystack
    end
  end
end

# example

if $0 == __FILE__
  needle='abcab'
  ['12abcabc', 'abcgghhhaabcabccccc', '123456789abc123abc', 'aabbcc'].each do |hay|
    puts "#{BoyerMoore.search(hay, needle)} -- #{hay.index(needle)}"
  end
end
