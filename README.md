# aws_owncloud
Gimme some ownCloud in AWS!

## Overview
This repo contains everything I use to set up my ownCloud server in AWS. It's very *me* specific, and I haven't designed it to be portable at all, sorry.

My inital notes from installing this on a Raspberry Pi are [on Github](https://gist.github.com/brasey/cc378a554edf04fff020).


## Tools and prerequisites
You'll obviously need an AWS account. If you don't have one, go google AWS free tier, you can have cloud things for free (or very close to free).

I use Puppet and r10k to configure the server.

I use Terraform to deploy the server to AWS.

I use Vagrant to test on a local Virtualbox VM.

I use the "Official" CentOS 7 [Amazon AMI](https://aws.amazon.com/marketplace/pp/B00O7WM7QW) and [Vagrant box](https://aws.amazon.com/marketplace/pp/B00O7WM7QW).

You really should understand how SSH keys work. Everything here uses them.


## How to use it
### owncloud.yaml
First thing you have to do is edit **/ops/files\_to\_provision/owncloud.yaml** and define some things.
```yaml
---
db_root_password: ""
owncloud_database: ""
owncloud_db_user: ""
owncloud_db_user_password: ""
gmail_address: ""
gmail_app_password: ""
```
**db\_root\_password** is a secure password for the database root user.

**owncloud\_database** is the name of the database ownCloud will use.

**owncloud\_db\_user** and **owncloud\_db\_user\_password** are the owncloud database user/password, which is granted all privileges to the owncloud database.

**gmail\_address** is your Gmail address or alias.

**gmail\_app\_password** is an app-specific key from Google so you can use Gmail to relay email from the server.


### terraform.tfvars
You'll also need to define some things in **/terraform.tfvars** so that Terraform can provision the server.
```
aws_access_key = ""
aws_secret_key = ""
ssh_key = ""
ssh_key_name = ""
base_image_ami = "ami-61bbf104"
instance_type = "t2.micro"
```
To do anything in AWS programatically, you need an **aws\_access\_key** and **aws\_secret\_key**. Once you have some, define them here.

**ssh\_key** is the path to the private key you'll use to provision your AWS instance.

**ssh\_key\_name** is the name of the key pair that you have configured in AWS EC2.

**base\_image\_ami** is the AMI id of the "Official" CentOS 7 image linked above. The one in the code snippet is in us-east-1.

**instance\_type** is the AWS instance type, or size of the VM you want to deploy. t2.micro qualifies for the free tier, anything else will cost you.


### Deploy a server!
To test it on a Virtualbox or libvirt VM, do
```bash
vagrant up
```

To deploy to AWS, do
```bash
terraform apply
```

## Manual steps
ownCloud requires you to do some configuration manually.

SSH to the server to perform these steps.
(Anywhere I use *FQDN*, put your own FQDN.)

1. yum install links
2. links http://localhost/owncloud
3. configure user/password in browser
4. configure mysql database connection in browser
5. (optional) yum remove links
6. ln -s /etc/httpd/conf.d/owncloud-access.conf.avail /etc/httpd/conf.d/z-owncloud-access.conf
7. edit /etc/owncloud/config.php and set 'trusted\_domains' to the FQDN(s) of your server
8. also in /etc/owncloud/config.php, set 'asset-pipeline.enabled' = true
9. also in /etc/owncloud/config.php, set 'memcache.local' => '\OC\Memcache\APC'
10. openssl genrsa -out *FQDN*.key 2048
11. openssl req -new -key *FQDN*.key -out *FQDN*.csr
12. openssl x509 -req -days 365 -in *FQDN*.csr -signkey *FQDN*.key -out *FQDN*.crt
13. cp *FQDN*.crt /etc/pki/tls/certs
14. cp *FQDN*.key *FQDN*.csr /etc/pki/tls/private
15. sed -i 's/SSLCertificateFile \/etc\/pki\/tls\/certs\/localhost.crt/SSLCertificateFile \/etc\/pki\/tls\/certs\/*FQDN*.crt/' /etc/httpd/conf.d/ssl.conf
16. sed -i 's/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/localhost.key/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/*FQDN*.key/' /etc/httpd/conf.d/ssl.conf
17. systemctl restart httpd

Access the web UI to perform these steps.

1. on the Admin page, Cron section, select 'cron'
2. on the Admin page, Email Server section, choose 'Send mode' = 'sendmail' and set the 'From address'
3. on the Admin page, Security section, check 'Enforce HTTPS'


