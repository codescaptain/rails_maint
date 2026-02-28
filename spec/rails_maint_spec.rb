RSpec.describe RailsMaint do
  it 'has a version number' do
    expect(RailsMaint::VERSION).not_to be_nil
  end

  it 'has a version string in semver format' do
    expect(RailsMaint::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
