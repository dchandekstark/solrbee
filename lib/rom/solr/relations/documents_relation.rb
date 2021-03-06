require 'rom/solr/documents_paginator'
require 'rom/solr/query_builder'

module ROM
  module Solr
    class DocumentsRelation < Relation

      def_delegators :dataset, :num_found, :num_found_exact?

      schema(:documents) do
        # no-op
      end

      # @override
      def each(&block)
        return super unless cursor?

        return to_enum unless block_given?

        DocumentsPaginator.new(dataset).each(&block)
      end

      # @override FIXME: Get from Solr schema unique key
      def primary_key
        :id
      end

      def by_unique_key(id)
        q('%s:%s' % [ primary_key, id ])
      end

      def all
        q('*:*')
      end

      # @override
      def count
        num_found_exact? ? num_found : super
      end

      # Set a cursor on the relation for pagination
      def cursor
        relation = add_params(cursorMark: '*')

        # Sort must include a sort on unique key (id).
        if /\bid\b/ =~ params[:sort]
          relation
        else
          relation.sort(params[:sort], 'id ASC')
        end
      end

      def cursor?
        params.key?(:cursorMark)
      end

      def query(&block)
        queries = QueryBuilder.call(&block)

        q(*queries)
      end

      def filter(&block)
        queries = QueryBuilder.call(&block)

        fq(*queries)
      end

      #
      # Commands
      #

      def insert(docs, **opts)
        # FIXME: use input schema?
        data = Array.wrap(docs).map do |doc|
          doc.transform_keys!(&:to_sym)
          doc[:id] ||= UUID[]
          doc
        end

        update_json_docs(
          data,
          opts.slice(:commit, :commit_within, :wait_searcher)
        )
      end

      def update(docs, **opts)
        # FIXME: use input schema?
        data = Array.wrap(docs)
                 .map    { |doc| doc.transform_keys(&:to_sym) }
                 .select { |doc| doc.key?(:id) }

        update_json_docs(
          data,
          opts.slice(:commit, :commit_within, :overwrite, :wait_searcher)
        )
      end

      def delete(docs, **opts)
        # FIXME: use input schema?
        ids = Array.wrap(docs)
                .map { |doc| doc.transform_keys(&:to_sym) }
                .map { |doc| doc.fetch(:id) }

        json_update_command(
          { delete: ids },
          opts.slice(:commit, :commit_within, :wait_searcher, :expunge_deletes)
        )
      end

      def delete_by_query(query)
        json_update_command(delete: {query: query})
      end

      #
      # Common Query Parameters
      #

      # Main Solr query param
      def q(*queries)
        new_queries = Array.wrap(queries).flatten

        add_params q: new_queries.join(' ')
      end

      def fq(*queries)
        old_queries = Array.wrap(params[:fq])
        new_queries = Array.wrap(queries).flatten

        add_params fq: old_queries + new_queries
      end

      def fl(*fields)
        new_fields = Types::Array.of(Types::Coercible::String)[fields]

        add_params fl: new_fields.join(',')
      end

      alias_method :fields, :fl

      def cache(enabled = true)
        add_params cache: Types::Bool[enabled]
      end

      def segment_terminate_early(enabled = true)
        add_params segmentTerminateEarly: Types::Bool[enabled]
      end

      def time_allowed(millis)
        add_params timeAllowed: Types::Coercible::Integer[millis]
      end

      def explain_other(query)
        add_params explainOther: Types::String[query]
      end

      def start(offset)
        add_params start: Types::Coercible::Integer[offset]
      end

      def sort(*criteria)
        new_sort = Types::Array.of(Types::String)[criteria]

        add_params sort: new_sort.join(',')
      end

      def rows(num)
        add_params rows: Types::Coercible::Integer[num]
      end

      alias_method :limit, :rows

      def def_type(value)
        add_params defType: Types::Coercible::String[value]
      end

      def debug(setting)
        add_params debug: Types::Coercible::String.enum('query', 'timing', 'results', 'all', 'true')[setting]
      end

      def echo_params(setting)
        add_params echoParams: Types::Coercible::String.enum('explicit', 'all', 'none')[setting]
      end

      def min_exact_count(num)
        add_params minExactCount: Types::Coercible::Integer[num]
      end

      #
      # Commit parameters
      #
      def commit(value = true)
        add_params commit: Types::Bool[value]
      end

      def commit_within(millis)
        add_params commitWithin: Types::Coercible::Integer.optional[millis]
      end

      def overwrite(value = true)
        add_params overwrite: Types::Bool[value]
      end

      def expunge_deletes(value = true)
        add_params expungeDeletes: Types::Bool[value]
      end

      def wait_searcher(value = true)
        add_params waitSearcher: Types::Bool[value]
      end

      private

      def json_update_command(data, **opts)
        __update__('update', data, **opts)
      end

      def update_json_docs(data, **opts)
        __update__('update/json/docs', data, **opts)
      end

      def __update__(base_path, data, **opts)
        opts
          .reduce(self) { |memo, (key, value)| memo.send(key, value) }
          .with_options(
            base_path: base_path,
            content_type: 'application/json',
            request_method: :post,
            request_data: JSON.dump(data)
          )
      end

    end
  end
end
