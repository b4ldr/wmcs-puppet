require_relative '../../../../rake_modules/spec_helper'

describe 'gitlab::ssh' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      describe 'default run' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
