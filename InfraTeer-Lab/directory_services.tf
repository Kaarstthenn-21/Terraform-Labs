resource "aws_directory_service_directory" "course_ad" {
  name = var.domain_name

  # don't change this or parameterize this as it will destroy the existing AD. Update it directly on AD & in "domain_pwd" variable in Terraform
  password = "InfraCourse!23"

  #short_name="${var.short_name}"
  edition     = "Standard"
  description = "InfraAD"

  vpc_settings {
    vpc_id = aws_vpc.vpc.id

    subnet_ids = [
      aws_subnet.subnet-private.id,
      aws_subnet.subnet-public.id,
    ]
  }

  type = var.dir_type

  lifecycle {
    ignore_changes = [
      # Ignore changes to edition, Because for some reason it wants to recreat it always
      edition,
    ]
  }
}
