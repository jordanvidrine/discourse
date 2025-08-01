# frozen_string_literal: true

require "base64"

class ThemeSerializer < BasicThemeSerializer
  attributes :color_scheme_id,
             :user_selectable,
             :auto_update,
             :remote_theme_id,
             :settings,
             :themeable_site_settings,
             :errors,
             :supported?,
             :enabled?,
             :disabled_at,
             :theme_fields,
             :screenshot_url,
             :system

  has_one :color_scheme, serializer: ColorSchemeSerializer, embed: :object
  has_one :owned_color_palette, serializer: ColorSchemeSerializer, embed: :object
  has_one :base_palette, serializer: ColorSchemeSerializer, embed: :object
  has_one :user, serializer: UserNameSerializer, embed: :object
  has_one :disabled_by, serializer: UserNameSerializer, embed: :object

  has_many :child_themes, serializer: BasicThemeSerializer, embed: :objects
  has_many :parent_themes, serializer: BasicThemeSerializer, embed: :objects
  has_one :remote_theme, serializer: RemoteThemeSerializer, embed: :objects
  has_many :translations, serializer: ThemeTranslationSerializer, embed: :objects

  def initialize(theme, options = {})
    super
    @include_theme_field_values = options[:include_theme_field_values] || false
    @errors = []

    object.theme_fields.each { |o| @errors << o.error if o.error }
  end

  def theme_fields
    ActiveModel::ArraySerializer.new(
      object.theme_fields,
      each_serializer: ThemeFieldSerializer,
      include_value: include_theme_field_values?,
    ).as_json
  end

  def include_theme_field_values?
    # This is passed into each `ThemeFieldSerializer` to determine if `value` will be serialized.
    # We only want to serialize if we are viewing staff_action_logs (for diffing changes), or if
    # the theme is a local theme, so the saved values appear in the theme field editor.
    @include_theme_field_values || object.remote_theme_id.nil?
  end

  def child_themes
    object.child_themes
  end

  def parent_themes
    object.parent_themes
  end

  def base_palette
    ColorScheme.base
  end

  def include_base_palette?
    object.color_scheme_id.blank? && object.owned_color_palette.blank?
  end

  def settings
    object.settings.map do |_name, setting|
      ThemeSettingsSerializer.new(setting, scope:, root: false)
    end
  rescue ThemeSettingsParser::InvalidYaml => e
    @errors << e.message
    nil
  end

  # Components always return an empty array here
  def themeable_site_settings
    object.themeable_site_settings
  end

  def include_themeable_site_settings?
    !object.component?
  end

  def include_child_themes?
    !object.component?
  end

  def errors
    @errors
  end

  def include_errors?
    @errors.present?
  end

  def include_disabled_at?
    object.component? && !object.enabled?
  end

  def include_disabled_by?
    include_disabled_at?
  end

  def system
    object.system?
  end
end
