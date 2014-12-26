# encoding: UTF-8
#
# Cookbook Name:: ssl_certificate_test
# Recipe:: self_signed_with_ca_certificate
# Description::	 Test kitchen test for testing self-signed host with CA.
# Author:: Jeremy MAURO (<j.mauro@criteo.com>)
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL. (www.onddo.com)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ca_cert = ::File.join(Chef::Config[:file_cache_path], 'CA.cert')
ca_key  = ::File.join(Chef::Config[:file_cache_path], 'CA.key')

node.default['test.com']['common_name']        = 'test.com'
node.default['test.com']['country']            = 'FR'
node.default['test.com']['city']               = 'Paris'
node.default['test.com']['state']              = 'Ile de Paris'
node.default['test.com']['organization']       = 'Toto'
node.default['test.com']['department']         = 'Titi'
node.default['test.com']['email']              = 'titi@test.com'
node.default['test.com']['ssl_key']['source']  = 'self-signed'
node.default['test.com']['ssl_cert']['source'] = 'with-ca'
node.default['test.com']['ca_cert_path']       = ca_cert
node.default['test.com']['ca_cert_key']        = ca_key

node.default['ca-certificate']['common_name']  = 'ca.test.com'
node.default['ca-certificate']['country']      = 'FR'
node.default['ca-certificate']['city']         = 'Paris'
node.default['ca-certificate']['state']        = 'Ile de Paris'
node.default['ca-certificate']['organization'] = 'Toto'
node.default['ca-certificate']['department']   = 'Titi'
node.default['ca-certificate']['email']        = 'titi@test.com'
node.default['ca-certificate']['time']         = 10 * 365

ca_name = ::CACertificate.generate_cert_subject(node['ca-certificate'])
::CACertificate.ca_key(ca_key)
::CACertificate.ca_certificate(
  ca_name, ca_key, ca_cert, node['ca-certificate']['time']
)

cert = ssl_certificate 'test' do
  namespace node['test.com']
  ca_cert_path ca_cert
  ca_key_path ca_key
end

include_recipe 'apache2'
include_recipe 'apache2::mod_ssl'

web_app 'test' do
  # this cookbook includes a virtualhost template for apache2
  cookbook 'ssl_certificate'
  # [...]
  docroot node['apache']['docroot_dir']
  server_name cert.common_name
  ssl_key cert.key_path
  ssl_cert cert.cert_path
  extra_directives EnableSendfile: 'On'
end
