-- Sweep policy defaults
INSERT INTO app_config (config_key, config_value)
VALUES
    ('sweep_enabled.TRON.TRX', 'true'),
    ('sweep_min_amount.TRON.TRX', '10'),
    ('sweep_enabled.TRON.USDT', 'true'),
    ('sweep_min_amount.TRON.USDT', '10'),
    ('sweep_enabled.TRON.KORI', 'true'),
    ('sweep_min_amount.TRON.KORI', '10'),
    ('sweep_enabled.TRON.F_COIN', 'true'),
    ('sweep_min_amount.TRON.F_COIN', '10'),
    ('sweep_gas_payer', 'ADMIN')
ON CONFLICT (config_key) DO NOTHING;
