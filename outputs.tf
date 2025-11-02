output "db_instance_id" {
  description = "The ID of the RDS database instance"
  value       = aws_db_instance.app_db.id
}