resource "aws_db_subnet_group" "db" {
  name       = "django-app-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  
  tags = merge(var.tags, {
    Name = "django-app-db-subnet-group"
  })
}

resource "aws_db_instance" "db" {
  allocated_storage           = 20
  max_allocated_storage      = 100
  storage_type               = "gp2"
  engine                     = "postgres"
  engine_version             = "14.9"
  instance_class             = "db.t3.micro"
  identifier                 = "django-app-db"
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.db.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az               = true
  publicly_accessible    = false
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = merge(var.tags, {
    Name = "django-app-database"
  })
}