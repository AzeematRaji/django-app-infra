output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.db.endpoint
}

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.db.id
}