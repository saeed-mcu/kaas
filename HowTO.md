# KaaS

### The business challenge: cost, scale, agility
From a business point of view, an instance marketplace platform based on an auction system must satisfy three key goals. First, cost efficiency: for every managed cluster, we want to minimise overhead for the Control Plane, maximise utilisation of resources, and pass savings onto our customers.

Traditional Control Plane architecture, **three dedicated VMs/hosts per cluster** (etcd + API + controllers), adds a fixed cost per cluster that doesn't scale well when you target hundreds of clusters. Second, rapid provisioning and elasticity: given the nature of instances with short-lived consumption, customers expect clusters on demand, spun up not in minutes but seconds. To remain competitive, systems must scale up (and down) control planes dynamically in response to demand. Third, operational consistency and reliability: each tenant's cluster must behave like a single-tenant experience with an isolated control plane, predictable performance, and robust lifecycle management including upgrades, patching, and fail-over. Yet the platform must provide a unified management entry point to operate them all, automating lifecycle operations and treating the control planes as infrastructure-as-code.

In a traditional model, these aims conflict. The overhead of dedicated hardware or VMs per control plane limits cost efficiency; manual or semi-automated provisioning slows agility; and per-cluster operations become an operational nightmare. We needed a new model.

### Why Kubernetes is the platform of choice

Using Kubernetes both as the customer-facing orchestration layer and for the internal management plane makes perfect sense. The familiar API delivers a declarative infrastructure model with a rich ecosystem of controllers and operators, while integration with CNCF primitives and open-source tooling provides a solid foundation. Most importantly, Kubernetes gives us the ability to treat Kubernetes clusters themselves as workloads, leveraging standard Kubernetes lifecycle features like rolling upgrades, self-healing, and autoscaling not just for apps, but for the entire cluster.

By building the management cluster on Kubernetes and running each tenant control plane on top of it, the architecture provides unified operational tooling and enables automation at scale. As we all know, Kubernetes is reliable when its control plane can consistently perform its duties; designing an architecture that supports control planes at scale therefore requires careful implementation.


### Enter Kamaji: Control Planes as Workloads
[Kamaji](https://kamaji.clastix.io/) is an open source Kubernetes Operator that transforms any Kubernetes cluster into a **Management Cluster** capable of orchestrating and managing multiple independent **Tenant Clusters**. This architecture is designed to simplify large-scale Kubernetes operations, reduce infrastructure costs, and provide strong isolation between tenants.
This architecture is well known with the terminology **Hosted Control Plane (HCP)**.

### Architecture at a glance
We maintain a management/seed Kubernetes cluster (or clusters) that hosts Kamaji, Cluster API, and other Control Plane provisioning tooling. Each tenant Kubernetes cluster is based on Cluster API, and Kamaji's extensibility supporting a variety of Infrastructure Providers, including non-public ones, allowed us to integrate it into our ecosystem.

Worker nodes may be remote from the management cluster: architecture allows you to auction instances from all over the  regions, meaning they could be in different data-centres and availability-zones. The control plane, however, remains centrally managed and exposed using an Ingress-based load balancer. This design can be described as `Hybrid Control Planes`, where Worker Nodes join an externally managed Control Plane.

We rely on Konnectivity, an optional component of the Kubernetes control plane, for remote connectivity. The worker nodes communicate outbound to the API-server via the Konnectivity Agent running on each worker, so the Control Plane does not need inbound connectivity into arbitrary worker nodes. This significantly simplifies firewall and topology concerns while helping preserve latency and connection performance even when worker nodes are geographically dispersed.

```
                    Management / Host Cluster
                 ┌──────────────────────────────┐
                 │                              │
                 │   HCP / Control Plane layer  │
                 │   ┌────────────────────────┐ │
                 │   │ kube-apiserver         │ │
                 │   │ controller-manager     │ │
                 │   │ scheduler              │ │
                 │   │ etcd                   │ │
                 │   └────────────────────────┘ │
                 │                              │
                 │   Cluster lifecycle          │
                 │   └── Cluster API (CAPI)     │
                 │                              │
                 └──────────────┬───────────────┘
                                │
                         OpenStack API
                                │
                    ┌───────────▼───────────┐
                    │       OpenStack       │
                    │                       │
                    │   Worker/Data Plane   │
                    │   VMs / Networks      │
                    └───────────────────────┘
```
## How to
### 01 Install KIND
Run Kamaji on kind only for development or learning purposes. [Kind Installation](./docs/01.KIND.md)

### 02 Install Management Cluster
This guide will lead you through the process of creating a working Kamaji setup using Kind cluster.
[Management Cluster](./docs/02.mgmt-cluster.md)

### 03 OpenStack Infra Provider
Use the "Cluster API OpenStack Infra Provider (CAPO)" with the Cluster API Kamaji Control Plane Provider to create Kubernetes clusters. [OpenStack Infra Provider](./docs/03.kamaji-on-openstack.md)
