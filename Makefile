# Single host entry point. All real work happens inside the devcontainer.
#
#   make cluster    create the k3d cluster (idempotent)
#   make dev        cluster + tilt up (your inner loop; opens UI at :10350)
#   make stop       stop the cluster (keeps state)
#   make nuke       delete the cluster and its registry
#
# Run from inside the devcontainer ("Reopen in Container" in VS Code).

CLUSTER := sol-arch
KUBECTX := k3d-$(CLUSTER)

.PHONY: cluster dev stop nuke kubeconfig

cluster:
	@k3d cluster list $(CLUSTER) >/dev/null 2>&1 \
	  || k3d cluster create --config infra/k3d/cluster.yaml
	@kubectl config use-context $(KUBECTX) >/dev/null

dev: cluster
	tilt up

stop:
	k3d cluster stop $(CLUSTER)

nuke:
	k3d cluster delete $(CLUSTER)

kubeconfig:
	@k3d kubeconfig get $(CLUSTER)
