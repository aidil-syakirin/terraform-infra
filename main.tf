resource "terraform_data" "example" {
  input = "Hello World and Terraform"
}

resource "terraform_data" "another_example" {
  input = "Another Hello World and Terraform"
}

output "example_message" {
  value = terraform_data.example.output
}
