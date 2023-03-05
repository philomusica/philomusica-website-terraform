resource "aws_s3_bucket" "philomusica_website" {
	bucket = "philomusica-website"
}

resource "aws_s3_bucket_acl" "philomusica_website_acl" {
  bucket = aws_s3_bucket.philomusica_website.id
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "philomusica_website_config" {
  bucket = aws_s3_bucket.philomusica_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
	bucket = aws_s3_bucket.philomusica_website.id

	policy = jsonencode({
		Version = "2012-10-17",
		Id      = "PhilomusicaS3BucketPolicy",
		Statement = [
			{
                Sid = "1",
                Effect = "Allow",
                Principal = {
                    AWS = aws_cloudfront_origin_access_identity.philomusica_website_access_identity.iam_arn
                },
                Action = "s3:GetObject",
                Resource = "${aws_s3_bucket.philomusica_website.arn}/*"
			}                                                                                              
		],
	})
}

resource "aws_s3_bucket" "philomusica_website_members_only_content" {
	bucket = "philomusica-website-members-only-content"
}

resource "aws_s3_bucket_acl" "philomusica_website_members_only_acl" {
  bucket = aws_s3_bucket.philomusica_website_members_only_content.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "philomusica_website_members_only_content" {
  bucket = aws_s3_bucket.philomusica_website_members_only_content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
