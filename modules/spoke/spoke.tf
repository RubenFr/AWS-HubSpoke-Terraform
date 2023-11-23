
#######################
# Main VPC and Subnets
#######################


resource "aws_vpc" "spoke_vpc" {
  cidr_block           = var.spoke_vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "spoke-vpc"
  }
}

resource "aws_subnet" "tgw_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.spoke_vpc.id
  cidr_block        = local.spoke_subnets_cidr_blocks.tgw[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "tgw-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_subnet" "spoke_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.spoke_vpc.id
  cidr_block        = local.spoke_subnets_cidr_blocks.spoke[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "spoke-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}



# Transit Gateway Attachment

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  subnet_ids         = aws_subnet.tgw_subnets[*].id
  transit_gateway_id = data.aws_ec2_transit_gateway.hub_tgw.id
  vpc_id             = aws_vpc.spoke_vpc.id

  dns_support = "enable"

  tags = {
    Name = "spoke-tgw-attachment"
  }
}



# Route Tables

# Spoke Subnets Route Table

resource "aws_route_table" "spoke_subnets_rt" {
  vpc_id = aws_vpc.spoke_vpc.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = data.aws_ec2_transit_gateway.hub_tgw.id
  }

  tags = {
    Name = "spoke-subnets-rt"
  }

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tgw_attachment]
}


resource "aws_route_table_association" "spoke_subnets_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.spoke_subnets[count.index].id
  route_table_id = aws_route_table.spoke_subnets_rt.id
}



# TGW Subnets Route Table

resource "aws_route_table" "tgw_subnets_rt" {
  vpc_id = aws_vpc.spoke_vpc.id

  tags = {
    Name = "tgw-subnets-rt"
  }
}

resource "aws_route_table_association" "tgw_subnets_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.tgw_subnets[count.index].id
  route_table_id = aws_route_table.tgw_subnets_rt.id
}



# IAM password Policy

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}


# Cloudtrail - enable trail

resource "aws_cloudtrail" "management-events" {
  count                         = var.create_trail ? 1 : 0
  name                          = "management-events"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_bucket]
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  count         = var.create_trail ? 1 : 0
  bucket        = "cloudtrail-bucket-${local.account_id}"
  force_destroy = true

}

resource "aws_s3_bucket_policy" "cloudtrail_bucket" {
  count  = var.create_trail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.cloudtrail_bucket.arn}"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${local.account_id}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
POLICY
}
