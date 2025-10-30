CREATE TABLE IF NOT EXISTS upload_tokens (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL UNIQUE,
    document_type VARCHAR(50) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_upload_tokens_token ON upload_tokens(token);
CREATE INDEX idx_upload_tokens_expires ON upload_tokens(expires_at);