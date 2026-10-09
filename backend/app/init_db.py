"""Create tables on Neon: `python -m app.init_db` (or run schema.sql in the Neon SQL editor)."""
from .database import Base, engine
from . import models  # noqa: F401

Base.metadata.create_all(engine)
print("Tables ready.")
