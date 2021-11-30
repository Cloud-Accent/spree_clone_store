module Spree
  module Olitt
    module CloneStore
      module Duplicators
        class MenusDuplicator < BaseDuplicator
          attr_reader :root_menu_items, :menus_cache

          def initialize(old_store:, new_store:)
            super()
            @old_store = old_store
            @new_store = new_store
            @menus_cache = {}
            @root_menu_items = {}
          end

          def handle_clone_menus
            menus = @old_store.menus.includes([:root])
            menus.map do |menu|
              new_menu = menu.dup
              new_menu.store = @new_store
              save_model(model: new_menu)
              @root_menu_items[menu.root] = new_menu.root
              cache_menu(new_menu: new_menu)
            end
          end

          def cache_menu(new_menu:)
            @menus_cache[new_menu.location] = {} unless @menus_cache.key?(new_menu.location)
            @menus_cache[new_menu.location][new_menu.locale] = [new_menu]
          end
        end
      end
    end
  end
end
