prenom          = "RTT"
resource_suffix = "rtt"
admin_cidr      = "94.156.151.222/32"

environment = "dev"

# Required for the real Python API -> PostgreSQL connection.
# Do not commit real production passwords. In CI, prefer the DB_APP_PASSWORD secret.
# Example local usage:
# $env:TF_VAR_db_app_password = "ReplaceMeWithAStrongDemoPassword"

# Private app/db tiers need outbound package access during user_data bootstrap.
enable_private_nat = true

# Keep this false during classroom work unless the team wants automatic stop/start.
enable_nonprod_schedule = false
