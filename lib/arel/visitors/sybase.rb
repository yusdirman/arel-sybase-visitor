# Arel Sybase ASE Visitor
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

        # LIMIT, OFFSET
        if o.limit && o.offset
          o        = o.dup
          limit    = o.limit.expr
          offset   = o.offset.expr + 1
          o.limit  = nil
          o.offset = nil

          return cursor_query_for(super(o), limit, offset)
        end

        # LIMIT-only case
        if o.limit
          o       = o.dup
          limit   = o.limit.expr
          o.limit = nil
          return <<-eosql
            SET ROWCOUNT #{limit}
            #{super(o)}
            SET ROWCOUNT 0
          eosql
        end

        # OFFSET-only case
        if o.offset
          o        = o.dup
          offset   = o.offset.expr + 1
          o.offset = nil

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
            FETCH ABSOLUTE #{offset} #{cursor}
            CLOSE #{cursor}
            DEALLOCATE #{cursor}
          eosql
        end

    end

    # Install the visitor
    VISITORS['sybase'] = Sybase
  end
end
