require 'spec_helper'
require 'deterministic'

include Deterministic

module Examples
  module Bookings

    module Adapters
      class BookingsRepo
        def find(params)
        end
      end
    end

    class FakeWebUi
      def method_missing(m, *args)
        { m => args }
      end
    end

    class Dependencies
      include Adapters
      def bookings_repo
        BookingsRepo.new
      end
    end

    class ShowBookings
      def initialize(world=FakeWebUi.new, deps=Dependencies.new)
        @world         = world
        @world.booking_list([])
        @bookings_repo = deps.bookings_repo
      end

      def call(dirty_params)
        result = Either.attempt_all(self) do
          try {          parse_params(dirty_params) }
          let { |params| read_bookings(params)           }
        end.match(world) do
          success(Array)         { |bookings| booking_list(bookings) }
          success                { |booking|  booking(booking)       }
          failure(:no_bookings)  { empty_booking_list                }
          failure(StandardError) { |ex| raise ex }
          any                    { |result| raise "Something went terribly wrong `#{result.class}`" }
        end
      end

    # private
      attr_reader   :bookings_repo, :world

      def parse_params(dirty_params)
        dirty_params
      end

      def read_bookings(params)
        bookings = [params]
        case bookings
          when nil; Failure(:no_bookings)
          when bookings.count == 1; 
          else Success(bookings)
        end
      end
    end
  end
end

describe Examples::Bookings::ShowBookings do
  subject { described_class.new }
  it "works" do
    expect(
      subject.call({status: 'confirmed'})
    ).to eq({:booking_list=>[[{:status=>"confirmed"}]]})
  end
end
