data "archive_file" "dummy_archive" {
  type        = "zip"
  output_path = "${path.module}/function.zip"

  source {
    content  = "This is a dummy zip file"
    filename = "dummy.txt"
  }
}

