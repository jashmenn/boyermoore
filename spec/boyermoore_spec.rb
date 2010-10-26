require File.dirname(__FILE__) + '/spec_helper'
require 'boyermoore'

describe "boyermoore" do
  it "should compute prefixes" do
    BoyerMoore.compute_prefix(%w{A N P A N M A N}).should == [0, 0, 0, 1, 2, 0, 1, 2]
    BoyerMoore.compute_prefix(%w{f o o b a r}).should == [0, 0, 0, 0, 0, 0]
  end

  it "should compute badcharacter heuristics" do
    BoyerMoore.prepare_badcharacter_heuristic(%w{A N P A N M A N}).should == {"A"=>6, "M"=>5, "N"=>7, "P"=>2}
    BoyerMoore.prepare_badcharacter_heuristic(%w{f o o b a r}).should == {"a"=>4, "b"=>3, "o"=>2, "f"=>0, "r"=>5}
  end

  it "should prepare goodsuffix heuristics" do
    BoyerMoore.prepare_goodsuffix_heuristic(%w{A N P A N M A N}).should == [6, 6, 6, 6, 6, 6, 3, 3, 1] 
     BoyerMoore.prepare_goodsuffix_heuristic(%w{f o o b a r}).should == [6, 6, 6, 6, 6, 6, 1]
  end

  it "should search properly" do
    BoyerMoore.search(%w{A N P A N M A N}, %w{A N P}).should == 0
    BoyerMoore.search(%w{A N P A N M A N}, %w{M A N}).should == 5
    BoyerMoore.search(%w{f o o b a r}, %w{b a r}).should == 3
  end



  # it "should do nothing" do
  #   needle='abcab'
  #   ['12abcabc', 'abcgghhhaabcabccccc', '123456789abc123abc', 'aabbcc'].each do |hay|
  #     # BoyerMoore.search(hay, needle).should == hay.index(needle)
  #   end
  # end
  
  # it "should match characters" do
  #   needle = "abc".split(//)
  #   [["abc", 0], ["bcd", nil],
  #    ["efg", nil], ["my dog abc", 7]].each do |hay,pos|
  #     hay = hay.split(//)
  #     BoyerMoore.search(hay, needle).should == pos
  #   end
  #   BoyerMoore.search("xxxfoobarbazxxx".split(//), "foobar".split(//)).should == 4
  # end

  # it "should match words" do
  #   needle = ["foo", "bar"]
  #   [ [["foo", "bar", "baz"], 0]
  #     # [["bam", "bar", "bang"], nil],
  #     # [["put", "foo", "bar"], 1]
  #   ].each do |hay,pos|
  #       # BoyerMoore.search(hay, needle).should == pos
  #     end
  # end

end