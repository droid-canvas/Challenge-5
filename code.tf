terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_global_address" "global_load_balancer_ip" {
  name = "global-load-balancer-ip"
}

resource "google_compute_url_map" "global_load_balancer" {
  name            = "global-load-balancer"
  default_service = "YOUR_BACKEND_SERVICE"
}

resource "google_cloud_run_v2_service" "frontend_web_client" {
  name     = "frontend-web-client"
  location = "asia-south1"

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
    containers {
      image = "gcr.io/${var.project_id}/frontend_web_client"
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }
  }
}

resource "google_container_cluster" "api_backend_cluster" {
  name                     = "api-backend-cluster"
  location                 = "asia-south1"
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "api_backend_cluster_nodes" {
  name       = "api-backend-cluster-node-pool"
  location   = "asia-south1"
  cluster    = google_container_cluster.api_backend_cluster.name
  node_count = 1

  node_config {
    machine_type = "e2-medium"
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}

resource "google_sql_database_instance" "megh" {
  name                = "megh"
  database_version    = "POSTGRES_15"
  region              = "asia-south1"
  deletion_protection = true

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
  }
}