# A TokenStream instance stores a stream of Tokens once it has used its 
# tokenization rules to extract them from a string. A TokenStream knows its 
# current
# position (TokenStream#cur_pos), which is incremented when any of the
# Enumerable methods are used (due to the redefinition of TokenStream#each).
# As you advance through the stream, the current token is always returned and
# then consumed. A TokenStream also provides methods for finding patterns in a
# given stream much like StringScanner but for an array of tokens. For rule
# generation, a certain token can be marked as being the start point of a label.
# Finally, a TokenStream will record whether it is in a reversed or unreversed
# state so that when rules are applied, they are always applied from the front
# or end of the stream as required, whether it is reversed or not.
class TokenStream
  include Comparable
  attr_accessor :tokens, :cur_pos, :label_index, :original_text

  def initialize()
    @tokens=[]
    @cur_pos=0
    @original_text = ""
    @reversed=false
    @contains_label_tags=false
  end

  # By default uses the default tokenizer. Takes a string to be tokenized, a 
  # boolean that indicates whether the string contains labels that should be 
  # stripped, and finally a tokenizer. The passed tokenizer must respond to 
  # #tokenize, and returns an array of Tokens in the correct order.
  def tokenize(input, contains_label_tags=false, tokenizer=Tokenizer::Default)
    @original_text=input
    @contains_label_tags=contains_label_tags
    @tokens=tokenizer.tokenize(input, contains_label_tags)
    @tokens.size
  end

  def contains_label_tags?
    @contains_label_tags
  end

  # Goes through all stored Token instances, removing them if 
  # Token#is_label_tag? Called after a labeled document has been extracted 
  #toa tree ready for the rule learning process.
  def remove_label_tags
    @tokens.delete_if {|token| token.is_label_tag?}
  end

  # Returns the slice of the current instance containing all the tokens
  # between the token where the start_loc == the left parameter and the token
  # where the end_loc == the right parameter.
  def slice_by_string_pos(left, right)
    l_index=nil
    r_index=nil
    @tokens.each_index {|i| l_index = i if @tokens[i].start_loc == left}
    @tokens.each_index {|i| r_index = i if @tokens[i].end_loc == right}
    if l_index.nil? or r_index.nil?
      raise ArgumentError, "Cannot slice between those locations"
    else
      return slice_by_token_index(l_index, r_index)
    end
  end

  # Slices tokens between the l_index and the r_index inclusive.
  def slice_by_token_index(l_index, r_index)
    sliced = self.dup
    sliced.tokens=@tokens[l_index..r_index]
    return sliced
  end

  # Used to ensure operations such as @tokens.reverse! in one instance won't
  # inadvertently effect another.
  def deep_clone
    Marshal::load(Marshal.dump(self))
  end

  # Set a label at a given offset in the original text. Searches for a token
  # with a start_loc equal to the position passed as an argument, and raises
  # an error if one is not found.
  def set_label_at(pos)
    token_pos=nil
    @tokens.each_index {|i| token_pos = i if @tokens[i].start_loc == pos}
    if token_pos.nil?
      raise ArgumentError, "Given string position does not match the start of any token"
    else
      @label_index = token_pos
      Log.debug "Token ##{label_index} - \"#{@tokens[label_index].text}\" labeled."
      return @label_index
    end
  end

  # Returns all text represented by the instance's stored tokens, stripping any
  # label tags if the stream was declared to be containing them when it was
  # initialized (this would only happen during the process of loading labeled
  # examples). See also TokenStream#raw_text
  def text(l_index=0, r_index=-1)
    out=raw_text(l_index, r_index)
    if contains_label_tags?
      LabelUtils.clean_string(out)
    else
      out
    end
  end

  # Returns all text represented by the instance's stored tokens. It will not
  # strip label tags even if the stream is marked to contain them. However,
  # you should not expect to get the raw_text once any label_tags have been
  # filtered (TokenStream#remove_label_tags).
  def raw_text(l_index=0, r_index=-1)
    return "" if @tokens.size==0
    if reversed?
      l_index, r_index = r_index, l_index
    end
    @original_text[@tokens[l_index].start_loc...@tokens[r_index].end_loc]
  end

  # Returns the current Token and consumes it.
  def advance
    return nil if @cur_pos > @tokens.size
    while true
      @cur_pos+=1
      current_token = @tokens[@cur_pos-1]
      return nil if current_token.nil?
      return current_token
    end
  end

  # Return to the beginning of the TokenStream. Returns self.
  def rewind
    @cur_pos=0
    self
  end

  # Returns a copy of the current instance with a reversed set of tokens. If
  # it is set, the label_index is adjusted accordingly to point to the correct
  # token.
  def reverse
    self.deep_clone.reverse!
  end

  # Converts the given position so it points to the same token once the stream
  # is reversed. Result invalid for when @tokens.size==0
  def reverse_pos(pos)
    if pos==@tokens.size
      return 0
    else
      return tokens.size-(pos + 1)
    end
  end

  # Same as TokenStream#reverse, but changes are made in place.
  def reverse!
    @tokens.reverse!
    if label_index
      @label_index = reverse_pos(@label_index)
    end
    @reversed=!@reversed
    return self
  end

  # Returns true or false depending on whether the given tokenstream is in a
  # reversed state
  def reversed?
    @reversed
  end

  # Returns the number of tokens in the TokenStream
  def size
    @tokens.size
  end

  # Takes a list of Strings and Symbols as its arguments representing text to be matched in
  # individual tokens and Wildcards. For a match to be a
  # success, all wildcards and strings must match a consecutive sequence
  # of Tokens in the TokenStream. All matched Tokens are consumed, and the
  # TokenStream's current position is returned on success. On failure, the
  # TokenStream is returned to its original state and returns nil.
  def skip_to(*features)
    features=features.collect do |f|
      f=Wildcards.list.fetch(f) if f.kind_of? Symbol
      f
    end
    match_length=0
    shifts=compute_table(features)
    orig_pos=@cur_pos
    for token in @tokens[@cur_pos..-1]
      while (match_length >=0) and !(features[match_length]===token.text)
        @cur_pos+=shifts[match_length]
        match_length-=shifts[match_length]
      end
      match_length+=1
      if match_length == features.length
        @cur_pos+=match_length # Consume matched tokens
        return @cur_pos
      end
    end
    @cur_pos = orig_pos
    return nil
  end

  # Iterates over and consumes every Token from the cur_pos.
  def each
    while (token = self.advance)
      yield token
    end
  end

  # Returns the current Token.
  def current_token
    @tokens[@cur_pos]
  end

  def <=>(stream)
    self.tokens.first.start_loc <=> stream.tokens.first.start_loc
  end


  private
  def could_match(a, b)
    if a==b
      return true
    elsif a===b
      return true
    elsif b===a
      return true
    end
    return false
  end

  def compute_table(pattern) 
    shifts=Array.new(pattern.size)
    shift = 1
    0.upto pattern.size do |i|
      a=pattern[i-1]
      b=pattern[i-shift-1]
      while (shift < i) and !could_match(pattern[i-1], pattern[i-shift-1])
        shift += shifts[i-shift-1]
      end
      shifts[i]=shift
    end
    return shifts
  end
end
