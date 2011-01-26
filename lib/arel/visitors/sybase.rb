# Arel Sybase ASE 15.0 Visitor
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
          return cursor_query_for(super(o), limit, offset)
        end

        # LIMIT-only case
        if limit > 0
          return <<-eosql
            SET ROWCOUNT #{limit}
            #{super(o)}
            SET ROWCOUNT 0
          eosql
        end

        # OFFSET-only case
        if offset > 0
          return cursor_query_for(super(o), 5000, offset)
        end

        super
      end

      private
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

    # Install the visitor
    VISITORS['sybase'] = Sybase
  end
end
