require_relative '../../../../rake_modules/spec_helper'

describe 'php::fpm::pool' do
  on_supported_os(WMFConfig.test_on(9)).each do |os, facts|
    context "on #{os}" do
      let(:facts) {facts}
      let(:title) { 'www' }
      let(:pre_condition) {
        [
          'class { "::php": sapis => ["fpm"]}',
          'class { "::php::fpm": }'
        ]
      }
      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        matcher = 'listen = /run/php/fpm-www.sock'
        it { is_expected.to contain_file('/etc/php/7.0/fpm/pool.d/www.conf')
          .with_content(/#{matcher}/)
          .with_owner('root')
          .that_notifies('Service[php7.0-fpm]')
        }
      end
      context 'when provided a port' do
        let(:params) { { 'port' => 9000 } }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/php/7.0/fpm/pool.d/www.conf')
          .with_content(/listen = 127.0.0.1:9000\n/)
        }
      end
    end
  end
end
