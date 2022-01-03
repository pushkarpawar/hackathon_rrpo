provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA4QEQ4N345CNOC45O"
  secret_key = "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"
}

resource "aws_security_group" "custom_sec_grp" {
  name        = "allow_http"
  description = "This Security Group Allows HTTP on Server"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
/////////////////////////////////////////////////////
resource "aws_iam_role" "test_role" {
  name = "test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.test_role.name
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = aws_iam_role.test_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

///////////////////////////////////////////////////
resource "aws_instance" "todoservers" {
  ami                    = "ami-0e472ba40eb589f49"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.custom_sec_grp.id]
  iam_instance_profile   = aws_iam_instance_profile.test_profile.name
  key_name               = "deployment"
  tags = {
    Name = "todoservers"
  }

  provisioner "local-exec" {
    command = <<EOT
        echo "[servers]" > ansible/inventory
        echo ${self.public_ip} >> ansible/inventory
        cd ansible/
        sleep 10
        ansible-playbook compose.yml
        EOT
  }
}

