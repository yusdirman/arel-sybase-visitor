# Arel Sybase ASE 12.5 Visitor - implementing
# LIMIT and OFFSET using temporary tables and
# replacing the empty string with NULL on the
# INSERT and UPDATE statements.
#
# Authors:
#
# Mirek Rusin      <mirek@me.com>
# Marcello Barnaba <vjt@openssl.it>
#
# Released under the terms of the Ruby License
#
module Arel
  module Visitors
    class Sybase < Arel::Visitors::ToSql
      private

        # Implements LIMIT and OFFSET using temporary tables.
        def visit_Arel_Nodes_SelectStatement(o)
          limit, offset = o.limit.try(:expr) || 0, o.offset.try(:expr) || 0

          # Alter the node if a limit or offset are set
          if limit > 0 || offset > 0
            o        = o.dup
            o.limit  = nil
            o.offset = nil
          end

          if limit > 0 && offset > 0
            # LIMIT, OFFSET
            temp_table_query_for(super(o), limit, offset)
          elsif limit > 0
            # LIMIT-only case
            set_rowcount_for(super(o), limit)
          elsif offset > 0
            # OFFSET-only case. Please note that at most 5000 rows
            # are fetched, that should be enough for everyone (tm)
            temp_table_query_for(super(o), 5000, offset)
          else
            super
          end
        end

        ########## Our private API

        # I know, it's dirty, ARel shouldn't be used
        # like that, yada yada - but ARel doesn't
        # support SELECT INTO thus a RegExp must be
        # used anyway.
        def temp_table_query_for(sql, limit, offset)
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

    # Install the visitor - only for AR <= 3.0
    VISITORS['sybase'] = Sybase if defined?(VISITORS)
  end
end
