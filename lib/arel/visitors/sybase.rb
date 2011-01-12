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

          order = extract_order_from(o)

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

          order = extract_order_from(o)

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

      # Extracts the eventual order clause from the given Arel::Node and
      # transforms them into raw SQL.
      #
      # o - The Arel::Node
      #
      # Returns the raw ORDER BY SQL, or nil if there were no ORDER clause.
      #
      # TODO cleanup
      def extract_order_from o
        orders   = o.orders
        o.orders = []
        "ORDER BY #{orders.join ','}" unless orders.blank?
      end

    end

    # Install the visitor
    VISITORS['sybase'] = Sybase
  end
end
