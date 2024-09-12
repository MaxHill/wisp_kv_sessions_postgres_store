import gleam/pgo
import wisp_kv_sessions/postgres_store

pub fn new_db() {
  let assert Ok(config) =
    pgo.url_config(
      "postgres://postgres:mySuperSecretPassword!@localhost:5432/postgres?sslmode=disable",
    )
  let db = pgo.connect(pgo.Config(..config, pool_size: 1))
  let assert Ok(_) = postgres_store.migrate_down(db)
  let assert Ok(_) = postgres_store.migrate_up(db)
  db
}
