provider "aws" {
  region = "ap-south-1"
  profile = "mukesh"
}


resource "aws_instance" "first" {
  ami           = "ami-0bab1ce996865e84"
  instance_type = "t2.micro"
  key_name = "tfkey"
  security_groups = [ "launch-wizard-2" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:\Users\user\Desktop\Terraform\tfkey.pem")
    host     = aws_instance.first.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "tfos"
  }

}


resource "aws_ebs_volume" "tfvolume" {
  availability_zone = aws_instance.first.availability_zone
  size              = 1
  tags = {
    Name = "tfsize"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdd"
  volume_id   = "${aws_ebs_volume.tfvolume.id}"
  instance_id = "${aws_instance.first.id}"
  force_detach = true
}





resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.first.public_ip} > publicip.txt"
  	}
}



resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:\Users\user\Desktop\Terraform\tfkey.pem")
    host     = aws_instance.first.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdd",
      "sudo mount  /dev/xvdd  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/mukeshsandela/Terraform.git /var/www/html/"
    ]
  }
}



resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nullremote3,
  ]

	provisioner "local-exec" {
	    command = "chrome  ${aws_instance.first.public_ip}"
  	}
}


provider "aws" {
  region = "ap-south-1"
}


resource "aws_s3_bucket" "bucket" {
  bucket = "mukesh08"
  acl = "public-read"
  versioning {
    enabled = true
  }


  tags = {
    Name = "tfbucket"
  }


}

resource "aws_cloudfront_distribution" "imgcloudfront" {
    origin {
        domain_name = "mukesh08.s3.amazonaws.com"
        origin_id = "S3-mukesh08" 


        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
        }
    }
       
    enabled = true


    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-mukesh08"


        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }


    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}
