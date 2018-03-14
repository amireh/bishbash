source 'https://rubygems.org'

group :development, :test do
  gem 'rspec'
  gem 'pry'

  if Dir.exists?(File.expand_path('../../rspec-bash', __FILE__))
    gem 'rspec-bash-x', path: '../rspec-bash'
  else
    gem 'rspec-bash-x', '~> 1.0'
  end
end