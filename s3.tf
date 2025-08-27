resource "aws_s3_bucket" "s3" {
  bucket = "week7-dsg-bcket-kipps"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}