# Automate setup and deploy MySQL Database server using GitHub, Jenkins, Terraform and Ansible

* Firstly get the code from GitHub.
* Second create infrastructure using Terraform on AWS cloud.
* Finally install Mysql database using Ansible, **Create user- mysqluser and automate table creation**.

### Another option if you want to delete existing table only (optional)
* Choose the option to delete table.


# Note Use Load Balancer in this code because no need to attached LB for direct in DB server if you have deploy application on same server so that use load balancer in same server second thing if you have deploy application on another server that no need to attached LB on DB server , LB attached only application server
