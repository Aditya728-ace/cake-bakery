-- Reference schema for Neon PostgreSQL (SQLAlchemy models create the same tables).
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE bakery_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(120) NOT NULL,
  tagline VARCHAR(200),
  email VARCHAR(255),
  phone VARCHAR(30),
  whatsapp_number VARCHAR(20),          -- digits only, with country code e.g. 919876543210
  address TEXT,
  logo_url TEXT,
  logo_public_id VARCHAR(255),
  social_links JSONB NOT NULL DEFAULT '{}',  -- {"instagram": "...", "facebook": "..."}
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE cakes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES bakery_profiles(id) ON DELETE CASCADE,
  slug VARCHAR(160) NOT NULL UNIQUE,
  title VARCHAR(140) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  ingredients JSONB NOT NULL DEFAULT '[]',
  price NUMERIC(10,2),                  -- optional
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_cakes_published ON cakes (is_published, created_at DESC);

CREATE TABLE cake_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cake_id UUID NOT NULL REFERENCES cakes(id) ON DELETE CASCADE,
  url TEXT NOT NULL,                    -- file lives in Cloudinary, not in the DB
  public_id VARCHAR(255) NOT NULL,
  width INT, height INT,
  position INT NOT NULL DEFAULT 0,
  is_cover BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_cake_images_cake ON cake_images (cake_id, position);

CREATE TABLE site_content (            -- editable website copy (key/value)
  key VARCHAR(60) PRIMARY KEY,
  value TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
