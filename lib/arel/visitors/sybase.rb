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

        def visit_Arel_Nodes_SelectStatement(o, a)
          limit, offset = o.limit.try(:expr) || 0, o.offset.try(:expr) || 0

          # Alter the node if a limit or offset are set
          if limit > 0 || offset > 0
            o        = o.dup
            o.limit  = nil
            o.offset = nil
          end

          if limit > 0 && offset > 0
            # LIMIT, OFFSET
            cursor_query_for(super(o, a), limit, offset)
          elsif limit > 0
            # LIMIT-only case
            %[ SET ROWCOUNT #{limit} #{super(o, a)} SET ROWCOUNT 0 ]
          elsif offset > 0
            # OFFSET-only case
            cursor_query_for(super(o, a), 5000, offset)
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

    end

    # Install the visitor - only for AR <= 3.0
    VISITORS['sybase'] = Sybase if defined?(VISITORS)
  end
end
