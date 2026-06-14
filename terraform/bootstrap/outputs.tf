output "state_bucket" {
  description = "Name of the S3 bucket holding remote state."
  value       = aws_s3_bucket.tfstate.id
}

output "lock_table" {
  description = "Name of the DynamoDB table used for state locking."
  value       = aws_dynamodb_table.tfstate_lock.name
}
