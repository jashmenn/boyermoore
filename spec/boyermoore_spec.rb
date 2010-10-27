require File.dirname(__FILE__) + '/spec_helper'
require 'boyermoore'

describe "boyermoore" do
  it "should compute prefixes" do
    BoyerMoore.compute_prefix(%w{A N P A N M A N}).should == [0, 0, 0, 1, 2, 0, 1, 2]
    BoyerMoore.compute_prefix(%w{f o o b a r}).should == [0, 0, 0, 0, 0, 0]
  end

  # it "should compute badcharacter heuristics" do
  #   BoyerMoore.prepare_badcharacter_heuristic(%w{A N P A N M A N}).should == {"A"=>6, "M"=>5, "N"=>7, "P"=>2}
  #   BoyerMoore.prepare_badcharacter_heuristic(%w{f o o b a r}).should == {"a"=>4, "b"=>3, "o"=>2, "f"=>0, "r"=>5}
  # end

  it "should prepare goodsuffix heuristics" do
    BoyerMoore.prepare_goodsuffix_heuristic(%w{A N P A N M A N}).should == [6, 6, 6, 6, 6, 6, 3, 3, 1] 
     BoyerMoore.prepare_goodsuffix_heuristic(%w{f o o b a r}).should == [6, 6, 6, 6, 6, 6, 1]
  end

  it "should search properly" do
    BoyerMoore.search("ANPANMAN", "ANP").should == 0
    BoyerMoore.search("ANPANMAN", "ANPXX").should == nil 
    BoyerMoore.search("ANPANMAN", "MAN").should == 5
    BoyerMoore.search("foobar", "bar").should == 3
    BoyerMoore.search("foobar", "zar").should == nil 
  end

  it "should match ruby's #index for basic strings" do
    needle='abcab'
    ['12abcabc', 'abcgghhhaabcabccccc', '123456789abc123abc', 'aabbcc'].each do |hay|
      BoyerMoore.search(hay, needle).should == hay.index(needle)
    end
  end
  
  it "should match characters" do
    needle = "abc".split(//)
    haystacks = {
      "abc" => 0, 
      "bcd" => nil,
      "efg" => nil, 
      "my dog abc" => 7
    }
    haystacks.each do |hay,pos|
      hay = hay.split(//)
      BoyerMoore.search(hay, needle).should == pos
    end
  end

  it "should match in the middle of a string" do
    BoyerMoore.search("xxxfoobarbazxxx".split(//), "foobar".split(//)).should == 3
  end

  it "should match words" do
    needle = ["foo", "bar"]
    haystacks = {
      ["foo", "bar", "baz"] => 0,
      ["bam", "bar", "bang"] => nil,
      ["put", "foo", "bar", "bar"] => 1,
      ["put", "foo", "bar", "foo", "bar"] => 1
    }
    haystacks.each do |hay,pos|
        BoyerMoore.search(hay, needle).should == pos
      end
  end

  it "should match regular expressions" do
    needle = [/^\d+$/]
    haystacks = {
      ["999"] => 0,
      ["foo", "99", "x"] => 1,
      ["foo99", "10", "10"] => 1
    } 
    haystacks.each do |hay,pos|
        BoyerMoore.search(hay, needle).should == pos
    end
  end

  describe "richhash" do
    it "should allow regular hash semantics" do
      h = RichHash.new
      h[1] = "foo"
      h[1].should == "foo"
    end

    it "should allow regexp semantics" do
      h = RichHash.new
      h["a"] = "b"
      h[/\d+/] = "bing"
      h["a"].should == "b"
      h["b"].should == nil
      h["9"].should == "bing"
      h["99"].should == "bing"
      h["a99"].should == "bing"
    end
  end

end