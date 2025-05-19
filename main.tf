locals {
  name_prefix = "wong"
}

# Step 1 : Create DynamoDB table with data (Table) - Part 1
resource "aws_dynamodb_table" "bookinventory" {
  name         = "${local.name_prefix}-bookinventory"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ISBN"
  range_key    = "Genre"

  attribute {
    name = "ISBN"
    type = "S"
  }

  attribute {
    name = "Genre"
    type = "S"
  }

  tags = {
    Name = "bookinventory"
  }
}

data "aws_dynamodb_table" "bookinventory" {
  name = aws_dynamodb_table.bookinventory.name
}

# Step 1 : Create DynamoDB table with data (Items) - Part 2
resource "aws_dynamodb_table_item" "book1" {
  table_name = aws_dynamodb_table.bookinventory.name
  hash_key   = "ISBN"
  range_key  = "Genre"

  item = <<ITEM
        {
            "ISBN": {"S": "978-3-16-148410-0"},
            "Genre": {"S": "Fiction"},
            "Title": {"S": "The Great Book"},
            "Pages": {"N": "320"}
        }
        
        ITEM
}

resource "aws_dynamodb_table_item" "book2" {
  table_name = aws_dynamodb_table.bookinventory.name
  hash_key   = "ISBN"
  range_key  = "Genre"

  item = <<ITEM
        {
            "ISBN": {"S": "978-0-13-110362-7"},
            "Genre": {"S": "Science"},
            "Title": {"S": "Understanding the Universe"},
            "Pages": {"N": "220"}
        }
        
        ITEM
}

# Step 2 : Create Policy
resource "aws_iam_policy" "dynamodb_read_policy" {
  name        = "${local.name_prefix}-read"
  description = "Read access to ${local.name_prefix}-bookinventory table"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:List*",
          "dynamodb:Describe*",
          "dynamodb:Get*",
          "dynamodb:Scan*",
          "dynamodb:Query*"
        ],

        Effect   = "Allow",
        Resource = data.aws_dynamodb_table.bookinventory.arn
      }
    ]
  })
}

# Step 3 : Create IAM Role
resource "aws_iam_role" "role_example" {
  name = "${local.name_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.dynamodb_read_role.name
  policy_arn = aws_iam_policy.dynamodb_read_policy.arn
}

resource "aws_iam_role" "dynamodb_read_role" {
  name = "${local.name_prefix}-read-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Step 4 : Create EC2 Instance
resource "aws_instance" "demo_ec2" {
  ami           = "ami-0afc7fe9be84307e4"
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = "${local.name_prefix}-dynamodb-test-instance"
  }

  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y aws-cli
        EOF
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.dynamodb_read_role.name
}