resource "aws_dynamodb_table" "concert_tickets_table" {
  name           = "philomusica_concert_tickets"
  billing_mode   = "PROVISIONED"
  hash_key       = "ID"
  write_capacity = 2
  read_capacity  = 2
  # Table with the following fields
  # ID (S) | Description (S) | Image URL (S) | DateTime (N) | TotalTickets (N) | TicketsSold (N) | FullPrice (N) | ConcessionPrice (N)

  attribute {
    name = "ID"
    type = "S"
  }

}

resource "aws_dynamodb_table" "purchased_tickets" {
	name = "philomusica_concert_purchased_tickets"
	billing_mode = "PROVISIONED"	
	hash_key = "ConcertID"
	range_key = "BookingNumber"
	write_capacity = 2
	read_capacity  = 2
	# DynamoDB table with the following fields
	# ConcertID (S) | BookingNumber (N) | EmailAddress (S) | FullPriceTickets (N) | ConcessionTickets (N) | Expiry (N)

	attribute {
		name = "ConcertID"
		type = "S"
	}

	attribute {
		name = "BookingNumber"
		type = "N"
	}

	ttl {
		attribute_name = "Expiry"
		enabled = true
	}
}
