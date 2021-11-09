require_relative '../../../../rake_modules/spec_helper'

describe 'bacula::director::fileset', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'something' }
      let(:params) { { :includes => ["/", "/var",], } }
      let(:pre_condition) do
        "class {'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
      }"
      end

      it 'should create /etc/bacula/conf.d/fileset-something.conf' do
        should contain_file('/etc/bacula/conf.d/fileset-something.conf').with({
          'ensure'  => 'present',
          'owner'   => 'root',
          'group'   => 'bacula',
          'mode'    => '0440',
        })
      end

      context 'without excludes' do
        it 'should create valid content for /etc/bacula/conf.d/fileset-something.conf' do
          should contain_file('/etc/bacula/conf.d/fileset-something.conf') \
            .with_content(%r{File = /}) \
            .with_content(%r{File = /var})
        end
      end

      context 'with excludes' do
        let(:params) { {
          :includes    => ["/", "/var",],
          :excludes    => ["/tmp",],
        }
        }
        it 'should create valid content for /etc/bacula/conf.d/fileset-something.conf' do
          should contain_file('/etc/bacula/conf.d/fileset-something.conf') \
            .with_content(%r{File = /}) \
            .with_content(%r{File = /var}) \
            .with_content(%r{File = /tmp})
        end
      end
    end
  end
end
