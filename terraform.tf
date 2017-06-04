provider "aws" {
  region = "ap-southeast-2"
}

variable "website_name" {
    type = "string"
    default = "terraform-travis.hearthfinder.net"
}

terraform {
  backend "s3" {
    bucket = "chrislewisdev-terraform"
    key    = "terraform-travis/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

data "aws_route53_zone" "hearthfinder_zone" {
  name = "hearthfinder.net"
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.website_name}"
  acl    = "public-read"
  policy = "${replace(file("s3-website-policy.json"), "BUCKET_NAME", "${var.website_name}")}"

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket" "www_website_bucket" {
  bucket = "www.${var.website_name}"
  acl    = "public-read"
  policy = "${replace(file("s3-website-policy.json"), "BUCKET_NAME", "www.${var.website_name}")}"

  website {
    redirect_all_requests_to = "${aws_s3_bucket.website_bucket.website_domain}"
  }
}

resource "aws_route53_record" "dns_record" {
  zone_id = "${data.aws_route53_zone.hearthfinder_zone.id}"
  name    = "${var.website_name}"
  type    = "A"

  alias {
    name                   = "${aws_s3_bucket.website_bucket.website_domain}"
    zone_id                = "${aws_s3_bucket.website_bucket.hosted_zone_id}"
    evaluate_target_health = "false"
  }
}

resource "aws_route53_record" "www_dns_record" {
  zone_id = "${data.aws_route53_zone.hearthfinder_zone.id}"
  name    = "www.${var.website_name}"
  type    = "A"

  alias {
    name                   = "${aws_s3_bucket.www_website_bucket.website_domain}"
    zone_id                = "${aws_s3_bucket.www_website_bucket.hosted_zone_id}"
    evaluate_target_health = "false"
  }
}
