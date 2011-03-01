# Arel Sybase ASE 15.0 Visitor -- implementing
# LIMIT and OFFSET using cursors and replacing
# the empty string with NULL in the INSERT and
# UPDATE statements.
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
            cursor_query_for(super(o), limit, offset)
          elsif limit > 0
            # LIMIT-only case
            %[ SET ROWCOUNT #{limit} #{super(o)} SET ROWCOUNT 0 ]
          elsif offset > 0
            # OFFSET-only case
            cursor_query_for(super(o), 5000, offset)
          else
            super
          end
        end

        # Danger Will Robinson! This SQL code only
        # works with the patched AR Sybase Adapter
        # on the http://github.com/ifad repository
        def cursor_query_for(sql, limit, offset)
          cursor = "__arel_cursor_#{rand(0xffff)}"

          return <<-eosql
            DECLARE #{cursor} SCROLL CURSOR FOR #{sql} FOR READ ONLY
            SET CURSOR ROWS #{limit} FOR #{cursor}
            OPEN #{cursor}
            FETCH ABSOLUTE #{offset+1} #{cursor}
            CLOSE #{cursor}
            DEALLOCATE #{cursor}
          eosql
        end

        # On ASE 15.0 the empty string has a puzzling behaviour:
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

        # Returns value unless it is a string and it is empty,
        # in that case nil is returned.
        def null_if_empty_string(value)
          value unless value.is_a?(String) && value.length.zero?
        end

    end

    # Install the visitor
    VISITORS['sybase'] = Sybase
  end
end
