# Arel Sybase ASE 12.5 Visitor
#
# Authors:
#
# Mirek Rusin      <mirek@me.com>
# Marcello Barnaba <vjt@openssl.it>
#
module Arel
  module Visitors
    class Sybase < Arel::Visitors::ToSql
      private

      def visit_Arel_Nodes_SelectStatement o
        limit, offset = o.limit.try(:expr) || 0, o.offset.try(:expr) || 0

        # Alter the node if a limit or offset are set
        if limit > 0 || offset > 0
          o        = o.dup
          o.limit  = nil
          o.offset = nil
        end

        # LIMIT, OFFSET
        if limit > 0 && offset > 0
          return temp_table_query_for(super(o), limit, offset)
        end

        # LIMIT-only case
        if limit > 0
          return set_rowcount_for(super(o), limit)
        end

        # OFFSET-only case. Please note that at most 5000 rows
        # are fetched, that should be enough for everyone (tm)
        if offset > 0
          return temp_table_query_for(super(o), 5000, offset)
        end

        super
      end

      require 'ruby-debug'
      private
        # I know, it's dirty, ARel shouldn't be used
        # like that, yada yada - but ARel doesn't
        # support SELECT INTO thus a RegExp must be
        # used anyway.
        def temp_table_query_for(sql, limit, offset)
          #debugger
          tmp = "#__arel_tmp_#{rand(0xffff)}"

          sql.sub! /\bFROM\b/, ", __arel_rowid = identity(8) INTO #{tmp} \\&"
          sql.concat %(
            SELECT * FROM #{tmp} WHERE __arel_rowid > #{offset}
            DROP TABLE #{tmp}
          )

          return set_rowcount_for(sql, limit + offset)
        end

        def set_rowcount_for(sql, count)
          "SET ROWCOUNT #{count} #{sql} SET ROWCOUNT 0"
        end

    end

    # Install the visitor
    VISITORS['sybase'] = Sybase
  end
end
