module Spree
  module Olitt
    module CloneStore
      module Duplicators
        class TaxonomiesDuplicator < BaseDuplicator
          attr_reader :root_taxons, :taxonomies_cache

          def initialize(old_store:, new_store:)
            super()
            @old_store = old_store
            @new_store = new_store
            @root_taxons = {}
            @taxonomies_cache = {}
          end

          def handle_clone_taxonomies
            taxonomies = @old_store.taxonomies
            taxonomies.each do |old_taxonomy|
              new_taxonomy = old_taxonomy.dup
              new_taxonomy.store = @new_store
              save_model(model: new_taxonomy)
              break if errors_are_present?

              @root_taxons[new_taxonomy.root.permalink] = [new_taxonomy.root]
              cache_taxonomies(new_taxonomy: new_taxonomy)
            end
          end

          def cache_taxonomies(new_taxonomy:)
            @taxonomies_cache[new_taxonomy.name] = [new_taxonomy]
          end
        end
      end
    end
  end
end
