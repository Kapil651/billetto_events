config_path = Rails.root.join("config/application.yml")

if File.exist?(config_path)
  yaml_config = YAML.safe_load_file(config_path, aliases: true)
  env_config = yaml_config.fetch(Rails.env, {})

  env_config.each do |key, value|
    ENV[key] ||= value.to_s if value.present?
  end
end
