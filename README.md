
## Prepare

Edit ~/.aws/credentials and put aws credentials in

Install terraform https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

# Project 1

### Architecture

![ Architecutre Project 1](./project-1/architectures/Project1CloudComputing.jpg)

### Terraform
```
$ cd project-1/terraform
```
### Init
```
$ terraform init
```
```
$ terraform plan
```
### Deploy to aws
```
$ terraform apply -auto-approve
```
### Test project 1

Open frontend

[Cloudfront URL: http://d2vky7lfbvwa5o.cloudfront.net](http://d2vky7lfbvwa5o.cloudfront.net)

Check backend

[Link backend http://tf-pj1-dev-lambda-alb-1377999723.us-east-1.elb.amazonaws.com](http://tf-pj1-dev-lambda-alb-1377999723.us-east-1.elb.amazonaws.com)

```
$ curl -X POST http://tf-pj1-dev-lambda-alb-1377999723.us-east-1.elb.amazonaws.com -H "Content-Type: application/json"   -d '{"name":"Arya", "age":16}'
```

### Destroy all

```
$ terraform destroy -auto-approve
```

# Project 2

## Project 2 - Phrase 1

### Architecture

### Cost estimation

## Project 2 - Phrase 2

```
$ terraform apply -auto-approve
```

Open website:

[Web IP: http://52.21.170.174](http://52.21.170.174)

Test/add serveral student

## Project 2 - Phrase 3

```
$ terraform apply -auto-approve
```

### Migration db

#### Add Lab Profile for cloud9

Install Session Manager Plugin

- macos
```
brew install --cask session-manager-plugin
```

linux:
```
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb

```

```
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxxxx \
  --iam-instance-profile Name=LabInstanceProfile
aws ec2 reboot-instances --instance-ids i-xxx

```

### Connect to cloud9

```
aws ssm start-session --target i-xxx
```

- Dump database
```
sh-4.2$ mysqldump -h 10.0.1.33 -u nodeapp -p --databases STUDENTS > data.sql
Enter password:
sh-4.2$ cat data.sql
/*M!999999\- enable the sandbox mode */
-- MariaDB dump 10.19  Distrib 10.5.29-MariaDB, for Linux (x86_64)
--
-- Host: 10.0.1.33    Database: STUDENTS
-- ------------------------------------------------------
-- Server version	8.0.42-0ubuntu0.20.04.1
```

- Import database
```
$ mysql -h tf-pj2-ph3-app-db.c3ousaeg01v3.us-east-1.rds.amazonaws.com -u nodeapp -p  STUDENTS < data.sql
Enter password:
```

### Load test

```
npm install -g loadtest
```

```
loadtest --rps 1000  -c 500 -k <<ELB URL>>
```