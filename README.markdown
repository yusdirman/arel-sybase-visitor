# ARel Sybase ASE visitor

* http://github.com/ifad/arel-sybase-visitor

## DESCRIPTION

Arel is a Relational Algebra for Ruby. Read more about arel on http://github.com/rails/arel

This repository contains an Arel Visitor for Sybase ASE, that implements .limit() and .offset()
using ROWCOUNT and temporary tables. You should also use the cleaned up Sybase adapter, available
[onto a public IFAD GitHub Repository](http://github.com/ifad/activerecord-sybase-adapter)

## INSTALLATION

Bundler is required. Gemfile:

    gem 'activerecord-sybase-adapter', :git => 'git://github.com/ifad/activerecord-sybase-adapter'
    gem 'arel-sybase-visitor',         :git => 'git://github.com/ifad/arel-sybase-visitor', :branch => 'ase_12_5'

config/application.rb:

    config.after_initialize do
      require 'arel/visitors/sybase'
    end

The above is quite dirty, will be fixed soon.

## COMPATIBILITY

Sybase ASE >= 12.5. A version for ASE 15.0 that uses SCROLL CURSORS is in the master branch.
arel ~> 2.0.7 - earlier releases won't work.

