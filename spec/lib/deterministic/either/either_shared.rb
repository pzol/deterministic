shared_examples 'Either' do
  let(:either_name) { described_class.name.split("::")[-1]}
  specify { expect(subject.value).to eq 1 }
  specify { expect(either.new(subject)).to eq either.new(1) }

  it "#fmap" do
    expect(either.new(1).fmap { |e| e + 1 }).to eq either.new(2)
  end

  it "#bind" do
    expect(either.new(1).bind { |v| either.new(v + 1)}).to eq either.new(2)
  end

  it "#to_s" do
    expect(either.new(1).to_s).to eq "1"
    expect(either.new({a: 1}).to_s).to eq "{:a=>1}"
  end

  it "#inspect" do
    expect(either.new(1).inspect).to eq "#{either_name}(1)"
    expect(either.new(:a=>1).inspect).to eq "#{either_name}({:a=>1})"
  end
end
