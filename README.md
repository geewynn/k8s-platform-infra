# Kubernetes Platform Infrastructure with ArgoCD

This repository contains the GitOps configuration for deploying and managing my homelab infrastructure with ArgoCD.

It uses Kustomize for managing environment-specific configurations and Argo CD for continuous deployment. The setup is structured to support multiple environments (e.g., dev and prod) from a single codebase.

The dev environment is also pre-configured with a comprehensive monitoring stack using Prometheus and Grafana.

## Current Deployment
- Kafka using Strimzi 

## Deployment Model (GitOps Flow)

This repository is designed to be used directly by Argo CD. The deployment logic is as follows:

- The **argo-apps/** directory contains the Argo CD Application definitions (e.g., dev-stack.yaml, prod-stack.yaml).

- These "App of Apps" manifests are applied to the Kubernetes cluster in the argocd namespace.

- Each Application resource points to a specific Kustomize overlay path within this repository (e.g., infrastructure/strimzi/overlays/dev).

- Argo CD monitors this Git repository. When a change is committed and pushed (e.g., to the dev overlay), Argo CD automatically detects it.

- Argo CD then runs kustomize build on the specified overlay and applies the resulting manifests to the target cluster, ensuring the cluster's state always matches the state defined in Git.


## Repository Structure

- **argo-apps/:** Contains the root Argo CD Application manifests. These are the entry points that bootstrap the environments.

- **dev-stack.yaml:** Deploys the entire "dev" environment (Strimzi Operator, Kafka Cluster, Topics, Users, Monitoring).

- **prod-stack.yaml:** Deploys the entire "prod" environment.

- **infrastructure/strimzi/base/:** Holds the common, non-environment-specific manifests for the Strimzi operator.

- **010 - 033:** ServiceAccounts, ClusterRoles, and RoleBindings required for the operator to function.

- **040 - 049:** The Strimzi Custom Resource Definitions (CRDs) (e.g., Kafka, KafkaTopic, KafkaUser).

- **060-Deployment...:** The core Strimzi Cluster Operator deployment.

- **kafka-base.yaml:** A base Kafka cluster definition, which will be patched by the overlays.

- **kafka-nodepool-base.yaml:** A base KafkaNodePool definition, used for managing dedicated pools of brokers/controllers (especially for KRaft).

- **kustomization.yaml:** Assembles all these base components.

- **infrastructure/strimzi/overlays/:** Contains the environment-specific configurations.

- **dev/:** Kustomize overlay for the development environment.

-  **patch-kafka-cluster.yaml:** Patches the kafka-base.yaml with dev-specific settings (e.g., 1 broker replica, specific storage).

- **patch-kafka-nodepool.yaml:** Configures the node pools for dev.

- **patch-operator-namespace.yaml:** Configures the Strimzi operator to watch for resources in the dev namespace.

- **topic/ & user/:** Defines KafkaTopic and KafkaUser resources specific to dev.

- **metrics/:** Contains the full monitoring stack.

- **prod/:** Kustomize overlay for the production environment. Contains patches and resources similar to dev, but configured for production needs (e.g., 3+ broker replicas, high-availability settings, different storage classes).

## Monitoring
Both environment includes a robust monitoring stack designed to integrate with a cluster-wide Prometheus Operator.

This stack, located in **infrastructure/strimzi/overlays/dev/metrics/**, consists of:

- **prometheus/pod-monitors/:** A set of PodMonitor CRs that instruct Prometheus how to discover and scrape metrics endpoints from:
    - Strimzi Cluster Operator
    - Entity Operator (Topic/User Operator)
    - Kafka Brokers (via the bundled Kafka Exporter)
    - Kafka Bridge

- **prometheus/prometheus-rules/:** A collection of PrometheusRule CRs that define critical alerts and recording rules for Kafka, such as:
    - Broker health and availability
    - Certificate expiry
    - Consumer group lag
    - Topic resource usage

- **grafana-dashboards/:** A set of JSON files for pre-built Grafana dashboards.


## How to Deploy
Prerequisites

- A Kubernetes cluster.
- kubectl and kustomize installed locally.
- Argo CD installed on your cluster.


### Deployment Steps
1. Clone this Repository

    ```sh
    git clone <your-repository-url>
    cd strimzi-gitops
    ```
2. Update Argo CD Application Repo URL Before applying, you must edit the files in `argo-apps/` to point to your Git repository.

    - Edit argo-apps/dev-stack.yaml and argo-apps/prod-stack.yaml.

    - Change the repoURL field to your repository's URL.

    - Adjust the destination.namespace and destination.server to match your cluster setup.

3. Apply the Root Applications Apply the root Argo CD applications to your cluster. This tells Argo CD to start managing your Strimzi stacks.

    ```sh
    # Apply the dev stack
    kubectl apply -f argo-apps/dev-stack.yaml
    ```
    ```sh
    # Apply the prod stack
    kubectl apply -f argo-apps/prod-stack.yaml
    ```
4. Sync in Argo CD Open your Argo CD dashboard. You will see the dev-stack and prod-stack applications. You can either wait for them to auto-sync (if enabled) or trigger a manual sync.

Once synced, Argo CD will deploy the Strimzi operator, followed by the Kafka cluster, topics, and users for each environment.

