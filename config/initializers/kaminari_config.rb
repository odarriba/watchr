Kaminari.configure do |config|
  config.default_per_page = 20
  # config.max_per_page = nil
  # config.window = 4
  # config.outer_window = 0
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
end

# :nodoc: all
# This is a hack to allow i18n in Kaminari model names
#
module Kaminari 
  module ActionViewExtension
    def page_entries_info(collection, options = {})
      entry_name = options[:entry_name] || collection.model_name
      entry_name = entry_name.human(count: collection.total_count)

      if collection.total_pages < 2
        t('helpers.page_entries_info.one_page.display_entries', :entry_name => entry_name, :count => collection.total_count)
      else
        first = collection.offset_value + 1
        last = collection.last_page? ? collection.total_count : collection.offset_value + collection.limit_value
        t('helpers.page_entries_info.more_pages.display_entries', :entry_name => entry_name, :first => first, :last => last, :total => collection.total_count)
      end.html_safe
    end
  end
end