require 'spec_helper'
require_relative 'list'

describe List do
  Nil  = List::Nil
  Cons = List::Cons

  subject(:list) { Nil.new.append(1) }

  specify { expect(list).to eq Cons.new(1, Nil.new) }

  context "match" do
    it "catches ignores guards with non-matching clauses" do
      expect(
        list.match {
          Nil()       { self }
          Cons(h, t, where { h == 0 })  { h }
          Cons(h, t)  { h }
        }).to eq 1
    end

    it "catches matching guards" do
      expect( # guard catched
        list.match {
          Nil() { raise "unreachable" }
          Cons(h, t, where { h == 1 })  { h + 1 }
          Cons(h, t)  { h }
        }).to eq 2
    end

    it "raises an error when no match was made" do
      expect {
        list.match {
          Cons(_, _, where { true == false }) { 1 }
          Nil(where { true == false }) { 0 } 
        }
      }.to raise_error(Deterministic::Enum::MatchError)
    end

    it "raises an error when the match is not exhaustive" do
      expect {
        list.match {
          Cons(_, _) {}
        }
      }.to raise_error(Deterministic::Enum::MatchError)
    end
  end

  context "head" do
    specify { expect(list.head).to eq 1 }
  end

  context "tail" do
    subject(:list) { Nil.new.append(21).append(15).append(9).append(3) }
    specify { expect(list.tail.to_s).to eq "9, 15, 21, Nil" }
  end

  context "take" do
    subject(:list) { Nil.new.append(21).append(15).append(9).append(3) }
    specify { expect(list.take(2).to_s).to eq "3, 9, Nil" }
  end

  context "drop" do
    subject(:list) { Nil.new.append(21).append(15).append(9).append(3) }
    specify { expect(list.drop(2).to_s).to eq "15, 21, Nil" }
  end

  context "null" do
    specify { expect(Nil.new).to be_null }
    specify { expect(Cons.new(1, Nil.new)).not_to be_null }
  end

  context "length" do
    subject(:list) { Nil.new.append(21).append(15).append(9).append(3) }
    specify { expect(list.length).to eq 4 }
    specify { expect(Nil.new.length).to eq 0 }
  end

  context "filter" do
    subject(:list) { Nil.new.append(21).append(15).append(9).append(3) }
    specify { expect(list.filter { |n| n < 10 }.to_s).to eq "3, 9, Nil" }
    specify { expect(Nil.new.filter { |n| n < 10 }).to eq Nil.new }
  end

  context "map" do
    subject(:list) { Nil.new.append(1).append(2).append(3).append(4) }

    specify { expect(list.map { |h, t| h + 1 }).to eq Cons.new(5, Cons.new(4, Cons.new(3, Cons.new(2, Nil.new)))) }
  end

  context "first & last" do
    subject(:list) { Nil.new.append(21).append(15).append(9) }
    specify { expect(list.first.head).to eq 9 }
    specify { expect(list.last.head).to eq 21 }

    specify { expect(Nil.new.first).to eq Nil.new }
    specify { expect(Nil.new.last).to eq Nil.new }
  end

  context "init" do
    subject(:list) { Nil.new.append(21).append(15).append(9) }
    specify { expect(list.init.to_s).to eq "9, 15, Nil" }
    specify { expect { Nil.new.init}.to raise_error EmptyListError }
  end

  context "foldl" do
    subject(:list) { Nil.new.append(21).append(15).append(9) }
    specify { expect(list.sum).to eq 45 }
    specify { expect { Nil.new.foldl(0, &:+) }.to raise_error EmptyListError }
  end

  context "reverse" do
    subject(:list) { Nil.new.append(21).append(15).append(9) }
    # specify { expect(list.reverse.first.head).to eq 21 }
    specify { expect(list.to_s).to eq "9, 15, 21, Nil" }
    specify { expect(list.reverse.to_s).to eq "21, 15, 9, Nil" }
  end

  context "to_a" do
    subject(:list) { Nil.new.append(21).append(15).append(9) }
    specify { expect(list.to_a).to eq [21, 15, 9] }
  end

  context "all?" do
    subject(:list) { Nil.new.append(21).append(15).append(9) }
    specify { expect(list.all? { |n| n.is_a?(Fixnum) }).to be_truthy }
  end

  context "any?" do
    subject(:list) { Nil.new.append(21).append(15).append(9) }
    specify { expect(list.any? { |n| n == 11 }).to be_falsey }
    specify { expect(list.any? { |n| n == 15 }).to be_truthy }
  end

  it "inspect" do
    list = Nil.new.append(21).append(15).append(9)
    expect(list.inspect).to eq "Cons(head: 9, tail: Cons(head: 15, tail: Cons(head: 21, tail: Nil)))"
    expect(Nil.new.inspect).to eq "Nil"
  end

  it "to_s" do
    list = Nil.new.append(21).append(15).append(9)
    expect(list.to_s).to eq "9, 15, 21, Nil"
    expect(Nil.new.to_s).to eq "Nil"
  end
end
