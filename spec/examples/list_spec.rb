require 'spec_helper'
require_relative 'list'

describe List do
  Nil  = List::Nil
  Cons = List::Cons

  subject(:list) { List[1] }

  specify { expect(list).to eq Cons.new(1, Nil.new) }

  context "match" do
    it "catches ignores guards with non-matching clauses" do
      expect(
        list.match {
          Nil()       { list }
          Cons(where { h == 0 }) {|h,t| h }
          Cons()  {|h, t| h }
        }).to eq 1
    end

    it "catches matching guards" do
      expect( # guard catched
        list.match {
          Nil() { raise "unreachable" }
          Cons(where { h == 1 }) {|h,t| h + 1 }
          Cons() {|h| h }
        }).to eq 2
    end

    it "raises an error when no match was made" do
      expect {
        list.match {
          Cons(where { true == false }) {|_, __| 1 }
          Nil(where { true == false }) { 0 }
        }
      }.to raise_error(Deterministic::Enum::MatchError)
    end

    it "raises an error when the match is not exhaustive" do
      expect {
        list.match {
          Cons() {|_, _| }
        }
      }.to raise_error(Deterministic::Enum::MatchError)
    end
  end

  it "empty" do
    expect(List.empty.object_id).to eq List.empty.object_id
  end

  it "from_a" do
    expect(List[21, 15, 9].to_s).to eq "21, 15, 9, Nil"
  end

  it "append" do
    expect(List[1].append(2)).to eq Cons.new(2, Cons.new(1, Nil.new))
  end

  context "head" do
    specify { expect(list.head).to eq 1 }
  end

  context "tail" do
    subject(:list) { List[3, 9, 15, 21] }
    specify { expect(list.tail.to_s).to eq "9, 15, 21, Nil" }
  end

  context "take" do
    subject(:list) { List[3, 9, 15, 21] }
    specify { expect(list.take(2).to_s).to eq "3, 9, Nil" }
  end

  context "drop" do
    subject(:list) { List[3, 9, 15, 21] }
    specify { expect(list.drop(2).to_s).to eq "15, 21, Nil" }
  end

  context "null" do
    specify { expect(Nil.new).to be_null }
    specify { expect(Cons.new(1, Nil.new)).not_to be_null }
  end

  context "length" do
    subject(:list) { List[21, 15, 9, 3] }
    specify { expect(list.length).to eq 4 }
    specify { expect(Nil.new.length).to eq 0 }
  end

  context "filter" do
    subject(:list) { List[3, 9, 15, 21] }
    specify { expect(list.filter { |n| n < 10 }.to_s).to eq "3, 9, Nil" }
    specify { expect(Nil.new.filter { |n| n < 10 }).to eq Nil.new }
  end

  context "map" do
    subject(:list) { List[1, 2, 3, 4] }

    specify { expect(list.map { |h, t| h + 1 }).to eq Cons.new(2, Cons.new(3, Cons.new(4, Cons.new(5, Nil.new)))) }
  end

  context "first & last" do
    subject(:list) { List[9, 15, 21] }
    specify { expect(list.first.head).to eq 9 }
    specify { expect(list.last.head).to eq 21 }

    specify { expect(Nil.new.first).to eq Nil.new }
    specify { expect(Nil.new.last).to eq Nil.new }
  end

  context "init" do
    subject(:list) { List[9, 15, 21] }
    specify { expect(list.init.to_s).to eq "9, 15, Nil" }
    specify { expect { Nil.new.init}.to raise_error EmptyListError }
  end

  it "foldl :: [a] -> b -> (b -> a -> b) -> b" do
    list = List[21, 15, 9]
    expect(list.foldl(0) { |b, a| a + b }).to eq (((0 + 21) + 15) + 9)
    expect(list.foldl(0) { |b, a| b - a }).to eq (((0 - 21) - 15) - 9)
    expect(Nil.new.foldl(0, &:+)).to eq 0
  end

  it "foldl1 :: [a] -> b -> (b -> a -> b) -> b" do
    list = List[21, 15, 9]
    expect(list.foldl1 { |b, a| a + b }).to eq ((21 + 15) + 9)
    expect(list.foldl1 { |b, a| b - a }).to eq ((21 - 15) - 9)
    expect { Nil.new.foldl1(&:+) }.to raise_error EmptyListError
  end

  it "foldr :: [a] -> b -> (b -> a -> b) -> b" do
    list = List[21, 15, 9]
    expect(list.foldr(0) { |b, a| a + b }).to eq (21 + (15 + (9 + 0)))
    expect(list.foldr(0) { |b, a| b - a }).to eq (21 - (15 - (9 - 0)))
    expect(Nil.new.foldr(0, &:+)).to eq 0
  end

  it "foldr1 :: [a] -> b -> (b -> a -> b) -> b" do
    list = List[21, 15, 9, 3]
    expect(list.foldr1 { |b, a| a + b }).to eq (21 + (15 + (9 + 3)))
    expect(list.foldr1 { |b, a| b - a }).to eq (21 - (15 - (9 - 3)))
    expect { Nil.new.foldr1(&:+) }.to raise_error EmptyListError
  end

  it "find :: [a] -> (a -> Bool) -> Option a" do
    list = List[21, 15, 9]
    expect(list.find { |a| a == 15 }).to eq Deterministic::Option::Some.new(15)
    expect(list.find { |a| a == 1 }).to  eq Deterministic::Option::None.new
  end

  context "reverse" do
    subject(:list) { List[9, 15, 21] }
    specify { expect(list.reverse.first.head).to eq 21 }
    specify { expect(list.to_s).to eq "9, 15, 21, Nil" }
    specify { expect(list.reverse.to_s).to eq "21, 15, 9, Nil" }
  end

  context "to_a" do
    subject(:list) { List[9, 15, 21] }
    specify { expect(list.to_a).to eq [21, 15, 9] }
  end

  context "all?" do
    subject(:list) { List[21, 15, 9] }
    specify { expect(list.all? { |n| n.is_a?(Fixnum) }).to be_truthy }
  end

  context "any?" do
    subject(:list) { List[21, 15, 9] }
    specify { expect(list.any? { |n| n == 11 }).to be_falsey }
    specify { expect(list.any? { |n| n == 15 }).to be_truthy }
  end

  it "inspect" do
    list = List[9, 15, 21]
    expect(list.inspect).to eq "Cons(head: 9, tail: Cons(head: 15, tail: Cons(head: 21, tail: Nil)))"
    expect(Nil.new.inspect).to eq "Nil"
  end

  it "to_s" do
    list = List[9, 15, 21]
    expect(list.to_s).to eq "9, 15, 21, Nil"
    expect(Nil.new.to_s).to eq "Nil"
  end
end
