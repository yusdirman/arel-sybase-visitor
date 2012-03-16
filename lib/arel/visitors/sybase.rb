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

        # On ASE 12.5 the empty string has a puzzling behaviour:
        #
        # http://infocenter.sybase.com/help/index.jsp?topic=/com.sybase.help.ase_15.0.blocks/html/blocks/blocks262.htm
        #
        # Meaning that "" becomes " " on INSERT, and assigments:
        #
        # 1> select '"' || '' || '"'
        # 2> go
        #
        # ---
        #   " "
        #
        # Because ' ' is NOT an empty string, and it creeps up
        # till to the ERB views, it requires that WHERE clauses
        # take care of it, etc - we replace it with a NULL here
        #
        # OK, '' is different than a NULL, but it seems that on
        # Sybase this is not the case. For instance:
        #
        # 1> select ltrim('')
        # 2> go
        #
        # -
        #   NULL
        #
        # Anyway, tables created with Rails migrations set columns
        # nullable by default so this should not be an issue as
        # long as you don't update legacy tables used by legacy
        # software that actually expects " " to represent the empty
        # string ...
        def visit_Arel_Nodes_UpdateStatement(o)
          o.values.each do |assignment|
            assignment.right = null_if_empty_string(assignment.right)
          end
          super
        end

        # See +visit_Arel_Nodes_UpdateStatement+ documentation
        def visit_Arel_Nodes_InsertStatement(o)
          o.values.expressions.map! &method(:null_if_empty_string)
          super
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

        # Returns value unless it is a string and it is empty,
        # in that case nil is returned.
        def null_if_empty_string(value)
          value unless value.is_a?(String) && value.length.zero?
        end

    end

    # Install the visitor - only for AR <= 3.0
    VISITORS['sybase'] = Sybase if defined?(VISITORS)
  end
end
