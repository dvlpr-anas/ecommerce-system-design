# Sealed Secrets

## Purpose

GitOps-compatible secret management: encrypt secrets so they can be committed to Git, and have an in-cluster controller decrypt them into native `Secret` objects. Removes the "secrets in env vars" anti-pattern (design-doc §9.4) without standing up Vault.

## Inputs / Prerequisites

- `kubernetes-baseline.md` complete (cluster + `platform` namespace exist)
- `kubeseal` CLI installed locally

## Tasks

1. [ ] Install Bitnami Sealed Secrets controller via Helm into `platform` namespace — effort: S
2. [ ] Back up the controller's private key out-of-band (1Password, AWS Secrets Manager) — losing this key means re-encrypting every secret — effort: S
3. [ ] Document the workflow in `infra/secrets/README.md`: `kubectl create secret … --dry-run=client -o yaml | kubeseal --controller-name=sealed-secrets -o yaml > sealed.yaml` — effort: S
4. [ ] Commit a sample sealed secret (`infra/secrets/sample.sealed.yaml`) and a corresponding `SealedSecret` manifest under `k8s-manifests/base/secrets/` — effort: S
5. [ ] Define key rotation policy: rotate annually, controller supports multiple active keys during rotation window — effort: S
6. [ ] CI lint: reject any unencrypted `Secret` resource in `k8s-manifests/` (use `kubeconform` + a custom check) — effort: M

## Deliverables

- Sealed Secrets controller running in `platform`
- `infra/secrets/README.md` with the encryption workflow
- Sample sealed secret round-trips correctly
- CI guard against unencrypted `Secret` manifests

## Exit Criteria

- [ ] `kubectl apply -f infra/secrets/sample.sealed.yaml` produces a `Secret` in the cluster
- [ ] `kubectl get secret sample -o jsonpath='{.data.value}' | base64 -d` returns the original plaintext
- [ ] Committing a raw `Secret` resource to `k8s-manifests/` fails CI
- [ ] Key backup procedure documented and tested (restore on a throwaway cluster)

## References

- Design doc: §9.4 Security Hardening (Secrets row)
- ADR-007 Observability (Secrets adjacent)

## Risks & Open Questions

- Sealed Secrets locks secrets to a single cluster's key. For multi-cluster (dev + staging + prod), need separate sealed copies per cluster. Document this in the workflow.
- Long-term, consider migrating to External Secrets Operator backed by AWS Secrets Manager / GCP Secret Manager if secret count exceeds ~50. Track as a future ADR.
