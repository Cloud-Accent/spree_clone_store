module Spree
  module Olitt
    module CloneStore
      module Duplicators
        class MenuItemsDuplicator
          include Spree::Olitt::CloneStore::CloneStoreHelpers

          def initialize(old_store:, new_store:)
            @old_store = old_store
            @new_store = Spree::Store.includes(:menus).find_by(id: new_store.id)
            @linked_resource = LinkedResourceDuplicator.new(old_store: @old_store, new_store: @new_store)
          end

          def handle_clone_menu_items
            old_root_menu_items = @old_store.menu_items.where(parent: nil).order(depth: :asc).order(id: :asc)
            save_root_menu_items =  @new_store.menu_items.build(get_model_hash(old_root_menu_items))
            return false unless save_models(save_root_menu_items)
            
            # old_root_menu_items.each do |root_menu_item|
            #   return false unless clone_menu_item(parent_menu_item: root_menu_item,
            #                                       terminate: false)
            # end
            true
          end

          # def clone_menu_item(parent_menu_item:, terminate: false)
          #   return false if terminate

          #   old_menu_items = @old_store.menu_items.where(parent: parent_menu_item, menu: parent_menu_item.menu)
          #                              .order(depth: :asc).order(id: :asc)
          #   return false if old_menu_items.nil?

          #   cloned_menu_items = clone_menu_item_helper(old_menu_items: old_menu_items, parent_menu_item: parent_menu_item)

          #   terminate = true unless save_models(cloned_menu_items)

          #   # old_menu_items.each { |menu_item| return false unless clone_menu_item(parent_menu_item: menu_item, terminate: terminate) }
          #   true
          # end

          # def clone_menu_item_helper(old_menu_items:, parent_menu_item:)
          #   new_menu = @new_store.menus.find_by(location: parent_menu_item.menu.location, locale: parent_menu_item.menu.locale)
          #   new_parent_menu_item = get_new_parent_menu_item(new_menu: new_menu, old_parent_menu_item: parent_menu_item)

          #   clone_update_menu_item(old_menu_items: old_menu_items,
          #                          new_menu: new_menu, new_parent_menu_item: new_parent_menu_item)
          # end

          # def clone_update_menu_item(old_menu_items:, new_menu:, new_parent_menu_item:)
          #   menu_items = old_menu_items.map do |menu_item|
          #     new_menu_item = menu_item.dup
          #     new_menu_item.parent = new_parent_menu_item
          #     new_menu_item
          #   end
          #   attributes_for_each_taxon = get_model_hash(menu_items).map do |attributes|
          #     attributes.except('lft', 'rgt', 'depth')
          #   end
          #   new_menu.menu_items.build(attributes_for_each_taxon)
          # end

          # def get_new_parent_menu_item(new_menu:, old_parent_menu_item:)
          #   old_grandparent_menu_item = old_parent_menu_item.parent
          #   new_grandparent_menu_item = nil
          #   unless old_grandparent_menu_item.nil?
          #     new_grandparent_menu_item = @new_store.menu_items.joins(:menu).find_by(menu: new_menu,
          #                                                                            name: old_grandparent_menu_item.name)

          #   end

          #   @new_store.menu_items.joins(:menu).find_by(menu: new_menu, name: old_parent_menu_item.name, parent: new_grandparent_menu_item)
          # end

          # def get_new_menu_item_linked_resource(resource_type:, resource_id:)
          #   resource = resource_type.constantize
          #   old_linked_resource = resource.find_by(id: resource_id)

          #   if old_linked_resource.instance_of?('Spree::Taxon'.constantize)
          #     return @linked_resource.get_new_linked_taxon(old_taxon: old_linked_resource)
          #   end

          #   if old_linked_resource.instance_of?('Spree::Product'.constantize)
          #     return @linked_resource.get_new_linked_product(old_product: old_linked_resource)
          #   end

          #   if old_linked_resource.instance_of?('Spree::CmsPage'.constantize)
          #     return @linked_resource.get_new_linked_page(old_page: old_linked_resource)
          #   end

          #   nil
          # end
        end
      end
    end
  end
end
