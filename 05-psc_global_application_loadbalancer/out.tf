output "global_endpoint" {
  value = "https://${local.domain_name}"
}

output "regional_endpoints" {
  value = {
    for region, domain in local.regional_domains :
    region => "https://${domain}"
  }
}
