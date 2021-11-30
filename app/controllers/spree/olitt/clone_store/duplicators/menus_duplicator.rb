module Spree
  module Olitt
    module CloneStore
      module Duplicators
        class MenusDuplicator
          include Spree::Olitt::CloneStore::CloneStoreHelpers

          def initialize(old_store:, new_store:)
            @old_store = old_store
            @new_store = new_store
          end

          def handle_clone_menus
            menus = @old_store.menus.all
            cloned_menus = @new_store.menus.build(get_model_hash(menus))
            return false unless save_models(cloned_menus)

            true
          end
        end
      end
    end
  end
end
