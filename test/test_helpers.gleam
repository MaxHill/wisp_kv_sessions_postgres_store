import pog
import wisp_kv_sessions/postgres_store

pub fn new_db() {
  let assert Ok(config) =
    pog.url_config(
      "postgres://postgres:mySuperSecretPassword!@localhost:5432/postgres?sslmode=disable",
    )
  let db = pog.connect(pog.Config(..config, pool_size: 1))
  let assert Ok(_) = postgres_store.migrate_down(db)
  let assert Ok(_) = postgres_store.migrate_up(db)
  db
}
