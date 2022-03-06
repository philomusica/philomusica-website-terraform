resource "aws_s3_bucket" "philomusica_website" {
	bucket = "philomusica-website"
	acl = "private"
	website {
		index_document = "index.html"
		error_document = "error.html"
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

