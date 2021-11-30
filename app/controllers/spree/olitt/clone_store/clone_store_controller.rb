require_relative 'duplicators/linked_resource_duplicator'
require_relative 'duplicators/menu_items_duplicator'
require_relative 'duplicators/menus_duplicator'
require_relative 'duplicators/pages_duplicator'
require_relative 'duplicators/products_duplicator'
require_relative 'duplicators/sections_duplicator'
require_relative 'duplicators/taxonomies_duplicator'
require_relative 'duplicators/taxons_duplicator'

module Spree
  module Olitt
    module CloneStore
      class CloneStoreController < Spree::Api::V2::BaseController
        include Spree::Olitt::CloneStore::CloneStoreHelpers
        include Spree::Olitt::CloneStore::ProductHelpers
        attr_accessor :old_store, :new_store

        def clone
          return unless handle_clone_store

          return unless  Duplicators::TaxonomiesDuplicator.new(old_store: @old_store,
                                                               new_store: @new_store).handle_clone_taxonomies
          return unless  Duplicators::TaxonsDuplicator.new(old_store: @old_store,
                                                           new_store: @new_store).handle_clone_taxons
          return unless Duplicators::MenusDuplicator.new(old_store: @old_store,
                                                         new_store: @new_store).handle_clone_menus
          return unless Duplicators::MenuItemsDuplicator.new(old_store: @old_store,
                                                             new_store: @new_store).handle_clone_menu_items
          # return unless Duplicators::PagesDuplicator.new(old_store: @old_store,
          #                                                new_store: @new_store).handle_clone_pages
          # return unless Duplicators::SectionsDuplicator.new(old_store: @old_store,
          #                                                   new_store: @new_store).handle_clone_sections
          # return unless Duplicators::ProductsDuplicator.new(old_store: @old_store,
          #                                                   new_store: @new_store).handle_clone_products

          finish
        end

        def test
          ActiveRecord::Base.transaction do
            handle_clone_store
            taxonomies_duplicator = Duplicators::TaxonomiesDuplicator.new(old_store: @old_store,
                                                                          new_store: @new_store)
            taxonomies_duplicator.handle_clone_taxonomies
            taxon_duplicator = Duplicators::TaxonsDuplicator.new(old_store: @old_store,
                                                                 new_store: @new_store)
            taxon_duplicator.handle_clone_taxons

            menus_duplicator = Duplicators::MenusDuplicator.new(old_store: @old_store,
                                                                new_store: @new_store)
            menus_duplicator.handle_clone_menus

            render json: @new_store.menus
            # Duplicators::MenuItemsDuplicator.new(old_store: @old_store,
            #                                      new_store: @new_store).handle_clone_menu_items
            # Duplicators::PagesDuplicator.new(old_store: @old_store,
            #                                  new_store: @new_store).handle_clone_pages
            # Duplicators::SectionsDuplicator.new(old_store: @old_store,
            #                                     new_store: @new_store).handle_clone_sections
            # product_duplicator = Duplicators::ProductsDuplicator.new(old_store: @old_store,
            #                                                          new_store: @new_store)
            # render json: product_duplicator.errors unless product_duplicator.handle_clone_products

            raise ActiveRecord::Rollback
          end
        end

        # Store
        def handle_clone_store
          @old_store = Spree::Store
                       .includes(:taxonomies, :menus, :menu_items, :cms_pages, :cms_sections,
                                 taxons: [:taxonomy], products: %i[variants taxons product_properties master])
                       .find_by(id: source_id_param)
          raise ActiveRecord::RecordNotFound if @old_store.nil?

          store = clone_and_update_store @old_store.dup
          unless store.save
            render_error_payload(store.errors)
            return false
          end

          @new_store = store
          true
        end

        def clone_and_update_store(store)
          name, url, code, mail_from_address = required_store_params

          store.name = name
          store.url = url
          store.code = code
          store.mail_from_address = mail_from_address
          store.default = false
          store
        end

        

        # Finish Lifecycle

        def finish
          render_serialized_payload(201) { serialize_resource(@new_store) }
        end
      end
    end
  end
end
