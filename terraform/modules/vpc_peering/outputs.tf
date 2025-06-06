output "peering_connections" {
  description = "Information about VPC peering connections"
  value = {
    management_to_environments = {
      for env, vpc in var.environment_vpcs : env => {
        name        = google_compute_network_peering.management_to_environments[env].name
        state       = google_compute_network_peering.management_to_environments[env].state
        network     = google_compute_network_peering.management_to_environments[env].network
        peer_network = google_compute_network_peering.management_to_environments[env].peer_network
      }
    }
    environments_to_management = {
      for env, vpc in var.environment_vpcs : env => {
        name        = google_compute_network_peering.environments_to_management[env].name
        state       = google_compute_network_peering.environments_to_management[env].state
        network     = google_compute_network_peering.environments_to_management[env].network
        peer_network = google_compute_network_peering.environments_to_management[env].peer_network
      }
    }
  }
}

output "peering_status" {
  description = "Status of all peering connections"
  value = {
    for env, vpc in var.environment_vpcs : env => {
      management_to_env = google_compute_network_peering.management_to_environments[env].state
      env_to_management = google_compute_network_peering.environments_to_management[env].state
    }
  }
}
