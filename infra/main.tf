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
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
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

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "OAI for S3 bucket access"
}

locals {
  s3_origin_id = var.s3_origin_id != "" ? var.s3_origin_id : "tp2-front-s3-origin"
}

data "aws_iam_policy_document" "allow_cloudfront_access" {
  statement {
    actions = ["s3:GetObject"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }

    resources = ["${aws_s3_bucket.main.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.allow_cloudfront_access.json
}

resource "aws_cloudfront_distribution" "main" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods

    target_origin_id = local.s3_origin_id

    viewer_protocol_policy = var.viewer_protocol_policy

    forwarded_values {
      query_string = false
      cookies {
        forward = var.cookies_forward
      }
    }
  }

  price_class = var.price_class

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_root_object = var.index_file

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/${var.index_file}"
  }

  restrictions {
    geo_restriction {
      restriction_type = var.restriction_type
      locations        = var.locations
    }
  }

}