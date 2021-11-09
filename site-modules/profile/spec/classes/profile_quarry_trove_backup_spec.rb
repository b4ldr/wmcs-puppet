require_relative '../../../../rake_modules/spec_helper'

describe 'profile::quarry::trove::backup' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { } }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
