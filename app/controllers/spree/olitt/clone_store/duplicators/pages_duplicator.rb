module Spree
  module Olitt
    module CloneStore
      module Duplicators
        class PagesDuplicator < BaseDuplicator
          attr_reader :pages_cache

          def initialize(old_store:, new_store:)
            super()
            @old_store = old_store
            @new_store = new_store

            @pages_cache = {}
          end

          def handle_clone_pages
            pages = @old_store.cms_pages
            pages.each do |old_page|
              new_page = old_page.dup
              new_page.store = @new_store
              save_model(model: new_page)
              break if errors_are_present?

              @pages_cache[new_page.slug] = [new_page]
            end
          end
        end
      end
    end
  end
end
