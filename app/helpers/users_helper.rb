# Helper functions for _UsersController_ actions.
#
module UsersHelper
  # Helper function to get a hash with the valid privilege levels of _User_ model.
  #
  # [Returns]
  #   Hash with the level identificators associated to the translations of the privilege levels names.
  #
  def levels_hash
    result = Hash.new

    User::LEVELS.each do |level|
      result[t("users.levels.level_#{level}")] = level
    end

    return result
  end

  # Helper function to get a hash with registered localizations of the app.
  #
  # [Returns]
  #   Hash with the locale identificators associated to the translation of the locales name.
  #
  def languages_hash
    result = Hash.new

    I18n.available_locales.each do |locale|
      result[t("languages.#{locale.to_s}")] = locale.to_s
    end
    
    return result
  end
end
