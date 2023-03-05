resource "aws_dynamodb_table" "concerts_table" {
  name           = "philomusica_concerts"
  billing_mode   = "PROVISIONED"
  hash_key       = "ID"
  write_capacity = 2
  read_capacity  = 2
  # Table with the following fields
  # ID (S) | Title (S) | Image URL (S) | Location (S) | DateTime (N) | TotalTickets (N) | TicketsSold (N) | FullPrice (N) | ConcessionPrice (N)

  attribute {
    name = "ID"
    type = "S"
  }

}

resource "aws_dynamodb_table" "orders_table" {
	name = "philomusica_orders"
	billing_mode = "PROVISIONED"	
	hash_key= "Reference"
	range_key = "ConcertID"
	write_capacity = 2
	read_capacity  = 2
	# DynamoDB table with the following fields
	# Reference (S) | ConcertID (S) | FirstName (S) | LastName (S) | EmailAddress (S) | NumOfFullPrice (N) | NumOfConcessions (N) | Status (S)

	attribute {
		name = "Reference"
		type = "S"
	}

	attribute {
		name = "ConcertID"
		type = "S"
	}

	ttl {
		attribute_name = "Expiry"
		enabled = true
	}
}
