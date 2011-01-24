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
        def cursor_query_for(sql, limit, offset)
          cursor = cursor_for(sql)

          return <<-eosql
            SET CURSOR ROWS #{limit} FOR #{cursor}
            OPEN #{cursor}
            FETCH ABSOLUTE #{offset} #{cursor}
            CLOSE #{cursor}
          eosql
        end

        def cursor_for(sql)
          cursor = "__arel_cursor_#{Zlib.crc32(sql).to_s(16)}"
          Cursors[sql] ||= cursor.tap do |name|
            @engine.connection.execute("DECLARE #{cursor} SCROLL CURSOR FOR #{sql} FOR READ ONLY")
          end
        end

        Cursors = {}

    end

    # Install the visitor
    VISITORS['sybase'] = Sybase
  end
end
