require 'spec_helper'

describe Deterministic::Sequencer do
  include Deterministic::Prelude::Result

  let(:test_class) { Class.new { include Deterministic::Sequencer } }
  let(:test_instance) { test_class.new }
  let(:arbitrary_success) { Success(double) }

  # This mock method makes #arbitrary_success available within the operations
  # in the test sequences
  before { allow(test_instance).to receive(:arbitrary_success).and_return(arbitrary_success) }

  it 'requires #and_yield to be specified' do
    expect do
      in_sequence do
        get(:_) { arbitrary_success }
      end
    end.to raise_error(described_class::InvalidSequenceError, 'and_yield not called')
  end

  it 'does not allow calling #and_yield multiple times' do
    expect do
      in_sequence do
        and_yield { arbitrary_success }
        and_yield { arbitrary_success }
      end
    end.to raise_error(described_class::InvalidSequenceError, 'and_yield already called')
  end

  it 'does not allow calling #get after #and_yield' do
    expect do
      in_sequence do
        and_yield { arbitrary_success }
        get(:_) { arbitrary_success }
      end
    end.to raise_error(described_class::InvalidSequenceError, 'and_yield already called')
  end

  it 'does not allow calling #and_then after #and_yield' do
    expect do
      in_sequence do
        and_yield { arbitrary_success }
        and_then { arbitrary_success }
      end
    end.to raise_error(described_class::InvalidSequenceError, 'and_yield already called')
  end

  it 'does not allow calling #observe after #and_yield' do
    expect do
      in_sequence do
        and_yield { arbitrary_success }
        observe { arbitrary_success }
      end
    end.to raise_error(described_class::InvalidSequenceError, 'and_yield already called')
  end

  context 'when #and_yield succeeds' do
    let(:yielder_result) { Success('yield') }
    before { allow(test_instance).to receive(:yielder).and_return(yielder_result) }

    it "returns and_yield's result" do
      result = in_sequence do
        and_yield { yielder }
      end
      expect(result).to eq(yielder_result)
    end

    it 'ignores the return value of the #in_sequence block' do
      result = in_sequence do
        and_yield { yielder }
        'a different return value'
      end
      expect(result).to eq(yielder_result)
    end
  end

  context 'when #and_yield fails' do
    let(:yielder_result) { Failure('yield') }
    before { allow(test_instance).to receive(:yielder).and_return(yielder_result) }

    it "returns and_yield's result" do
      result = in_sequence do
        and_yield { yielder }
      end
      expect(result).to eq(yielder_result)
    end
  end

  context 'when #get succeeds' do
    let(:getter_result) { Success('get') }
    before { allow(test_instance).to receive(:getter).and_return(getter_result) }

    it 'its result is available in a subsequent #get' do
      allow(test_instance).to receive(:second_getter).and_return(arbitrary_success)

      in_sequence do
        get(:get_result) { getter }
        get(:_) { second_getter(get_result) }
        and_yield { arbitrary_success }
      end

      expect(test_instance).to have_received(:second_getter).with(getter_result.value)
    end

    it 'its result is not available in a previous #get' do
      allow(test_instance).to receive(:second_getter)

      expect do
        in_sequence do
          get(:_) { second_getter(get_result) }
          get(:get_result) { getter }
          and_yield { arbitrary_success }
        end
      end.to raise_error(NameError)
    end

    it 'its result is available in a subsequent #and_then' do
      allow(test_instance).to receive(:and_then_function).and_return(arbitrary_success)

      in_sequence do
        get(:get_result) { getter }
        and_then { and_then_function(get_result) }
        and_yield { arbitrary_success }
      end

      expect(test_instance).to have_received(:and_then_function).with(getter_result.value)
    end

    it 'its result is not available in a previous #and_then' do
      allow(test_instance).to receive(:and_then_function)

      expect do
        in_sequence do
          and_then { and_then_function(get_result) }
          get(:get_result) { getter }
          and_yield { arbitrary_success }
        end
      end.to raise_error(NameError)
    end

    it 'its result is available in a subsequent #observe' do
      allow(test_instance).to receive(:observer)

      in_sequence do
        get(:get_result) { getter }
        observe { observer(get_result) }
        and_yield { arbitrary_success }
      end

      expect(test_instance).to have_received(:observer).with(getter_result.value)
    end

    it 'its result is not available in a previous #observe' do
      allow(test_instance).to receive(:observer)

      expect do
        in_sequence do
          observe { observer(get_result) }
          get(:get_result) { getter }
          and_yield { arbitrary_success }
        end
      end.to raise_error(NameError)
    end

    it 'its result is available in #and_yield' do
      allow(test_instance).to receive(:yielder).and_return(arbitrary_success)

      in_sequence do
        get(:get_result) { getter }
        and_yield { yielder(get_result) }
      end

      expect(test_instance).to have_received(:yielder).with(getter_result.value)
    end
  end

  context 'when multiple #gets succeed' do
    let(:first_getter_result) { Success('get1') }
    let(:second_getter_result) { Success('get2') }

    before do
      allow(test_instance).to receive(:first_getter).and_return(first_getter_result)
      allow(test_instance).to receive(:second_getter).and_return(second_getter_result)
    end

    it 'both results are available in subsequent operations' do
      allow(test_instance).to receive(:yielder).and_return(arbitrary_success)

      in_sequence do
        get(:first_get_result) { first_getter }
        get(:second_get_result) { second_getter }
        and_yield { yielder(first_get_result, second_get_result) }
      end

      expect(test_instance).to have_received(:yielder)
        .with(first_getter_result.value, second_getter_result.value)
    end
  end

  context 'when #get fails' do
    let(:getter_result) { Failure('get') }
    before { allow(test_instance).to receive(:getter).and_return(getter_result) }

    it 'does not invoke subsequent #gets' do
      allow(test_instance).to receive(:second_getter).and_return(arbitrary_success)

      in_sequence do
        get(:get_result) { getter }
        get(:_) { second_getter(get_result) }
        and_yield { arbitrary_success }
      end

      expect(test_instance).not_to have_received(:second_getter)
    end

    it 'does not invoke subsequent #and_thens' do
      allow(test_instance).to receive(:and_then_function).and_return(arbitrary_success)

      in_sequence do
        get(:get_result) { getter }
        and_then { and_then_function(get_result) }
        and_yield { arbitrary_success }
      end

      expect(test_instance).not_to have_received(:and_then_function)
    end

    it 'does not invoke subsequent #observes' do
      allow(test_instance).to receive(:observer)

      in_sequence do
        get(:get_result) { getter }
        observe { observer(get_result) }
        and_yield { arbitrary_success }
      end

      expect(test_instance).not_to have_received(:observer)
    end

    it 'does not invoke #and_yield' do
      allow(test_instance).to receive(:yielder).and_return(arbitrary_success)

      in_sequence do
        get(:get_result) { getter }
        and_yield { yielder }
      end

      expect(test_instance).not_to have_received(:yielder)
    end

    it 'returns the failure' do
      result = in_sequence do
        get(:get_result) { getter }
        and_yield { arbitrary_success }
      end

      expect(result).to eq(getter_result)
    end
  end

  context 'when #and_then succeeds' do
    let(:and_then_result) { Success('and_then') }
    before { allow(test_instance).to receive(:and_then_function).and_return(and_then_result) }

    it 'continues the sequence' do
      allow(test_instance).to receive(:another_step).and_return(arbitrary_success)

      in_sequence do
        and_then { and_then_function }
        and_then { another_step }
        and_yield { arbitrary_success }
      end

      expect(test_instance).to have_received(:another_step)
    end
  end

  context 'when #and_then fails' do
    let(:and_then_result) { Failure('and_then') }
    before { allow(test_instance).to receive(:and_then_function).and_return(and_then_result) }

    it 'does not continue the sequence' do
      allow(test_instance).to receive(:another_step).and_return(arbitrary_success)

      in_sequence do
        and_then { and_then_function }
        and_then { another_step }
        and_yield { arbitrary_success }
      end

      expect(test_instance).not_to have_received(:another_step)
    end

    it 'returns the failure' do
      result = in_sequence do
        and_then { and_then_function }
        and_yield { arbitrary_success }
      end

      expect(result).to eq(and_then_result)
    end
  end

  context 'when #observe returns a failure' do
    let(:observe_result) { Failure('observe') }
    before { allow(test_instance).to receive(:observer).and_return(observe_result) }

    it 'its return value is ignored and the sequence continues' do
      allow(test_instance).to receive(:another_step).and_return(arbitrary_success)

      in_sequence do
        observe { observer }
        and_then { another_step }
        and_yield { arbitrary_success }
      end

      expect(test_instance).to have_received(:another_step)
    end
  end


  it 'does not allow calling methods outside of the wrapped instance' do
    expect do
      in_sequence do
        and_yield { top_level_test_method }
      end
    end.to raise_error(NameError)
  end

  context 'when including Deterministic::Prelude' do
    let(:test_class) { Class.new { include Deterministic::Prelude } }

    it '#in_sequence is available' do
      expect do
        in_sequence do
          and_yield { arbitrary_success }
        end
      end.not_to raise_error
    end
  end

  context 'readme example' do
    let(:test_class) do
      Class.new do
        include Deterministic::Prelude

        def call(input)
          in_sequence do
            get(:sanitized_input) { sanitize(input) }
            and_then              { validate(sanitized_input) }
            get(:user)            { get_user_from_db(sanitized_input) }
            get(:request)         { build_request(sanitized_input, user) }
            observe               { log('sending request', request) }
            get(:response)        { send_request(request) }
            observe               { log('got response', response) }
            and_yield             { format_response(response) }
          end
        end

        def sanitize(input)
          sanitized_input = input
          Success(sanitized_input)
        end

        def validate(sanitized_input)
          Success(sanitized_input)
        end

        def get_user_from_db(sanitized_input)
          Success(type: :admin, id: sanitized_input.fetch(:id))
        end

        def build_request(sanitized_input, user)
          Success(input: sanitized_input, user: user)
        end

        def log(message, data)
          # logger.info(message, data)
        end

        def send_request(request)
          Success(status: 200)
        end

        def format_response(response)
          Success(response: response, message: 'it worked')
        end
      end
    end

    it 'returns expected result' do
      result = test_instance.call(id: 1)

      expect(result).to eq(Success(
        response: {status: 200},
        message: 'it worked'
      ))
    end

    it 'logs expected values' do
      allow(test_instance).to receive(:log).and_call_original

      test_instance.call(id: 1)

      expect(test_instance).to have_received(:log)
        .with('sending request',
          input: {id: 1},
          user: {type: :admin, id: 1}
        )
        .ordered
      expect(test_instance).to have_received(:log)
        .with('got response', status: 200)
        .ordered
    end
  end

  def in_sequence(&block)
    test_instance.instance_eval do
      in_sequence(&block)
    end
  end
end

def top_level_test_method
  :empty
end
