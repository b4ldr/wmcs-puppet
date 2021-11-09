require_relative '../../../../rake_modules/spec_helper'

describe 'envoyproxy::tls_terminator' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts.merge({:initsystem => 'systemd'})}
      let(:title) { '443' }
      context 'when envoyproxy is defined' do
        let(:pre_condition) {'class { "envoyproxy": ensure => present, admin_port => 9191, pkg_name => "envoyproxy", service_cluster => "example" }'}

        context 'simple http termination (no SNI)' do
          let(:params) do
            {
                :upstreams => [
                    {
                        :server_names  => ['*'],
                        :upstream      => {
                            :port => 80,
                        },
                        :certificates => :undef
                    },
                ],
                :global_certs => [
                    {
                        :cert_path => '/etc/ssl/localcerts/appservers.crt',
                        :key_path  => '/etc/ssl/localcerts/appservers.key',
                    }
                ]
            }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_envoyproxy__listener('tls_terminator_443')
                                .with_priority(0)
                                .with_content(/port_value: 443/)
                                .with_content(/# Non-SNI support/)
                                .with_content(/domains: \["\*"\]/)
                                .without_content(/name: default/)
          }
        end
        context 'multi-service (SNI) termination' do
          let(:title) { "123" }
          let(:params) do
            {
              :upstreams => [
                {
                  server_names: ['citoid.svc.eqiad.wmnet', 'citoid'],
                  certificates: [
                    {
                        cert_path: '/etc/ssl/localcerts/citoid.crt',
                        key_path: '/etc/ssl/localcerts/citoid.key',
                    },
                  ],
                  upstream: {
                      port: 1234,
                  },
                },
                {
                  server_names: ['pdfrenderer.svc.eqiad.wmnet', 'pdfrenderer'],
                  certificates: [
                    {
                        cert_path: '/etc/ssl/localcerts/evil.crt',
                        key_path: '/etc/ssl/localcerts/evil.key',
                    },
                  ],
                  upstream: {
                      port: 666,
                  },
                }],
            }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_envoyproxy__listener('tls_terminator_123')
                                .with_priority(0)
                                .with_content(/port_value: 123/)
                                .without_content(/# Non-SNI support/)
                                .with_content(/server_names: \["citoid.svc.eqiad.wmnet", "citoid"\]/)
                                .with_content(/^\s+cluster: local_port_1234$/)
                                .with_content(/^\s+timeout: 65.0s$/)
          }
        end
      end
      context 'without envoyproxy defined' do
        it { is_expected.to compile.and_raise_error(/envoyproxy::tls_terminator should only be used once/) }
      end
    end
  end
end
