DROP TABLE IF EXISTS cari_hesaplar;
DROP ROLE IF EXISTS pix2pi_app;

CREATE TABLE cari_hesaplar (
    hesap_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    kod TEXT NOT NULL,
    unvan TEXT NOT NULL
);

INSERT INTO cari_hesaplar VALUES
('cari-001','tenant-001','120.01.001','Ali Market'),
('cari-002','tenant-002','120.01.002','Akdeniz Gida');

ALTER TABLE cari_hesaplar ENABLE ROW LEVEL SECURITY;
ALTER TABLE cari_hesaplar FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON cari_hesaplar;

CREATE POLICY tenant_isolation_policy
ON cari_hesaplar
FOR SELECT
USING (tenant_id = current_setting('app.tenant_id', true));

CREATE ROLE pix2pi_app LOGIN PASSWORD 'pix2pi_app_123';
GRANT SELECT ON cari_hesaplar TO pix2pi_app;
