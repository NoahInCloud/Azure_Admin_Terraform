data "external" "usage_details" {
  program = ["pwsh", "-File", "./get_usage_details.ps1"]

  query = {
    start_date = formatdate("2006-01-02", timeadd(timestamp(), "-720h"))
    end_date   = formatdate("2006-01-02", timestamp())
  }
}

output "usage_details" {
  value = data.external.usage_details.result
}
