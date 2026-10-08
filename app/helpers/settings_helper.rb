module SettingsHelper
  # Grouped options with IANA identifiers as values. Zones that share an identifier
  # (e.g. Edinburgh and London) become one option; US zones are listed first.
  def time_zone_options(selected)
    options = ActiveSupport::TimeZone.all.group_by { it.tzinfo.name }.map do |id, zones|
      [ "(GMT#{zones.first.formatted_offset}) #{zones.map(&:name).join(", ")}", id ]
    end
    us_ids = ActiveSupport::TimeZone.us_zones.reject { it.name == it.tzinfo.name }.map { it.tzinfo.name }
    us, rest = options.partition { us_ids.include?(it.last) }

    grouped_options_for_select({ "United States" => us, "Other time zones" => rest }, selected)
  end
end
