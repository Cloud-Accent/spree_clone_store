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

          taxonomies_duplicator = Duplicators::TaxonomiesDuplicator.new(old_store: @old_store,
                                                                        new_store: @new_store)
          taxonomies_duplicator.handle_clone_taxonomies

          return render_error(duplicator: taxonomies_duplicator) if taxonomies_duplicator.errors_are_present?

          taxon_duplicator = Duplicators::TaxonsDuplicator.new(old_store: @old_store,
                                                               new_store: @new_store,
                                                               taxonomies_cache: taxonomies_duplicator.taxonomies_cache,
                                                               root_taxons: taxonomies_duplicator.root_taxons)
          taxon_duplicator.handle_clone_taxons

          return render_error(duplicator: taxon_duplicator) if taxon_duplicator.errors_are_present?

          menus_duplicator = Duplicators::MenusDuplicator.new(old_store: @old_store,
                                                              new_store: @new_store)
          menus_duplicator.handle_clone_menus

          return render_error(duplicator: menus_duplicator) if menus_duplicator.errors_are_present?

          menu_items_duplicator = Duplicators::MenuItemsDuplicator.new(old_store: @old_store,
                                                                       new_store: @new_store,
                                                                       new_menus_cache: menus_duplicator.menus_cache,
                                                                       root_menu_items: menus_duplicator.root_menu_items)
          menu_items_duplicator.handle_clone_menu_items

          return render_error(duplicator: menu_items_duplicator) if menu_items_duplicator.errors_are_present?

          page_duplicator = Duplicators::PagesDuplicator.new(old_store: @old_store,
                                                             new_store: @new_store)
          page_duplicator.handle_clone_pages

          return render_error(duplicator: page_duplicator) if page_duplicator.errors_are_present?

          # return unless Duplicators::SectionsDuplicator.new(old_store: @old_store,
          #                                                   new_store: @new_store).handle_clone_sections
          # return unless Duplicators::ProductsDuplicator.new(old_store: @old_store,
          #                                                   new_store: @new_store).handle_clone_products

          finish
        end

        def test
          ActiveRecord::Base.transaction do
            handle_clone_store
            # taxonomies_duplicator = Duplicators::TaxonomiesDuplicator.new(old_store: @old_store,
            #                                                               new_store: @new_store)
            # taxonomies_duplicator.handle_clone_taxonomies

            # return render_error(duplicator: taxonomies_duplicator) if taxonomies_duplicator.errors_are_present?

            # taxon_duplicator = Duplicators::TaxonsDuplicator.new(old_store: @old_store,
            #                                                      new_store: @new_store,
            #                                                      taxonomies_cache: taxonomies_duplicator.taxonomies_cache,
            #                                                      root_taxons: taxonomies_duplicator.root_taxons)
            # taxon_duplicator.handle_clone_taxons

            # return render_error(duplicator: taxon_duplicator) if taxon_duplicator.errors_are_present?

            # menus_duplicator = Duplicators::MenusDuplicator.new(old_store: @old_store,
            #                                                     new_store: @new_store)
            # menus_duplicator.handle_clone_menus

            # return render_error(duplicator: menus_duplicator) if menus_duplicator.errors_are_present?

            # menu_items_duplicator = Duplicators::MenuItemsDuplicator.new(old_store: @old_store,
            #                                                              new_store: @new_store,
            #                                                              new_menus_cache: menus_duplicator.menus_cache,
            #                                                              root_menu_items: menus_duplicator.root_menu_items)
            # menu_items_duplicator.handle_clone_menu_items

            # return render_error(duplicator: menu_items_duplicator) if menu_items_duplicator.errors_are_present?

            page_duplicator = Duplicators::PagesDuplicator.new(old_store: @old_store,
                                                               new_store: @new_store)
            page_duplicator.handle_clone_pages

            return render_error(duplicator: page_duplicator) if page_duplicator.errors_are_present?

            render json: @new_store.cms_pages

            section_duplicator = Duplicators::SectionsDuplicator.new(old_store: @old_store,
                                                                     new_store: @new_store)
            section_duplicator.handle_clone_sections

            return render_error(duplicator: section_duplicator) if section_duplicator.errors_are_present?

            # product_duplicator = Duplicators::ProductsDuplicator.new(old_store: @old_store,
            #                                                          new_store: @new_store)
            # render json: product_duplicator.errors unless product_duplicator.handle_clone_products

            raise ActiveRecord::Rollback
          end
        end

        def render_error(duplicator:)
          render json: duplicator.errors
        end

        # Store
        def handle_clone_store
          @old_store = Spree::Store.find_by(id: source_id_param)
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
