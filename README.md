# Kubernetes-as-a-Service (KaaS) Architecture and Platform Comparison

## 1. Executive Summary

Kubernetes-as-a-Service (KaaS) is the operational model in which an infrastructure or platform provider offers Kubernetes clusters as a managed service rather than requiring each customer or application team to build and operate Kubernetes clusters independently.

There are several fundamentally different approaches to KaaS:

1. **Traditional self-managed Kubernetes** — each cluster owns and runs its own control plane.
2. **Automated self-managed clusters** — tools such as Cluster API automate provisioning and lifecycle management while control planes still normally run as part of each workload cluster.
3. **Hosted Control Plane (HCP)** — the Kubernetes control plane is separated from the worker/data plane and hosted in a management cluster.
4. **Full KaaS platforms** — platforms such as Gardener and KKP combine cluster lifecycle management, hosted control planes, multi-tenancy, infrastructure abstraction, networking, upgrades, monitoring, backup, policy, and user-facing APIs.


For an organization building a **managed Kubernetes service**, the distinction between "cluster lifecycle automation" and "KaaS platform" is critical.

**Cluster API is primarily a cluster lifecycle framework.** It provides declarative APIs and a provider model for provisioning, upgrading, scaling, and deleting clusters.

**Kamaji is primarily a hosted-control-plane operator.** It runs tenant Kubernetes control planes as pods in a management cluster and can integrate with Cluster API.

**Gardener and KKP are broader KaaS platforms.** Both use management/seed concepts to operate many user clusters and host control-plane components separately from worker nodes.

**HyperShift is a specialized hosted-control-plane platform for OpenShift**, designed to host OpenShift control planes at scale and separate management from workload infrastructure.

### High-level recommendation

For a company building a **general-purpose managed Kubernetes service**, the strongest candidates are:

* **Gardener** — strongest fit when the goal is a complete, multi-cloud, large-scale KaaS platform.
* **KKP** — strong fit when a more integrated commercial/open-core platform experience, UI, projects, multi-tenancy, and operational tooling are important.
* **Kamaji + Cluster API** — particularly attractive when building a customizable KaaS platform internally and wanting maximum architectural control over the hosted-control-plane layer.
* **Cluster API alone** — excellent foundation, but usually not sufficient by itself to constitute a complete managed Kubernetes service.
* **HyperShift** — excellent hosted-control-plane architecture, but its primary target is OpenShift rather than a generic upstream-Kubernetes KaaS offering.

---

# 2. Introduction: Evolution of Kubernetes Cluster Management

## 2.1 Traditional model: every cluster owns its control plane

The original and still very common Kubernetes deployment model looks like this:

```text
                    Kubernetes Cluster
┌─────────────────────────────────────────────────┐
│                                                 │
│   Control Plane                                 │
│   ┌─────────┐ ┌────────────┐ ┌─────────────┐   │
│   │ API     │ │ Scheduler  │ │ Controller  │   │
│   │ Server  │ │            │ │ Manager     │   │
│   └─────────┘ └────────────┘ └─────────────┘   │
│             ┌────────────┐                     │
│             │    etcd    │                     │
│             └────────────┘                     │
│                                                 │
│   Worker/Data Plane                             │
│   ┌────────┐ ┌────────┐ ┌────────┐             │
│   │ Worker │ │ Worker │ │ Worker │             │
│   └────────┘ └────────┘ └────────┘             │
│                                                 │
└─────────────────────────────────────────────────┘
```

The control plane normally runs on dedicated machines or VMs. Cluster lifecycle tools such as kubeadm automate bootstrap, but each cluster still has its own control-plane infrastructure.

This model is straightforward and provides strong physical/resource isolation.

However, operating hundreds or thousands of clusters becomes expensive because each cluster potentially requires:

* multiple control-plane nodes;
* etcd;
* load balancers;
* networking;
* operating-system management;
* Kubernetes upgrades;
* certificate management;
* backups;
* monitoring;
* security hardening;
* control-plane capacity planning.

The operational overhead grows approximately with the number of clusters.

---

# 3. Automated Self-Managed Kubernetes

The next evolution is to automate the traditional model.

Instead of manually creating VMs and running kubeadm, a management system maintains declarative Kubernetes resources describing the desired cluster.

This is where **Cluster API (CAPI)** becomes important.

Cluster API is a Kubernetes SIG project focused on declarative APIs and tooling for provisioning, upgrading, scaling, and operating multiple Kubernetes clusters. It uses a management cluster containing providers that manage workload clusters.

The architecture becomes:

```text
                    Management Cluster
             ┌───────────────────────────┐
             │                           │
             │       Cluster API         │
             │       Providers            │
             │                           │
             └─────────────┬─────────────┘
                           │
             ┌─────────────┼─────────────┐
             │             │             │
             ▼             ▼             ▼
        Cluster A      Cluster B      Cluster C
        ┌───────┐      ┌───────┐      ┌───────┐
        │ CP    │      │ CP    │      │ CP    │
        │ + etcd│      │ + etcd│      │ + etcd│
        ├───────┤      ├───────┤      ├───────┤
        │Workers│      │Workers│      │Workers│
        └───────┘      └───────┘      └───────┘
```

The management cluster manages lifecycle, but each workload cluster still owns its own control plane.

This provides much better automation but does **not fundamentally solve the cost of dedicated control planes**.

---

# 4. Hosted Control Plane Model

The next major architectural evolution is the **Hosted Control Plane (HCP)**.

Instead of:

```text
Cluster A = Control Plane + Workers
Cluster B = Control Plane + Workers
Cluster C = Control Plane + Workers
```

we separate the control plane from the worker infrastructure:

```text
                  Management / Hosting Cluster
        ┌────────────────────────────────────────┐
        │                                        │
        │  CP-A       CP-B       CP-C            │
        │ ┌──────┐   ┌──────┐   ┌──────┐         │
        │ │ API  │   │ API  │   │ API  │         │
        │ │ etcd │   │ etcd │   │ etcd │         │
        │ └──────┘   └──────┘   └──────┘         │
        │                                        │
        └───────────────┬────────────────────────┘
                        │
          ┌─────────────┼──────────────┐
          │             │              │
          ▼             ▼              ▼
       Workers A     Workers B      Workers C
       Cluster A     Cluster B      Cluster C
```

The control planes run as Kubernetes workloads in a hosting/management cluster.

This has several major advantages:

### Cost efficiency

Many control planes can share the same underlying infrastructure.

### Faster provisioning

Creating a control plane can become equivalent to creating Kubernetes workloads rather than provisioning a new set of VMs.

### Centralized operations

The platform operator can manage:

* Kubernetes versions;
* control-plane resources;
* upgrades;
* certificates;
* monitoring;
* backups;
* security;
* scheduling;

from the management layer.

### Better separation

The worker infrastructure can be completely separate from the control-plane infrastructure.

Kamaji explicitly follows this model: tenant control planes run as pods inside the management cluster, while workers can run on cloud, data-center, or edge infrastructure.

Gardener follows a similar principle using **seed clusters**, where the control planes of multiple shoot clusters are hosted in the seed.

KKP similarly uses seed clusters to host user-cluster control-plane components.

HyperShift uses the hosted-control-plane model for OpenShift.

---

# 5. KaaS Architecture Categories

The products in this comparison should not be considered identical products.

They belong to different architectural categories.

| Solution    | Primary category          |      HCP | Cluster lifecycle |         Full KaaS platform |
| ----------- | ------------------------- | -------: | ----------------: | -------------------------: |
| Cluster API | Lifecycle framework       | Optional |         Excellent |                         No |
| Kamaji      | Hosted control plane      |      Yes |   Good / via CAPI |                    Partial |
| Gardener    | KaaS platform             |      Yes |         Excellent |                        Yes |
| KKP         | KaaS platform             |      Yes |         Excellent |                        Yes |
| HyperShift  | Hosted OpenShift platform |      Yes |         Excellent | Yes, but OpenShift-focused |

This distinction is extremely important.

For example, comparing **Cluster API directly against Gardener** is somewhat like comparing an orchestration framework with a complete service platform.

Gardener itself describes the relationship by saying that CAPI primarily harmonizes how to get to clusters, while Gardener goes further by harmonizing the clusters and their operational behavior.

---

# 6. Cluster API

## 6.1 Overview

Cluster API provides Kubernetes-native APIs for cluster lifecycle management.

Its architecture is provider-based:

```text
                    Management Cluster
                           │
            ┌──────────────┼──────────────┐
            │              │              │
       Core Provider   Bootstrap       Control Plane
            │           Provider          Provider
            │              │              │
            └──────────────┼──────────────┘
                           │
                    Infrastructure
                       Provider
                           │
                           ▼
                     Workload Cluster
```

The current Cluster API provider ecosystem includes infrastructure providers for environments such as AWS, Azure, OpenStack, vSphere, Metal3 and others. Its provider list also includes Kamaji as a control-plane provider.

## 6.2 Strengths

* Kubernetes-native API.
* Large ecosystem.
* Provider model.
* Multi-cloud capability.
* Declarative lifecycle.
* GitOps-friendly.
* Strong integration with Kubernetes ecosystem.
* Can use different infrastructure providers.
* Can integrate with hosted control-plane providers.
* Good foundation for building a custom KaaS platform.

## 6.3 Weaknesses

Cluster API by itself is **not a complete managed Kubernetes service**.

You generally still need to build or integrate:

* tenant management;
* authentication;
* authorization;
* billing/metering;
* UI/API;
* networking;
* DNS;
* load balancers;
* cluster templates;
* quotas;
* monitoring;
* logging;
* backup;
* policy;
* lifecycle policies;
* support processes.

The management cluster model is explicitly designed around providers managing separate workload clusters.

## 6.4 Best use

Use Cluster API when:

> "We want to build our own Kubernetes platform and need a standard Kubernetes-native lifecycle abstraction."

It is particularly powerful when combined with a hosted-control-plane provider such as Kamaji.

---

# 7. Kamaji

## 7.1 Overview

Kamaji is a Kubernetes operator specifically designed for managed Kubernetes clusters using hosted control planes.

Its core architecture is:

```text
                 Kamaji Management Cluster
        ┌─────────────────────────────────────┐
        │                                     │
        │ Tenant CP A     Tenant CP B         │
        │ ┌───────────┐   ┌───────────┐       │
        │ │ API Server│   │ API Server│       │
        │ │ Scheduler │   │ Scheduler │       │
        │ │ Controller│   │ Controller│       │
        │ │ etcd      │   │ etcd      │       │
        │ └───────────┘   └───────────┘       │
        │                                     │
        └─────────────────────────────────────┘
                 │                 │
                 ▼                 ▼
             Workers A          Workers B
```

Kamaji explicitly states that it runs each tenant control plane as pods in the management cluster and uses upstream Kubernetes control-plane components with kubeadm-based setup/lifecycle.

## 7.2 Important feature: Cluster API integration

Kamaji can act as a Cluster API control-plane provider through `KamajiControlPlane`.

This creates an interesting architecture:

```text
                  Cluster API
                       │
              ┌────────┴────────┐
              │                 │
       Infrastructure        Kamaji
         Provider        Control Plane Provider
              │                 │
              ▼                 ▼
          Worker VMs       Hosted Control Plane
```

This separation is powerful because infrastructure and control-plane lifecycle can be managed independently.

## 7.3 Strengths

* Native hosted control plane.
* Upstream Kubernetes.
* Lightweight.
* Kubernetes-native.
* Good infrastructure/control-plane separation.
* Works with CAPI.
* Suitable for cloud, on-premises and edge.
* Strong fit for custom KaaS platforms.

## 7.4 Weaknesses

Compared with Gardener or KKP, Kamaji is more focused on the **control-plane layer**.

A platform operator may need to build additional components around it for:

* complete tenant portal;
* project management;
* quotas;
* billing;
* policy;
* cluster catalog;
* centralized lifecycle policies;
* advanced multi-cloud orchestration;
* platform-level observability.

Therefore:

> **Kamaji is a very good building block for a KaaS platform, rather than necessarily being the entire KaaS platform.**

---

# 8. Gardener

## 8.1 Overview

Gardener is specifically designed around the concept of **Kubernetes clusters as a service**.

Its architecture contains:

```text
                    Garden Cluster
                         │
                     Gardener
                         │
                ┌────────┴────────┐
                │                 │
              Seed A             Seed B
                │                 │
       ┌────────┼────────┐        │
       │        │        │        │
     Shoot A  Shoot B  Shoot C   Shoot D
       │
       ▼
    Workers
```

A **Garden** cluster contains the Gardener control system.

A **Seed** cluster hosts control planes.

A **Shoot** is the Kubernetes cluster provided to the user.

Gardener's architecture explicitly describes seed clusters as hosting the control planes of multiple end-user shoot clusters.

## 8.2 Gardener is more than HCP

Gardener manages the complete lifecycle of Kubernetes clusters as a service and provides extension points for infrastructure and provider-specific integrations.

It also has components analogous to Kubernetes control-plane components:

```text
Kubernetes              Gardener
----------------------------------------
API Server               gardener-apiserver
Controller Manager       gardener-controller-manager
Scheduler                gardener-scheduler
Kubelet                  gardenlet
```

The scheduler selects an appropriate seed for a new cluster.

## 8.3 Strengths

* Designed specifically for KaaS.
* Strong multi-cloud architecture.
* Hosted control planes.
* Seed/shoot model.
* Declarative API.
* Strong lifecycle automation.
* Multi-tenancy concepts.
* Extension architecture.
* Large-scale cluster management.
* Strong infrastructure abstraction.
* Automated control-plane management.
* Workerless/control-plane-as-a-service use cases.
* Mature operational model.

Gardener can even create workerless shoots, where only the control plane exists, which demonstrates how deeply the platform separates control plane from data plane.

## 8.4 Weaknesses

* Considerably more complex than Kamaji.
* Larger operational footprint.
* More concepts to learn.
* Requires understanding Garden, Seed, Shoot and extensions.
* Can be excessive for a small platform.
* Requires significant platform engineering knowledge.

## 8.5 Best use

Gardener is particularly strong when the objective is:

> **"We want to operate a large-scale, multi-tenant, multi-cloud Kubernetes-as-a-Service platform."**

---

# 9. Kubermatic Kubernetes Platform (KKP)

## 9.1 Overview

KKP is a complete Kubernetes management platform with a master/seed/user-cluster architecture.

The basic architecture is:

```text
                    KKP Master
                       │
          ┌────────────┼────────────┐
          │            │            │
       Seed A       Seed B       Seed C
          │            │            │
      ┌───┼───┐        │            │
      │   │   │        │            │
     UC1 UC2 UC3      UC4          UC5
```

KKP documentation defines:

* **Master Cluster** — central management and metadata.
* **Seed Cluster** — hosts user-cluster control planes.
* **User Cluster** — the Kubernetes cluster used by customers.

KKP's seed architecture therefore implements the hosted-control-plane concept.

## 9.2 Platform features

KKP goes beyond control-plane lifecycle.

It includes capabilities around:

* multi-tenancy;
* projects;
* OIDC;
* monitoring;
* logging;
* alerting;
* cluster templates;
* backups;
* quotas;
* application catalog;
* UI;
* multiple seeds in Enterprise Edition;
* edge capabilities.

The Enterprise Edition supports multiple seed clusters for independent management zones such as edge, cloud and on-premises.

KKP also provides monitoring/logging/alerting stacks for both management and user clusters.

## 9.3 Strengths

* Complete KaaS platform.
* Hosted control planes.
* User-facing UI.
* Projects and multi-tenancy.
* Cluster templates.
* Monitoring/logging/alerting.
* Backup integration.
* Multiple seeds in Enterprise Edition.
* Broad infrastructure support.
* Strong operational tooling.

## 9.4 Weaknesses

* Larger platform footprint.
* More opinionated than CAPI/Kamaji.
* Commercial Enterprise features exist.
* Less suitable if the goal is to build every platform layer yourself.
* Architecture and lifecycle are more tightly integrated into the KKP platform.

## 9.5 Best use

KKP is strong when:

> **"We want a ready-made managed Kubernetes platform rather than assembling the platform ourselves."**

---

# 10. HyperShift

## 10.1 Overview

HyperShift is different from the other solutions because its primary focus is **OpenShift hosted control planes**.

Its own project description says that HyperShift is middleware for hosting OpenShift control planes at scale and focuses on cost, provisioning time, portability and separation between management and workloads.

The architecture is:

```text
                 OpenShift Management Cluster
                         │
          ┌──────────────┼──────────────┐
          │              │              │
       Hosted CP A    Hosted CP B    Hosted CP C
          │              │              │
          ▼              ▼              ▼
       Workers A       Workers B      Workers C
```

The HyperShift API explicitly models the separation between the control plane and data plane.

## 10.2 Strengths

* Mature hosted-control-plane architecture.
* Designed for large-scale hosted clusters.
* Strong control/data-plane separation.
* OpenShift ecosystem integration.
* Strong security/isolation model.
* CAPI integrations exist within the ecosystem.
* Strong cloud portability.

## 10.3 Weaknesses

The most important limitation for this comparison is:

> HyperShift is primarily an **OpenShift** platform rather than a generic upstream-Kubernetes KaaS framework.

Therefore, if the service you intend to offer is:

```text
Managed Kubernetes
```

rather than:

```text
Managed OpenShift
```

Gardener, KKP or Kamaji+CAPI are generally more natural starting points.

---

# 11. Architecture Comparison

| Capability                 |           CAPI |    Kamaji |            Gardener |       KKP |          HyperShift |
| -------------------------- | -------------: | --------: | ------------------: | --------: | ------------------: |
| Kubernetes lifecycle       |          ★★★★★ |      ★★★★ |               ★★★★★ |     ★★★★★ |               ★★★★★ |
| Hosted control plane       |       Optional |     ★★★★★ |               ★★★★★ |     ★★★★★ |               ★★★★★ |
| Upstream Kubernetes        |          ★★★★★ |     ★★★★★ |               ★★★★★ |     ★★★★★ |                  ★★ |
| OpenShift                  |      Ecosystem |        No |                  No |        No |               ★★★★★ |
| Multi-cloud                |          ★★★★★ |     ★★★★★ |               ★★★★★ |     ★★★★★ |                ★★★★ |
| On-premises                |          ★★★★★ |     ★★★★★ |               ★★★★★ |     ★★★★★ |                ★★★★ |
| Edge                       |           ★★★★ |     ★★★★★ |                ★★★★ |     ★★★★★ |                ★★★★ |
| Multi-tenancy              | Building block |      ★★★★ |               ★★★★★ |     ★★★★★ |                ★★★★ |
| User portal                |          Build |     Build | Available ecosystem |     ★★★★★ | OpenShift ecosystem |
| Billing/metering           |          Build |     Build |           Integrate | Available |           Integrate |
| Monitoring                 |      Integrate | Integrate |               ★★★★★ |     ★★★★★ |               ★★★★★ |
| Backup                     |      Integrate | Integrate |               ★★★★★ |     ★★★★★ |               ★★★★★ |
| Cluster templates          |          ★★★★★ |      ★★★★ |               ★★★★★ |     ★★★★★ |                ★★★★ |
| Infrastructure abstraction |          ★★★★★ |  Via CAPI |               ★★★★★ |     ★★★★★ |                ★★★★ |
| Operational complexity     |     Low/Medium |    Medium |                High |      High |                High |
| Platform completeness      |             ★★ |       ★★★ |               ★★★★★ |     ★★★★★ |                ★★★★ |
| Customizability            |          ★★★★★ |     ★★★★★ |                ★★★★ |       ★★★ |                 ★★★ |
| Ready-made KaaS            |             No |   Partial |                 Yes |       Yes |                Yes* |

`*` HyperShift is primarily an OpenShift service architecture.

The star ratings are architectural assessments rather than official vendor/project scores.

---

# 12. Control Plane Comparison

This is one of the most important dimensions.

| Solution            | Control-plane location     |
| ------------------- | -------------------------- |
| CAPI + kubeadm      | Workload cluster           |
| CAPI + HCP provider | Management cluster         |
| Kamaji              | Management cluster         |
| Gardener            | Seed cluster               |
| KKP                 | Seed cluster               |
| HyperShift          | Management/hosting cluster |

Cluster API itself supports different control-plane provider models, and its provider contract defines the control plane abstraction rather than forcing one implementation.

Kamaji explicitly implements the hosted model.

Gardener and KKP use the seed model.

HyperShift implements hosted OpenShift control planes.

---

# 13. Operational Model Comparison

## Traditional

```text
Operator
   │
   ├── Cluster A
   │    ├── CP
   │    └── Workers
   │
   ├── Cluster B
   │    ├── CP
   │    └── Workers
   │
   └── Cluster C
        ├── CP
        └── Workers
```

Operational responsibility grows with cluster count.

## CAPI

```text
                Management
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
        CAPI-A    CAPI-B    CAPI-C
          │         │         │
        Cluster   Cluster   Cluster
```

Lifecycle automation improves significantly.

## HCP

```text
                 Management
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
      CP-A          CP-B         CP-C
        │            │            │
      Workers      Workers      Workers
```

Control-plane resources become centralized and share infrastructure.

## Full KaaS

```text
                     KaaS Platform
                          │
        ┌─────────────────┼──────────────────┐
        │                 │                  │
     Identity          Lifecycle          Billing
        │                 │                  │
        ├───────────── Cluster API ─────────┤
        │                 │                  │
        │              HCP Layer             │
        │                 │                  │
        └──────────── Infrastructure ────────┘
                          │
                 Kubernetes Clusters
```

This final model is what a serious managed Kubernetes service generally needs.

---

# 14. Multi-Tenancy

Multi-tenancy is not simply "multiple Kubernetes clusters."

A production KaaS platform normally needs:

* tenants;
* projects;
* users;
* groups;
* authentication;
* authorization;
* quotas;
* resource limits;
* cluster limits;
* network isolation;
* audit;
* billing/metering;
* cluster ownership;
* lifecycle policies.

### CAPI

Provides the Kubernetes-native lifecycle building blocks, but the platform operator generally needs to implement the tenant layer.

### Kamaji

Provides isolated tenant control planes and is particularly useful when customers require full cluster-admin privileges. Kamaji explicitly distinguishes its dedicated control-plane model from namespace-level multi-tenancy solutions.

### Gardener

Designed around projects, shoots, seeds and a central Garden control plane.

### KKP

Provides projects, users, OIDC, quotas and other platform-level capabilities.

### HyperShift

Strong hosted-cluster isolation, but its platform model is primarily tied to OpenShift.

---

# 15. Infrastructure Abstraction

A serious KaaS platform may need to support:

```text
Public Cloud
 ├── AWS
 ├── Azure
 ├── GCP
 └── Other clouds

Private Cloud
 ├── VMware
 ├── OpenStack
 ├── Nutanix
 └── Bare metal

Edge
 ├── Remote sites
 └── Small clusters
```

CAPI is particularly strong here because its architecture is explicitly provider-oriented.

For example:

```text
                  Cluster API
                       │
       ┌───────────────┼────────────────┐
       │               │                │
      AWS           OpenStack         vSphere
       │               │                │
     Workers         Workers          Workers
```

Kamaji complements this architecture by allowing the hosted control plane to remain independent of the worker infrastructure.

Gardener also has a strong multi-cloud extension model.

KKP provides broad infrastructure support through its cloud and private-infrastructure integrations.

---

# 16. Upgrades

A managed Kubernetes platform needs to separate:

### Control-plane upgrade

```text
Kubernetes 1.31
      ↓
Kubernetes 1.32
      ↓
Kubernetes 1.33
```

from:

### Worker upgrade

```text
Worker Pool
   ↓
Rolling replacement
   ↓
New Kubernetes version
```

With HCP, this separation becomes particularly useful.

For example:

```text
                 Management
                     │
               Control Plane
                     │
                Kubernetes
                 Upgrade
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
     Workers       Workers      Workers
```

The worker fleet can be upgraded independently according to the platform's lifecycle policy.

---

# 17. High Availability

The HCP model introduces an important distinction:

> **The hosting cluster becomes part of the control-plane failure domain.**

Therefore, if you host 500 control planes in one management cluster, that management cluster is extremely important.

A production design should consider:

```text
               Management Region
          ┌─────────────────────────┐
          │                         │
       Seed A                    Seed B
          │                         │
       CP 1..N                   CP 1..N
          │                         │
       Workers                   Workers
```

Gardener explicitly supports HA control planes and distributes replicas across failure domains.

KKP also has explicit seed infrastructure and HA requirements for production environments.

---

# 18. Network Architecture

Hosted control planes create an additional networking requirement.

The API server is physically located in the management/seed cluster, while the worker nodes are somewhere else.

Therefore:

```text
Worker
   │
   │ Kubernetes API
   ▼
Management/Seed
   │
   ▼
Hosted API Server
```

You must solve:

* API endpoint exposure;
* worker-to-control-plane connectivity;
* control-plane-to-worker connectivity;
* webhook connectivity;
* `kubectl exec`;
* `kubectl logs`;
* port forwarding;
* CNI;
* DNS;
* private endpoints;
* public endpoints;
* firewalling.

Gardener, for example, uses connectivity components including VPN mechanisms to handle communication between hosted control planes and shoot worker networks.

KKP similarly provides different expose strategies including NodePort, LoadBalancer and tunneling.

This is one of the most important engineering areas when implementing HCP.

---

# 19. Security

A production KaaS platform should consider:

### Tenant isolation

Each tenant should be isolated at:

* API level;
* Kubernetes namespace level;
* network level;
* identity level;
* infrastructure level.

### Control-plane isolation

A compromise of one hosted control plane must not compromise another.

### Management-plane isolation

The management cluster becomes highly privileged.

### Secrets

The platform must protect:

* cluster CA;
* service-account keys;
* etcd encryption keys;
* cloud credentials;
* bootstrap credentials;
* kubeconfigs.

Cluster API's control-plane contract explicitly calls out security considerations around private key material.

HyperShift also emphasizes namespace isolation and one-directional communication as architectural invariants.

---

# 20. Observability

A complete KaaS platform should monitor two layers.

## Platform layer

```text
Management
 ├── Controllers
 ├── API
 ├── Scheduler
 ├── HCP
 ├── Infrastructure
 └── Database
```

## Customer cluster layer

```text
User Cluster
 ├── API Server
 ├── etcd
 ├── Nodes
 ├── Pods
 ├── Network
 └── Storage
```

KKP explicitly provides separate management/seed and user-cluster monitoring/logging/alerting stacks.

Gardener similarly deploys observability components for control-plane and system components.

---

# 21. Platform Engineering Complexity

A useful way to compare the solutions is:

```text
                More platform functionality
                         ↑
                         │
                    Gardener
                         │
                      KKP
                         │
                    HyperShift
                         │
                     Kamaji
                         │
                    Cluster API
                         │
                         └────────────→
                         More building required
```

This isn't a quality ranking.

It describes the amount of platform functionality you get out of the box.

### Cluster API

More building, more flexibility.

### Kamaji

Hosted control plane building block + CAPI integration.

### Gardener

Complete KaaS architecture with a strong operator model.

### KKP

Complete KaaS product/platform.

### HyperShift

Complete hosted OpenShift architecture.

---

# 22. Which Is Best for Managed Kubernetes?

There is no universal winner because "managed Kubernetes" can mean different things.

## Scenario A — Build your own KaaS platform

Recommended:

**Cluster API + Kamaji**

Architecture:

```text
                  Your KaaS Platform
                         │
             ┌───────────┴───────────┐
             │                       │
        Platform API             Cluster API
             │                       │
             │                ┌──────┴──────┐
             │                │             │
             │              Kamaji      Infra Provider
             │                │             │
             │                ▼             ▼
             │          Hosted CP       Workers
             │
          Identity
          Billing
          Quotas
          Monitoring
          Portal
```

This gives you control over the platform architecture.

**Best when your engineering organization wants to own the KaaS product.**

---

# 23. Scenario B — Large-scale multi-cloud KaaS

Recommended:

**Gardener**

Architecture:

```text
                       Garden
                          │
                      Gardener
                          │
             ┌────────────┼────────────┐
             │            │            │
           Seed A       Seed B       Seed C
             │            │            │
          Shoots        Shoots        Shoots
             │            │            │
          Workers       Workers       Workers
```

This is arguably the most natural architecture when the goal is:

> **Thousands of standardized Kubernetes clusters across multiple infrastructure providers.**

Gardener was explicitly designed around Kubernetes clusters as a service and the seed/shoot model.

---

# 24. Scenario C — Ready-made managed Kubernetes platform

Recommended:

**KKP**

KKP already provides much of the surrounding platform functionality:

* UI;
* projects;
* identity;
* cluster lifecycle;
* seeds;
* monitoring;
* logging;
* alerting;
* backups;
* cluster templates;
* infrastructure integration.

Its architecture explicitly separates master, seed and user clusters.

Therefore it can reduce the amount of platform engineering required.

---

# 25. Scenario D — Managed OpenShift

Recommended:

**HyperShift**

If the service is specifically:

> OpenShift-as-a-Service

then HyperShift is the most directly aligned solution.

It was designed specifically to host OpenShift control planes at scale.

---

# 26. Recommended Architecture for a New KaaS Provider

If the objective is to build a **generic managed Kubernetes service**, my preferred architecture would be:

```text
                           Customer
                              │
                              ▼
                    KaaS API / Portal
                              │
          ┌───────────────────┼────────────────────┐
          │                   │                    │
      Identity             Billing             Quotas
          │                   │                    │
          └───────────────────┼────────────────────┘
                              │
                         Cluster API
                              │
              ┌───────────────┼─────────────────┐
              │                                 │
          Kamaji HCP                    Infrastructure
              │                           Providers
              │                                 │
              ▼                                 ▼
       Hosted Control Plane               Worker Nodes
              │                                 │
              └───────────────┬─────────────────┘
                              │
                       Customer Cluster
```

### Why this architecture?

Because it separates responsibilities cleanly:

| Layer                    | Responsibility                  |
| ------------------------ | ------------------------------- |
| KaaS API                 | Customer-facing service         |
| Identity                 | Authentication/authorization    |
| Billing                  | Consumption                     |
| Quotas                   | Resource control                |
| Cluster API              | Cluster lifecycle abstraction   |
| Kamaji                   | Hosted Kubernetes control plane |
| Infrastructure providers | VM/network/storage              |
| Kubernetes               | Customer workload platform      |

This also gives you the option to replace components later.

For example:

```text
Kamaji
   ↓
Another HCP provider
```

or:

```text
CAPI infrastructure provider
   ↓
Another infrastructure provider
```

without redesigning the entire platform.

---

# 27. Final Recommendation

## Overall ranking by use case

| Goal                                    | Recommended              |
| --------------------------------------- | ------------------------ |
| Generic Kubernetes lifecycle automation | **Cluster API**          |
| Hosted control plane building block     | **Kamaji**               |
| Build-your-own KaaS                     | **Cluster API + Kamaji** |
| Large-scale multi-cloud KaaS            | **Gardener**             |
| Ready-made KaaS platform                | **KKP**                  |
| OpenShift hosted control plane          | **HyperShift**           |

### Best for Hosted Control Plane

**Kamaji, Gardener, KKP and HyperShift** are all strong HCP choices, but for different purposes.

For **upstream Kubernetes + custom platform engineering**, I would favor:

> **Kamaji + Cluster API**

For **large-scale, mature, multi-cloud KaaS**, I would favor:

> **Gardener**

For **a more complete platform/product with substantial management functionality already included**, I would favor:

> **KKP**

For **OpenShift**, I would favor:

> **HyperShift**

### Best overall for a new generic managed Kubernetes service

If the organization has a strong platform engineering team and wants to **own the architecture and product**, my recommendation would be:

> **Cluster API + Kamaji + your own KaaS control plane**

If the goal is to **adopt rather than build**, I would evaluate:

> **Gardener vs KKP**

first.

---

# 28. Decision Matrix

| Requirement                  |      CAPI |    Kamaji |  Gardener |          KKP |    HyperShift |
| ---------------------------- | --------: | --------: | --------: | -----------: | ------------: |
| Generic Kubernetes           |     ★★★★★ |     ★★★★★ |     ★★★★★ |        ★★★★★ |            ★★ |
| HCP                          |       ★★★ |     ★★★★★ |     ★★★★★ |        ★★★★★ |         ★★★★★ |
| Build custom KaaS            |     ★★★★★ |     ★★★★★ |      ★★★★ |          ★★★ |           ★★★ |
| Complete KaaS                |        ★★ |       ★★★ |     ★★★★★ |        ★★★★★ |          ★★★★ |
| Multi-cloud                  |     ★★★★★ |     ★★★★★ |     ★★★★★ |        ★★★★★ |          ★★★★ |
| On-prem                      |     ★★★★★ |     ★★★★★ |     ★★★★★ |        ★★★★★ |          ★★★★ |
| Edge                         |      ★★★★ |     ★★★★★ |      ★★★★ |        ★★★★★ |          ★★★★ |
| Multi-tenancy                |        ★★ |      ★★★★ |     ★★★★★ |        ★★★★★ |          ★★★★ |
| User portal                  |     Build |     Build | Available |       Strong |        Strong |
| Platform customization       |     ★★★★★ |     ★★★★★ |      ★★★★ |          ★★★ |           ★★★ |
| Operational simplicity       |      ★★★★ |      ★★★★ |        ★★ |          ★★★ |           ★★★ |
| Ecosystem                    |     ★★★★★ |      ★★★★ |      ★★★★ |         ★★★★ |          ★★★★ |
| Vendor/platform independence |     ★★★★★ |     ★★★★★ |      ★★★★ |          ★★★ |            ★★ |
| Best fit                     | Lifecycle | HCP layer |      KaaS | KaaS product | OpenShift HCP |

---

# 29. Conclusion

The evolution can be summarized as:

```text
Traditional Kubernetes
        │
        ▼
Automated Kubernetes
        │
        │  Cluster API
        ▼
Hosted Control Plane
        │
        │  Kamaji / HyperShift
        │
        ▼
Kubernetes-as-a-Service
        │
        │  Gardener / KKP
        ▼
Full Managed Kubernetes Platform
        │
        ├── Identity
        ├── Billing
        ├── Quotas
        ├── Networking
        ├── Security
        ├── Observability
        ├── Backup
        ├── Lifecycle
        ├── Multi-tenancy
        └── Customer Portal/API
```

The most important architectural conclusion is that **Cluster API, Kamaji, Gardener, KKP and HyperShift should not be viewed as five interchangeable products**.

They occupy different layers of the Kubernetes management ecosystem.

**Cluster API** provides a standardized lifecycle foundation.

**Kamaji** provides a lightweight upstream-Kubernetes hosted-control-plane layer.

**Gardener** provides a complete Kubernetes-as-a-Service architecture.

**KKP** provides a complete Kubernetes management/KaaS platform with a strong operational and UI layer.

**HyperShift** provides a large-scale hosted-control-plane architecture primarily for OpenShift.

For a new **generic managed Kubernetes service**, the most strategically interesting architecture is therefore:

> **KaaS Platform Layer + Cluster API + Hosted Control Plane + Infrastructure Providers**

and **Cluster API + Kamaji** is an especially attractive composable foundation when the platform itself is going to be developed and controlled internally.

### Primary references

* [Cluster API documentation](https://cluster-api.sigs.k8s.io/?utm_source=chatgpt.com)
* [Kamaji documentation](https://kamaji.clastix.io/?utm_source=chatgpt.com)
* [Gardener documentation](https://gardener.cloud/docs/gardener/?utm_source=chatgpt.com)
* [KKP documentation](https://docs.kubermatic.com/kubermatic/?utm_source=chatgpt.com)
* [HyperShift project](https://github.com/openshift/hypershift?utm_source=chatgpt.com)
