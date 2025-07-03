

## Project 1

$ cd project-1/terraform

### Init
$ terraform init

$ terraform plan

### Deploy to aws

$ terraform apply -auto-approve

### Test project 1

Open frontend

Check backend

$ curl -X POST http://lambda-alb-654582969.us-east-1.elb.amazonaws.com   -H "Content-Type: application/json"   -d '{"name":"Arya", "age":16}'

### Destroy all

$ terraform destroy -auto-approve

## Project 2 - Phrase 2

$ terraform apply -auto-approve

##