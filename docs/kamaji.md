## Architecture Overview

### Management Cluster
The central cluster where Kamaji is installed. It hosts the control planes for all Tenant Clusters as regular Kubernetes pods, leveraging the Management Cluster’s reliability, scalability, and operational features.

### Tenant Clusters
These are user-facing Kubernetes clusters, each with its own dedicated control plane running as pods in the Management Cluster. Tenant Clusters are fully isolated from each other and unaware of the Management Cluster’s existence.

### Tenant Worker Nodes:
Regular virtual or bare metal machines that join a Tenant Cluster by connecting to its control plane. These nodes run only tenant workloads, ensuring strong security and resource isolation.
