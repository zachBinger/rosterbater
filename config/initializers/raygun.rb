Raygun.setup do |config|
  config.api_key = "l9ug31Jc4xMv35E3GNUthw=="
  config.filter_parameters = Rails.application.config.filter_parameters
  config.affected_user_method = :current_user
end
