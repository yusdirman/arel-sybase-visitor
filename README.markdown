# ARel Sybase ASE visitor

* http://github.com/ifad/arel-sybase-visitor

## DESCRIPTION

Arel is a Relational Algebra for Ruby. Read more about arel on http://github.com/rails/arel

This repository contains an Arel Visitor for Sybase ASE, that implements .limit() and .offset()
using ROWCOUNT and cursors - with only a single nasty hack - assured! :-)

## INSTALLATION

If defined?(Bundler):

    gem 'arel-sybase-visitor', :git => 'git://github.com/ifad/arel-sybase-visitor'

else:

    gem install arel-sybase-visitor

config/application.rb:

    config.after_initialize do
      require 'arel/visitors/sybase'
    end

The above is quite dirty, will be fixed soon.

## COMPATIBILITY

arel ~> 2.0.7 - earlier releases won't work.

