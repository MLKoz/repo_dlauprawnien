locals {
  project = "${var.tbd_semester}-${var.group_id}"
}
provider "google" {
  project = local.project
  region  = var.region
}
resource "google_dataproc_cluster" "mycluster" {
  name   = "dproc-cluster-unique-name"
  region = var.region
  cluster_config {
    autoscaling_config {
      policy_uri = google_dataproc_autoscaling_policy.asp.name
    }
    worker_config {
      num_instances    =  4
      disk_config {
        boot_disk_size_gb = 30
        num_local_ssds    = 1
      }
    }
}
}


resource "google_dataproc_autoscaling_policy" "asp" {
  policy_id = "dataproc-policy"
  location  = var.region

  worker_config {
    min_instances = 2
    max_instances = 20
  }
  secondary_worker_config {
    min_instances=0
    max_instances = 4
    
  }
  basic_algorithm {
    yarn_config {
      graceful_decommission_timeout = "30s"

      scale_up_factor   = 0.5
      scale_down_factor = 0.5
    }
  }
}




# Submit an example spark job to a dataproc cluster
resource "google_dataproc_job" "spark" {
  region       = google_dataproc_cluster.mycluster.region
  force_delete = true
  placement {
    cluster_name = google_dataproc_cluster.mycluster.name
  }

  spark_config {
    main_class    = "org.apache.spark.examples.SparkPi"
    jar_file_uris = ["file:///usr/lib/spark/examples/jars/spark-examples.jar"]
    args          = ["220000"]

    properties = {
      "spark.logConf" = "true"
    }

    logging_config {
      driver_log_levels = {
        "root" = "INFO"
      }
    }
  }
}

# Submit an example pyspark job to a dataproc cluster
resource "google_dataproc_job" "pyspark" {
  region       = google_dataproc_cluster.mycluster.region
  force_delete = true
  placement {
    cluster_name = google_dataproc_cluster.mycluster.name
  }

  pyspark_config {
    main_python_file_uri = "gs://dataproc-examples-2f10d78d114f6aaec76462e3c310f31f/src/pyspark/hello-world/hello-world.py"
    properties = {
      "spark.logConf" = "true"
    }
  }
}

# Check out current state of the jobs
output "spark_status" {
  value = google_dataproc_job.spark.status[0].state
}

output "pyspark_status" {
  value = google_dataproc_job.pyspark.status[0].state
}

