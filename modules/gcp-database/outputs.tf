output "instance_name" {
  description = "Cloud SQL instance name."
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = <<-EOT
    PROJECT:REGION:INSTANCE. Pass to the Helm module as
    cloud_sql_proxy.instance_connection_name.
  EOT
  value       = google_sql_database_instance.this.connection_name
}

output "private_ip" {
  description = "Private IP. Only needed if you bypass the Auth Proxy."
  value       = google_sql_database_instance.this.private_ip_address
}

output "database_name" {
  description = "Database the application uses."
  value       = google_sql_database.presponsieve.name
}

output "iam_user" {
  description = <<-EOT
    IAM database user. Pass to the Helm module as cloud_sql_proxy.iam_user.
  EOT
  value       = google_sql_user.app.name
}
