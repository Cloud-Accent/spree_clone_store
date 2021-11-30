module Spree
  module Olitt
    module CloneStore
      module Duplicators
        class MenuItemsDuplicator < BaseDuplicator
          def initialize(old_store:, new_store:, new_menus_cache:, root_menu_items:)
            super()
            @old_store = old_store
            @new_store = new_store

            @new_menus_by_location_locale = new_menus_cache
            @old_to_new_menu_item_map = root_menu_items

            @old_menu_items_by_parent = @old_store.menu_items.group_by(&:parent)

            @linked_resource = LinkedResourceDuplicator.new(old_store: @old_store, new_store: @new_store)
          end

          def handle_clone_menu_items
            clone_child_menu_item(parent_menu_item: nil)
          end

          def clone_child_menu_item(parent_menu_item:)
            return if are_errors_present?

            return unless @old_menu_items_by_parent.key?(parent_menu_item)

            old_child_menu_items = get_old_menu_items(parent: parent_menu_item)

            return loop_back(old_child_menu_items: old_child_menu_items) if parent_menu_item.nil?

            new_child_menu_items = reassign_menu_items_properies(old_child_menu_items: old_child_menu_items)

            save_models(models: new_child_menu_items)

            loop_back(old_child_menu_items: old_child_menu_items)
          end

          def loop_back(old_child_menu_items:)
            old_child_menu_items.each { |menu_item| clone_child_menu_item(parent_menu_item: menu_item) }
          end

          def reassign_menu_items_properies(old_child_menu_items:)
            old_child_menu_items.map do |old_menu_item|
              new_menu_item = old_menu_item.dup
              @old_to_new_menu_item_map[old_menu_item] = new_menu_item

              new_menu_item.parent = get_new_parent(old_menu_item: old_menu_item)
              new_menu_item.menu = get_new_menu(old_menu: old_menu_item.menu)

              new_menu_item
            end
          end

          def get_new_parent(old_menu_item:)
            old_parent = old_menu_item.parent
            new_parent = @old_to_new_menu_item_map[old_parent]
            return new_parent unless new_parent.nil?

            @errors << 'parent is undefined'
          end

          def get_new_menu(old_menu:)
            @new_menus_by_location_locale[old_menu.location][old_menu.locale].first
          end

          def get_old_menu_items(parent:)
            @old_menu_items_by_parent[parent]
          end
        end
      end
    end
  end
end
