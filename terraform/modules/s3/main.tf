resource "aws_s3_bucket" "django_bucket" {
  bucket = var.bucket_name
  
  tags = merge(var.tags, {
    Name = "django-app-storage"
  })
}

resource "aws_s3_bucket_versioning" "django_bucket" {
  bucket = aws_s3_bucket.django_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "django_bucket" {
  bucket = aws_s3_bucket.django_bucket.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "django_bucket" {
  bucket = aws_s3_bucket.django_bucket.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "django_bucket" {
  bucket = aws_s3_bucket.django_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Access"
        Effect = "Allow"
        Principal = {
          AWS = var.ec2_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.django_bucket.arn}/*"
      },
      {
        Sid    = "AllowEC2ListBucket"
        Effect = "Allow"
        Principal = {
          AWS = var.ec2_role_arn
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.django_bucket.arn
      }
    ]
  })
}