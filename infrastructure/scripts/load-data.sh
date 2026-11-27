#!/usr/bin/env bash

set -euo pipefail

environment="${1:-dev}"
case "$environment" in
  dev|prod)
    ;;
  *)
    echo "Usage: $0 [dev|prod]" >&2
    exit 1
    ;;
esac

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pod="$(kubectl -n "$environment" get pod -l app.kubernetes.io/name=postgres -o jsonpath='{.items[0].metadata.name}')"

kubectl -n "$environment" wait --for=condition=Ready "pod/$pod" --timeout=300s

echo "Creating tables from sql/schema.sql..."
kubectl -n "$environment" exec -i "$pod" -- \
  psql -v ON_ERROR_STOP=1 -U ds_candidate -d ecommerce \
  < "$repository_root/sql/schema.sql"

for table in customers products orders order_items events; do
  echo "Loading data/$table.csv into $table..."
  kubectl -n "$environment" exec -i "$pod" -- \
    psql -v ON_ERROR_STOP=1 -U ds_candidate -d ecommerce \
    -c "\copy $table FROM STDIN WITH (FORMAT csv, HEADER true, NULL '')" \
    < "$repository_root/data/$table.csv"
done

echo "Loaded row counts:"
kubectl -n "$environment" exec "$pod" -- \
  psql -v ON_ERROR_STOP=1 -U ds_candidate -d ecommerce -c \
  "SELECT 'customers' AS table_name, count(*) FROM customers
   UNION ALL SELECT 'products', count(*) FROM products
   UNION ALL SELECT 'orders', count(*) FROM orders
   UNION ALL SELECT 'order_items', count(*) FROM order_items
   UNION ALL SELECT 'events', count(*) FROM events;"
