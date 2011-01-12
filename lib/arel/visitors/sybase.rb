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

        if o.limit && o.offset
          o        = o.dup
          limit    = o.limit.to_i
          offset   = o.offset
          o.limit  = nil
          o.offset = nil

          group, order = group_and_order_for(o)

          sql = super(o)
          return <<-eosql
            SET ROWCOUNT #{offset.value.to_i + limit}

            SELECT
              *,
              __arel_rownum = identity(8)
            INTO
              #__arel_tmp
            FROM
              (#{sql}) AS __arel_select
            #{order}
            #{group}

            SELECT
              *
            FROM
              #__arel_tmp
            WHERE
              __arel_rownum BETWEEN #{offset.value.to_i + 1} AND #{offset.value.to_i + limit}

            DROP TABLE
              #__arel_tmp

            SET ROWCOUNT 0
          eosql
        end

        if o.limit
          o       = o.dup
          limit   = o.limit
          o.limit = nil
          return "SET ROWCOUNT #{limit} #{super(o)}"
        end

        if o.offset
          o        = o.dup
          offset   = o.offset
          o.offset = nil

          group, order = group_and_order_for(o)

          sql = super(o)
          return <<-eosql
            SET ROWCOUNT #{offset.value.to_i + limit}

            SELECT
              *,
              __arel_rownum = identity(8)
            INTO
              #__arel_tmp
            FROM
              (#{sql}) AS __arel_select
            #{order}
            #{group}

            SELECT
              *
            FROM
              #__arel_tmp
            WHERE
              __arel_rownum >= #{offset.value.to_i + 1}

            DROP TABLE
              #__arel_tmp

            SET ROWCOUNT 0
          eosql
        end

        super
      end

      # Extracts group and order clauses from the given Arel::Node and
      # transforms them into raw SQL.
      #
      # o - The Arel::Node
      #
      # Returns an array containing group SQL as the first element and
      # order SQL as the second one. Both can be nil if they're unset.
      def group_and_order_for o
        # Bring orders and groups outside - quite dirty - to clean up
        orders   = o.orders
        o.orders = []
        order = "ORDER BY #{orders.join ','}" unless orders.blank?

        groups   = o.cores.map(&:groups).flatten.map(&:to_sql)
        o.cores.each {|c| c.groups = []}
        group = "GROUP BY #{groups.join ','}" unless groups.blank?

        return [group, order]
      end

    end

    # Install the visitor
    VISITORS['sybase'] = Sybase
  end
end
