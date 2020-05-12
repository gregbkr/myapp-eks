# OUTPUTS

# output "default_vpc_id" {
#   value = "${data.aws_vpc.default.id}"
# }

# output "default_subnet_ids" {
#   value = ["${data.aws_subnet_ids.default.ids}"]
# }

output "ecr_hello_container_registry" {
  value = "${aws_ecr_repository.ecr.repository_url}"
}
