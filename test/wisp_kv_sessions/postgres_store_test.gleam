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
