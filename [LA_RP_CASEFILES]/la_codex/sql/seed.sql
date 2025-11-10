-- Example SQL seed for Los Animales RP codex.
-- Replace or extend with your own schema and data.
CREATE TABLE IF NOT EXISTS la_example (
    id INT PRIMARY KEY,
    description VARCHAR(255) NOT NULL
);

INSERT INTO la_example (id, description) VALUES
    (1, 'Los Animales initial record')
ON DUPLICATE KEY UPDATE description = VALUES(description);