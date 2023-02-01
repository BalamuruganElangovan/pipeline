resource "aws_s3_bucket" "b" {
  bucket = "my-tf-test-bucketsdfsdfqwgy"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}