resource "aws_s3_bucket" "main" {
  bucket = "${var.bucket_name}-${random_integer.random.result}"

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = var.index_file
  }

  error_document {
    key = var.index_file
  }
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = var.bucket_owner_acl
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_content_public" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.allow_content_public.json
}

data "aws_iam_policy_document" "allow_content_public" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutBucketPolicy",
      "s3:GetBucketPolicyStatus",
    ]
    resources = [
      "${aws_s3_bucket.main.arn}/*",
    ]
  }
}

resource "aws_s3_object" "sync_remote_website_content" {
  for_each = fileset(var.sync_directories[0].local_source_directory, "**/*.*")

  bucket = aws_s3_bucket.main.id
  key    = "${var.sync_directories[0].s3_target_directory}/${each.value}"
  source = "${var.sync_directories[0].local_source_directory}/${each.value}"
  etag   = filemd5("${var.sync_directories[0].local_source_directory}/${each.value}")
  content_type = try(
    lookup(var.mime_types, split(".", each.value)[length(split(".", each.value)) - 1]),
    "binary/octet-stream"
  )

}

resource "random_integer" "random" {
  min = 1
  max = 50000
}

resource "aws_s3_bucket_acl" "main_acl" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

locals {
  s3_origin_id = var.s3_origin_id != "" ? var.s3_origin_id : "tp2-front-s3-origin"
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = var.aws_cloudfront_origin_access_control_name
  description                       = var.aws_cloudfront_origin_access_control_description
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = var.signing_protocol
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.main.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "IPv6 enabled CloudFront distribution for S3 bucket"
  default_root_object = var.index_file

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = var.cookies_forward != "" ? var.cookies_forward : "none"
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy != "" ? var.viewer_protocol_policy : "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = var.restriction_type
      locations        = var.locations
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}