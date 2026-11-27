# PostgreSQL on Minikube with Kustomize

## Layout

- `infrastructure/base/` defines the PostgreSQL 16 StatefulSet and ClusterIP
  Service.
- `infrastructure/overlays/dev/` installs into the `dev` namespace.
- `infrastructure/overlays/prod/` installs into the `prod` namespace.
- `infrastructure/scripts/load-data.sh` creates the schema and loads all five
  CSV files.

The Kubernetes base mirrors the PostgreSQL image, database environment, port,
health check, and persistent storage in `docker-compose.yaml`. Docker's
`./data` and `./sql` bind mounts are not host-mount dependencies in Kubernetes;
the data loader streams the repository files into `psql` with `kubectl exec`.

## Prerequisites

Install:

- Docker
- Minikube
- `kubectl`

Use a Docker driver for this local setup:

```bash
minikube start --driver=docker
```

## Deploy development

From the repository root:

```bash
kubectl apply -k infrastructure/overlays/dev
kubectl -n dev rollout status statefulset/postgres --timeout=5m
```

## Create tables and load the CSV files

**Warning:** `sql/schema.sql` drops and recreates the five tables. Running the
loader again destroys their existing data before importing the CSVs.

```bash
chmod +x infrastructure/scripts/load-data.sh
./infrastructure/scripts/load-data.sh dev
```

The script runs `sql/schema.sql`, then loads these files:

| CSV file | PostgreSQL table |
|---|---|
| `data/customers.csv` | `customers` |
| `data/products.csv` | `products` |
| `data/orders.csv` | `orders` |
| `data/order_items.csv` | `order_items` |
| `data/events.csv` | `events` |

The events import is intentionally the slowest because it contains about ten
million rows.

## Verify

```bash
kubectl -n dev exec postgres-0 -- \
  psql -U ds_candidate -d ecommerce -c \
  "SELECT 'customers' AS table_name, count(*) FROM customers
   UNION ALL SELECT 'products', count(*) FROM products
   UNION ALL SELECT 'orders', count(*) FROM orders
   UNION ALL SELECT 'order_items', count(*) FROM order_items
   UNION ALL SELECT 'events', count(*) FROM events;"
```

Expected counts are 50,000 customers, 2,000 products, 500,000 orders,
approximately 1.53 million order items, and approximately 10 million events.

## Connect a Kubeflow component

Inside the `dev` namespace, use:

```text
postgresql://ds_candidate:ds_candidate_pw@postgres.dev.svc.cluster.local:5432/ecommerce
```

Inside Minikube, from another namespace, the same fully qualified service name
works. From the local machine:

```bash
kubectl -n dev port-forward service/postgres 5432:5432
```

Then connect to `localhost:5432`.

## Deploy the production-shaped environment

```bash
kubectl apply -k infrastructure/overlays/prod
kubectl -n prod rollout status statefulset/postgres --timeout=5m
```

To load the same sample data into that local environment:

```bash
./infrastructure/scripts/load-data.sh prod
```

The `prod` overlay is for a local production-shaped namespace, not a
production security configuration. Before a real production deployment, replace
the checked-in development credentials with a secret manager, restrict network
access, configure backups, and use an appropriately sized managed or replicated
database.
