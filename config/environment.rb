# encoding: utf-8
# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
LibraryApp::Application.initialize!

CASClient::Frameworks::Rails::Filter.configure(
  :cas_base_url => "https://cas.qiniu.io:9443/"
)