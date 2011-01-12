# ARel Sybase ASE visitor

* http://github.com/ifad/arel-sybase-visitor

## DESCRIPTION

Arel is a Relational Algebra for Ruby. Read more about arel on http://github.com/rails/arel

This repository contains an Arel Visitor for Sybase ASE, that implements .limit() and .offset() using ROWCOUNT and temporary tables.

## INSTALLATION

* gem install arel-sybase-visitor
* require 'arel/visitors/sybase'

If using bundler:

gem 'arel-sybase-visitor', :git => 'git://github.com/ifad/arel-sybase-visitor', :require => 'arel/visitors/sybase'
