
provider "aws" {
  region = "us-west-2"
}
dumm_var = 'test'
# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "main-vpc"
    Environment = "Production"
    Team        = "DevOps"
  }
}

# Subnet Configurations
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public-subnet"
    Environment = "Production"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name        = "private-subnet"
    Environment = "Production"
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "AppServer"
    Environment = "Production"
    Team        = "DevOps"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "logs" {
  bucket = "my-app-logs-12345"

  tags = {
    Name        = "ApplicationLogs"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# RDS MySQL Database Configuration (with Encryption)
resource "aws_db_instance" "my_database" {
  allocated_storage    = 20
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "5.7"
  db_name             = "appdb"
  username            = "admin"
  password            = "password123"
  multi_az            = false
  publicly_accessible = false


  # Enable encryption at rest
  storage_encrypted = true
  kms_key_id        = "arn:aws:kms:us-west-2:123456789012:key/abcd-1234"

  tags = {
    Name        = "MyDatabase"
    Environment = "Production"
    Team        = "DevOps"
  }
  instance_class = ""
}