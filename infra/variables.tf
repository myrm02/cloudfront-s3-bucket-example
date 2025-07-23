variable "bucket_name" {
  type        = string
  description = "The bucket name"
  default     = "iimmbtp2frontbucket"
}

variable "tags" {
  type        = object({
    Name        = string
    Environment = string
  })
  default     = {
    Name        = "tp2_devops_course_front_bucket"
    Environment = "dev"
  }
}

variable "mime_types" {
  description = "Mapping of file extensions to their respective MIME (Multipurpose Internet Mail Extensions) types. This helps in determining the nature and format of a document."
  type        = map(string)
  default = {
    htm  = "text/html"
    html = "text/html"
    css  = "text/css"
    ttf  = "font/ttf"
    js   = "application/javascript"
    map  = "application/javascript"
    json = "application/json"
  }
}

variable "sync_directories" {
  type = list(object({
    local_source_directory = string
    s3_target_directory    = string
  }))
  description = "List of directories to synchronize with Amazon S3."
  default     = [{
  local_source_directory = "../tp2-devops-web-app/dist"
  s3_target_directory    = ""
}]
}

variable "index_file" {
  type        = string
  description = "The index file to be served by the S3 bucket"
  default     = "index.html"
  
}

variable "bucket_owner_acl" {
  type        = string
  description = "Bucket Owner Status for S3 bucket ACL"
  default     = "BucketOwnerPreferred"
}

variable "s3_origin_id" {
  type        = string
  description = "TP2 Front S3 Origin ID"
  default     = "tp2-front-s3-origin"
}

variable "aws_cloudfront_origin_access_control_name" {
  type        = string
  description = "TP2 Front S3 Origin Access Control Name"
  default     = "tp2-front-s3-origin-access-control"
}

variable "aws_cloudfront_origin_access_control_description" {
  type        = string
  description = "TP2 Front S3 Origin Access Control Name"
  default     = "TP2 Front S3 Origin Access Control"
}

variable "signing_protocol" {
  type        = string
  description = "TP2 Front S3 Origin Access Control Signing Protocol"
  default     = "sigv4"
}

variable "restriction_type" {
  type        = string
  description = "The restriction type for the CloudFront distribution"
  default     = "whitelist" 
}

variable "locations" {
  type        = list(string)
  description = "List of locations for the CloudFront distribution"
  default     = ["US", "CA", "IL", "KP"]
  
}

variable "cookies_forward" {
  type        = string
  description = "The method for forwarding cookies in CloudFront distribution"
  default     = "none"
  
}

variable "viewer_protocol_policy" {
  type        = string
  description = "The viewer protocol policy for CloudFront distribution"
  default     = "redirect-to-https"
  
}
