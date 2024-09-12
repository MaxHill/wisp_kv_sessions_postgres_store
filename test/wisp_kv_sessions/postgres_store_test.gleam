import gleam/dict
import gleam/dynamic
import gleam/json
import gleeunit/should
import test_helpers
import wisp_kv_sessions/postgres_store
import wisp_kv_sessions/session

pub fn set_get_session_test() {
  let db = test_helpers.new_db()
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
  let db = test_helpers.new_db()
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
