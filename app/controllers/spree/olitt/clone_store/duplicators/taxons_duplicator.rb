module Spree
  module Olitt
    module CloneStore
      module Duplicators
        class TaxonsDuplicator < BaseDuplicator
          def initialize(old_store:, new_store:, taxonomies_cache:, root_taxons:)
            super()
            @old_store = old_store
            @new_store = new_store

            @new_taxons_cache = root_taxons
            @new_taxonomies_by_name = taxonomies_cache

            @old_taxons_by_parent = @old_store.taxons.includes(%i[taxonomy parent]).group_by(&:parent_id)
          end

          def handle_clone_taxons
            clone_child_taxons(parent_taxon_id: nil)
          end

          def clone_child_taxons(parent_taxon_id:)
            return unless @old_taxons_by_parent.key?(parent_taxon_id)

            old_child_taxons = get_old_child_taxons(parent_taxon_id: parent_taxon_id)

            return old_child_taxons.each { |child_taxon| clone_child_taxons(parent_taxon_id: child_taxon.id) } if parent_taxon_id.nil?

            save_new_taxons(old_child_taxons: old_child_taxons)

            return if errors_are_present?

            old_child_taxons.each { |child_taxon| clone_child_taxons(parent_taxon_id: child_taxon.id) }
          end

          def save_new_taxons(old_child_taxons:)
            old_child_taxons.each do |old_taxon|
              new_taxon = old_taxon.dup
              new_taxon.taxonomy = get_new_taxonomy(old_taxon: old_taxon)
              new_taxon.parent = get_new_parent_taxon(old_taxon: old_taxon)
              attributes = new_taxon.attributes
              attributes = attributes.except('lft', 'rgt', 'depth')
              new_taxon = Spree::Taxon.new attributes
              save_model(model: new_taxon)
              break if errors_are_present?

              @new_taxons_cache[new_taxon.permalink] = [new_taxon]
            end
          end

          def get_old_child_taxons(parent_taxon_id:)
            @old_taxons_by_parent[parent_taxon_id]
          end

          def get_new_taxonomy(old_taxon:)
            @new_taxonomies_by_name[old_taxon.taxonomy.name].first
          end

          def get_new_parent_taxon(old_taxon:)
            @new_taxons_cache[old_taxon.parent.permalink].first
          end
        end
      end
    end
  end
end
