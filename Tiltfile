# sol-arch inner loop. Run inside the devcontainer with `make dev`.
#
# Layout:
#   - infra (postgres/redis/kafka/keycloak) as raw k8s manifests using the same
#     upstream images as the compose stack. Promotion path for phase 07:
#     CloudNativePG (postgres), Strimzi (kafka), Keycloak Operator.
#   - sol-arch-env ConfigMap projected from infra/dev/.env.dev
#   - migrations as a local_resource over port-forward (goose from mise)
#   - 8 Go services built once via Docker, then live_update'd on every edit
#   - 2 frontends (web, admin-web) as local_resource for native HMR
#
# Tilt UI: http://localhost:10350

load('ext://restart_process', 'docker_build_with_restart')

allow_k8s_contexts('k3d-sol-arch')

# ------------------------------------------------------------------ env --
# Project the shared .env.dev into a ConfigMap consumed by every service.
local_resource(
    'env-configmap',
    cmd = 'kubectl create configmap sol-arch-env --from-env-file=infra/dev/.env.dev --dry-run=client -o yaml | kubectl apply -f -',
    deps = ['infra/dev/.env.dev'],
    labels = ['infra'],
)

# ConfigMaps consumed by the postgres/keycloak manifests below. Projected from
# the same source files used by the compose stack - one source of truth.
local_resource(
    'postgres-init-configmap',
    cmd = 'kubectl create configmap postgres-init --from-file=infra/dev/postgres-init.sql --dry-run=client -o yaml | kubectl apply -f -',
    deps = ['infra/dev/postgres-init.sql'],
    labels = ['infra'],
)

local_resource(
    'keycloak-realm-configmap',
    cmd = 'kubectl create configmap keycloak-realm --from-file=realm.json=infra/dev/keycloak-realm.json --dry-run=client -o yaml | kubectl apply -f -',
    deps = ['infra/dev/keycloak-realm.json'],
    labels = ['infra'],
)

# -------------------------------------------------------- infra (raw k8s) --
k8s_yaml('infra/k3d/manifests/postgres.yaml')
k8s_resource('postgres',
    port_forwards = ['5432:5432'],
    resource_deps = ['postgres-init-configmap'],
    labels = ['infra'])

k8s_yaml('infra/k3d/manifests/redis.yaml')
k8s_resource('redis',
    port_forwards = ['6379:6379'],
    labels = ['infra'])

k8s_yaml('infra/k3d/manifests/kafka.yaml')
k8s_resource('kafka',
    port_forwards = ['29092:29092'],
    labels = ['infra'])

k8s_yaml('infra/k3d/manifests/keycloak.yaml')
k8s_resource('keycloak',
    port_forwards = ['8080:8080'],
    resource_deps = ['postgres', 'keycloak-realm-configmap'],
    labels = ['infra'])

# ----------------------------------------------------------- migrations --
# Runs against postgres via the Tilt-managed port-forward. Re-runs whenever
# any service's migrations folder changes.
local_resource(
    'migrations',
    cmd = 'task db:migrate:all',
    deps = ['services/user-service/migrations',
            'services/product-service/migrations',
            'services/pricing-service/migrations',
            'services/order-service/migrations',
            'services/inventory-service/migrations',
            'services/payment-service/migrations'],
    resource_deps = ['postgres', 'env-configmap'],
    labels = ['infra'],
    env = {
        # Override the in-cluster DSNs with the host port-forward variants.
        'USER_DATABASE_URL':      'postgres://user_svc:user_svc@localhost:5432/user_db?sslmode=disable',
        'PRODUCT_DATABASE_URL':   'postgres://product_svc:product_svc@localhost:5432/product_db?sslmode=disable',
        'PRICING_DATABASE_URL':   'postgres://pricing_svc:pricing_svc@localhost:5432/pricing_db?sslmode=disable',
        'ORDER_DATABASE_URL':     'postgres://order_svc:order_svc@localhost:5432/order_db?sslmode=disable',
        'INVENTORY_DATABASE_URL': 'postgres://inventory_svc:inventory_svc@localhost:5432/inventory_db?sslmode=disable',
        'PAYMENT_DATABASE_URL':   'postgres://payment_svc:payment_svc@localhost:5432/payment_db?sslmode=disable',
    },
)

# ------------------------------------------------------------- services --
SERVICES = [
    ('user-service',         8081),
    ('product-service',      8082),
    ('pricing-service',      8083),
    ('cart-service',         8084),
    ('order-service',        8085),
    ('inventory-service',    8086),
    ('payment-service',      8087),
    ('notification-service', 8088),
]

for name, port in SERVICES:
    docker_build_with_restart(
        ref = name + ':dev',
        context = '.',
        dockerfile = 'infra/docker/Dockerfile.go-service.dev',
        build_args = {'SERVICE': name},
        entrypoint = '/app/' + name,
        only = ['pkg/', 'services/' + name + '/'],
        live_update = [
            sync('services/' + name, '/src/services/' + name),
            sync('pkg', '/src/pkg'),
            run('cd /src/services/' + name + ' && GOWORK=off go build -o /app/' + name + ' ./cmd',
                trigger = ['services/' + name, 'pkg']),
        ],
    )
    k8s_yaml('k8s-manifests/overlays/dev/' + name + '.yaml')
    k8s_resource(
        name,
        port_forwards = port,
        resource_deps = ['migrations', 'kafka', 'keycloak', 'redis'],
        labels = ['services'],
        links = [link('http://localhost:' + str(port) + '/healthz', 'healthz')],
    )

# ------------------------------------------------------------ frontends --
local_resource(
    'web',
    serve_cmd = 'pnpm --filter web dev',
    deps = ['web/app', 'web/package.json'],
    links = ['http://localhost:3000'],
    labels = ['frontend'],
)
local_resource(
    'admin-web',
    serve_cmd = 'pnpm --filter admin-web dev',
    deps = ['admin-web/src', 'admin-web/package.json'],
    links = ['http://localhost:5173'],
    labels = ['frontend'],
)

# Mobile (Expo) is intentionally NOT wired into Tilt - it needs Xcode/Android
# Studio on the host. Run `task mobile:dev` from a host shell.
