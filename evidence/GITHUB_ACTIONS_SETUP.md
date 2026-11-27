# Infrastructure GitHub Actions

The [infrastructure workflow](../.github/workflows/infrastructure.yaml) uses
Kustomize and the existing Minikube cluster:

| Trigger | Runner | Action |
|---|---|---|
| PR to `main` | GitHub-hosted | Render both overlays and check the loader's syntax. No deployment. |
| Push to `main`, including a merged PR | Laptop | Apply the dev overlay and wait for PostgreSQL readiness. |
| Manual dispatch on `main`, choosing `dev` or `prod` | Laptop | Apply only the selected overlay and wait for readiness. |

GitHub hosts the event scheduler; the laptop runner only executes deployment
jobs. The repository must be pushed to GitHub before these triggers can run.
PRs run on GitHub-hosted runners to keep untrusted workflow changes away from
the persistent laptop runner. Restrict write access and protect `main`; anyone
who can modify trusted workflow code can execute commands as the runner user.
A label is not a security boundary. GitHub-hosted runner usage in a private
repository is subject to the account's included minutes and billing.

## Laptop prerequisites

- Docker, Minikube, and `kubectl` are installed.
- The `minikube` kubectl context points to the intended local cluster.
- The repository runner has the `irco-minikube` label and runs as the same
  user with access to that context and Docker.
- The laptop is on, online, and the runner and Minikube are running. If the
  runner is offline, deployment jobs wait for it.

Check locally:

```bash
minikube status
kubectl --context=minikube get nodes
systemctl --user status irco-actions-runner.service
```

The user service starts when the user session's systemd manager is active.
After a reboot, sign in and start Minikube if needed. To restart the runner:

```bash
systemctl --user restart irco-actions-runner.service
```

## Manual deployment

On GitHub, open **Actions > Infrastructure > Run workflow**, select `main`,
and choose `dev` or `prod`. The prod job uses the GitHub environment named
`prod`; configure required reviewers or other deployment protection rules in
repository settings if available for your plan. Merely naming the environment
does not enable approvals.

Both deployments apply Kubernetes manifests and wait for the PostgreSQL
StatefulSet. Neither runs `load-data.sh`: that script executes a schema that
drops existing tables and must only be run deliberately. Persistent volumes
are not deleted by the workflow. Applying an unchanged PostgreSQL configuration
leaves the existing database in place; configuration changes are still applied
and may restart the pod.

This is a local demonstration, not production-grade infrastructure. The prod
overlay contains sample credentials and runs one PostgreSQL instance; real
production needs managed secrets, restricted networking, backups, and a
recovery and availability strategy. PR rendering also does not replace
cluster-side or integration testing.
