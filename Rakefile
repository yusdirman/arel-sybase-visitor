require 'rubygems'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'arel-sybase-visitor'

    gemspec.summary          = %[Sybase ASE visitor for AREL]
    gemspec.description      = %[Sybase ASE doesn't implement LIMIT and OFFSET. This visitor implements them for usage with arel's .limit() and .offset()]
    gemspec.homepage         = 'http://github.com/ifad/arel-sybase-visitor'

    gemspec.authors          = ['Mirek Rusin', 'Marcello Barnaba']
    gemspec.email            = ['mirek@me.com', 'vjt@openssl.it']
    gemspec.version          = '0.1.0'
    gemspec.extra_rdoc_files = FileList['README.markdown']
    gemspec.has_rdoc         = true
  end

rescue LoadError
  puts 'Jeweler not available. Install it with: gem install jeweler'
end
