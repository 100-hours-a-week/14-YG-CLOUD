output "peering_connections" {
  description = "Information about VPC peering connections"
  value = {
    shared_to_environments = {
      for env, vpc in var.environment_vpcs : env => {
        name        = google_compute_network_peering.shared_to_environments[env].name
        state       = google_compute_network_peering.shared_to_environments[env].state
        network     = google_compute_network_peering.shared_to_environments[env].network
        peer_network = google_compute_network_peering.shared_to_environments[env].peer_network
      }
    }
    environments_to_shared = {
      for env, vpc in var.environment_vpcs : env => {
        name        = google_compute_network_peering.environments_to_shared[env].name
        state       = google_compute_network_peering.environments_to_shared[env].state
        network     = google_compute_network_peering.environments_to_shared[env].network
        peer_network = google_compute_network_peering.environments_to_shared[env].peer_network
      }
    }
  }
}

output "peering_status" {
  description = "Status of all peering connections"
  value = {
    for env, vpc in var.environment_vpcs : env => {
      shared_to_env = google_compute_network_peering.shared_to_environments[env].state
      env_to_shared = google_compute_network_peering.environments_to_shared[env].state
    }
  }
}
