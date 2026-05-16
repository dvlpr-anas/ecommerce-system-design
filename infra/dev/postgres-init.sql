-- Per-service databases and roles for local dev.
-- Each service owns its own database. No cross-database access.
-- Passwords here are dev-only. Prod credentials come from Sealed Secrets in phase 07.

CREATE ROLE user_svc      WITH LOGIN PASSWORD 'user_svc';
CREATE ROLE product_svc   WITH LOGIN PASSWORD 'product_svc';
CREATE ROLE pricing_svc   WITH LOGIN PASSWORD 'pricing_svc';
CREATE ROLE order_svc     WITH LOGIN PASSWORD 'order_svc';
CREATE ROLE inventory_svc WITH LOGIN PASSWORD 'inventory_svc';
CREATE ROLE payment_svc   WITH LOGIN PASSWORD 'payment_svc';

CREATE DATABASE user_db      OWNER user_svc;
CREATE DATABASE product_db   OWNER product_svc;
CREATE DATABASE pricing_db   OWNER pricing_svc;
CREATE DATABASE order_db     OWNER order_svc;
CREATE DATABASE inventory_db OWNER inventory_svc;
CREATE DATABASE payment_db   OWNER payment_svc;
