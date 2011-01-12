# Arel Sybase ASE Visitor
#
# Author: Mirek Rusin <mirek@me.com>
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
          return "SET ROWCOUNT #{limit} SELECT * FROM (#{super(o)}) __arel_dp"
        end

        if o.offset
          o        = o.dup
          offset   = o.offset
          o.offset = nil
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

    end

    # Install the visitor
    VISITORS['sybase'] = Sybase
  end
end
