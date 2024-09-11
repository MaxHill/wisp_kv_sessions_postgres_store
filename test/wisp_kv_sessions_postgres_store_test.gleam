import gleam/dict
import gleam/dynamic
import gleam/json
import gleam/pgo
import gleeunit
import gleeunit/should
import wisp_kv_sessions/session
import wisp_kv_sessions_postgres_store as postgres_store

pub fn main() {
  gleeunit.main()
}

fn new_db() {
  let assert Ok(config) =
    pgo.url_config(
      "postgres://postgres:mySuperSecretPassword!@localhost:5432/postgres?sslmode=disable",
    )
  let db = pgo.connect(pgo.Config(..config, pool_size: 1))
  let assert Ok(_) = postgres_store.migrate_down(db)
  let assert Ok(_) = postgres_store.migrate_up(db)
  db
}

pub fn set_get_session_test() {
  let db = new_db()
  let session =
    session.builder()
    |> session.set_key_value("test", "hello")
    |> session.build

  let session_store = postgres_store.try_create_session_store(db)

  session_store.save_session(session)
  |> should.be_ok()
  |> should.equal(session)

  session_store.get_session(session.id)
  |> should.be_ok()
  |> should.be_some()
  |> should.equal(session)
}

pub fn set_delete_session_test() {
  let db = new_db()
  let session =
    session.builder()
    |> session.set_key_value("test", "hello")
    |> session.build

  let session_store = postgres_store.try_create_session_store(db)

  session_store.save_session(session)
  |> should.be_ok()
  |> should.equal(session)

  session_store.delete_session(session.id)
  |> should.be_ok()
  |> should.equal(Nil)

  session_store.get_session(session.id)
  |> should.be_ok()
  |> should.be_none()
}

pub fn dont_get_sessions_that_have_expired_test() {
  True |> should.be_false
}

pub fn encode_decode_data_test() {
  let data =
    dict.new()
    |> dict.insert("key_one", "value1")
    |> dict.insert(
      "key_two",
      json.to_string(json.object([#("value2.1", json.string("value2.2"))])),
    )
    |> dict.insert("key_three", "value3")

  let json = postgres_store.encode_data(data)

  json
  |> json.to_string
  |> should.equal(
    "{\"key_one\":\"value1\",\"key_three\":\"value3\",\"key_two\":\"{\\\"value2.1\\\":\\\"value2.2\\\"}\"}",
  )

  json
  |> json.to_string
  |> json.decode(dynamic.dict(dynamic.string, dynamic.string))
  |> should.be_ok
  |> dict.get("key_one")
  |> should.be_ok
  |> should.equal("value1")

  json
  |> json.to_string
  |> json.decode(dynamic.dict(dynamic.string, dynamic.string))
  |> should.be_ok
  |> dict.get("key_two")
  |> should.be_ok
  |> should.equal("{\"value2.1\":\"value2.2\"}")
}
