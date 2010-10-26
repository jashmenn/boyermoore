require File.dirname(__FILE__) + '/spec_helper'
require 'boyermoore'

describe "boyermoore" do
  it "should do nothing" do
    needle='abcab'
    ['12abcabc', 'abcgghhhaabcabccccc', '123456789abc123abc', 'aabbcc'].each do |hay|
      # BoyerMoore.search(hay, needle).should == hay.index(needle)
    end
  end
  
  it "should match characters" do
    needle = "abc".split(//)
    [["abc", 0], ["bcd", nil],
     ["efg", nil], ["my dog abc", 7]].each do |hay,pos|
      hay = hay.split(//)
      BoyerMoore.search(hay, needle).should == pos
    end
    BoyerMoore.search("xxxfoobarbazxxx".split(//), "foobar".split(//)).should == 4
  end

  it "should match words" do
    needle = ["foo", "bar"]
    [ [["foo", "bar", "baz"], 0]
      # [["bam", "bar", "bang"], nil],
      # [["put", "foo", "bar"], 1]
    ].each do |hay,pos|
        # BoyerMoore.search(hay, needle).should == pos
      end
  end

end