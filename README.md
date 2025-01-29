# Automate setup and deploy MySQL Database server using GitHub, Jenkins, Terraform and Ansible

* Firstly get the code from GitHub.
* Second create infrastructure using Terraform on AWS cloud.
* Finally install Mysql database using Ansible, **Create user- mysqluser and automate table creation**.

### Another option if you want to delete existing table only (optional)
* Choose the option to delete table.


**Note:-** No need to attached LB for direct in DB server if you have deploy application on same server so that use load balancer in same server second thing if you have deploy application on another server that no need to attached LB on DB server , LB attached only application server


## Implementation

* 1. Use t2 medium server and install jenkins, ansible and aws after that configure aws add Access Key and Secret key both user 
(ubuntu and jenkins) use command **aws configure** otherwise you pass credential in jenkins pipeline.
* 2. Open deshboard of jenkins and go to plugins section in manage jenkins after that install plugins:- ansible, sleck (if you have send the update all stages on sleck), Blue Ocean etc.
* 3. Create credential on Jenkins:- Go to credential section in menage jenkins and add credential like:- pem file (ssh password), git tocken (username and password) and slack password (secrate text).
* 4. Create a pipeline and use SCM pipeline option then mention git repo and git tocken (if repo is private), last mention jenkins file name.
