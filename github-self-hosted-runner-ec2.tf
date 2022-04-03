terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}


data "aws_availability_zones" "all_azs" {
  state = "available"
}


resource "aws_launch_template" "ec2_launch_template" {
  name        = "github_runner_launch_template"
  description = "Launch Template for GitHub Runners EC2 AutoScaling Group"

  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = base64encode(templatefile("${path.cwd}/bootstrap.sh", { github_repo_url = var.github_repo_url, github_repo_pat_token = var.github_repo_pat_token, runner_name = var.runner_name, labels = join(",", var.labels) }))
  tags = {
    Name = "github_runner"
  }
}

resource "aws_autoscaling_group" "github_runners_autoscaling_group" {
  name                      = "github_runners_autoscaling_group"
  availability_zones        = data.aws_availability_zones.all_azs.names
  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }
}

variable "ami" {
  description = "The AMI for the GitHub Runner backing EC2 Instance"
  type        = string
}

variable "instance_type" {
  description = "The type of the EC2 instance backing the GitHub Runner"
  type        = string
}

variable "key_name" {
  description = "The KeyPair name for accessing (SSH) into the EC2 instance backing the GitHub Runner"
  type        = string
}

variable "github_repo_url" {
  description = "The GitHub Repo URL for which the GitHub Runner to be registered with"
  type        = string
}

variable "github_repo_pat_token" {
  description = "The GitHub Repo Pat Token that would be used by the GitHub Runner to authenticate with the GitHub Repo"
  type        = string
}

variable "runner_name" {
  description = "The name to give to the GitHub Runner so you can easily identify it"
  type        = string
}

variable "labels" {
  description = "A list of additional labels to attach to the runner instance"
  type        = list(string)
}

variable "health_check_grace_period" {
  description = "The health check grace period"
  type        = number
  default     = 600
}

variable "desired_capacity" {
  description = "The desired number of EC2 instances in the AutoScaling Group"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "The Minimum number of EC2 instances in the AutoScaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The Maximum number of EC2 instances in the AutoScaling Group"
  type        = number
  default     = 1
}


