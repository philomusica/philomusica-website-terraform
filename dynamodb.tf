resource "aws_dynamodb_table" "concert_tickets_table" {
  name           = "philomusica_concert_tickets"
  billing_mode   = "PROVISIONED"
  hash_key       = "ConcertId"
  write_capacity = 2
  read_capacity  = 2

  attribute {
    name = "ConcertId"
    type = "S"
  }

  attribute {
    name = "Description"
    type = "S"
  }

  attribute {
    name = "ImageURL"
    type = "S"
  }

  attribute {
    name = "ConcertDateTime"
    type = "S"
  }

  attribute {
    name = "TotalTickets"
    type = "N"
  }

  attribute {
    name = "TicketsSold"
    type = "N"
  }

  attribute {
    name = "FullPrice"
    type = "N"
  }

  attribute {
    name = "ConcessionPrice"
    type = "N"
  }
}

resource "aws_dynamodb_table" "purchased_tickets" {
	name = "philomusica_concert_purchased_tickets"
	billing_mode = "PROVISIONED"	
	hash_key = "TicketReference"
	write_capacity = 2
	read_capacity  = 2

	attribute {
		name = "TicketReference"
		type = "S"
	}

	attribute {
		name = "EmailAddress"
		type = "S"
	}

	attribute {
		name = "AdmitFullPrice"
		type = "N"
	}

	attribute {
		name = "AdmitConcession"
		type = "N"
	}

	ttl {
		attribute_name = "Expiry"
		enabled = true
	}
}
