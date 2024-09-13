import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/pgo
import gleam/result
import wisp
import wisp_kv_sessions/internal
import wisp_kv_sessions/session
import wisp_kv_sessions/session_config

pub fn try_create_session_store(db: pgo.Connection) {
  session_config.SessionStore(
    default_expiry: 60 * 60,
    get_session: get_session(db),
    save_session: save_session(db),
    delete_session: delete_session(db),
  )
}

pub fn migrate_up(db: pgo.Connection) {
  let sql =
    "
    CREATE TABLE IF NOT EXISTS wisp_kv_sessions (
      session_id VARCHAR PRIMARY KEY,
      expires_at TIMESTAMP NOT NULL,
      data JSON
    );
    "

  pgo.execute(sql, db, [], fn(_) { Ok(Nil) })
}

pub fn migrate_down(db: pgo.Connection) {
  let sql = "DROP TABLE IF EXISTS wisp_kv_sessions"
  pgo.execute(sql, db, [], fn(_) { Ok(Nil) })
}

fn get_session(db: pgo.Connection) {
  fn(session_id: session.SessionId) {
    let sql =
      "
      SELECT session_id, expires_at, data from wisp_kv_sessions
      WHERE session_id = $1;
      "
    use returned <- result.try(
      pgo.execute(
        sql,
        db,
        [pgo.text(session.id_to_string(session_id))],
        internal.decode_session_row,
      )
      |> result.map_error(fn(err) {
        io.debug(err)
        wisp.log_error(
          "Could not get session" <> session.id_to_string(session_id),
        )
        session.DbErrorGetError(
          "Could not get session with id"
          <> session.id_to_string(session_id)
          <> " from database",
        )
      }),
    )

    returned.rows
    |> list.first
    |> option.from_result
    |> option.map(fn(row) {
      use data <- result.map(
        internal.decode_data_from_string(row.2)
        |> result.map_error(fn(err) {
          io.debug(err)
          session.DeserializeError("Could not deserialize data")
        }),
      )

      session.Session(
        id: session.id_from_string(row.0),
        expires_at: row.1,
        data: data,
      )
    })
    |> fn(r) {
      case r {
        option.Some(Ok(v)) -> Ok(option.Some(v))
        option.Some(Error(e)) -> Error(e)
        option.None -> Ok(option.None)
      }
    }
  }
}

fn save_session(db: pgo.Connection) {
  fn(new_session: session.Session) {
    let sql =
      "
        INSERT INTO wisp_kv_sessions (session_id, expires_at, data)
        VALUES ($1, $2, $3)
        ON CONFLICT (session_id)
        DO UPDATE SET
            session_id = EXCLUDED.session_id,
            data = EXCLUDED.data,
            expires_at = EXCLUDED.expires_at;
      "

    // io.debug(birl.to_erlang_datetime(new_session.expires_at))
    let insert =
      pgo.execute(
        sql,
        db,
        [
          pgo.text(session.id_to_string(new_session.id)),
          pgo.timestamp(new_session.expires_at),
          pgo.text(json.to_string(internal.encode_data(new_session.data))),
        ],
        fn(_) { Ok(Nil) },
      )

    case insert {
      Ok(_) -> Ok(new_session)
      Error(err) -> {
        io.debug(err)
        wisp.log_error("Could not insert new session")
        Error(session.DbErrorInsertError("Could not insert new session"))
      }
    }
  }
}

fn delete_session(db: pgo.Connection) {
  fn(session_id: session.SessionId) {
    let sql =
      "
    DELETE FROM wisp_kv_sessions
    WHERE session_id = $1
    "

    case
      pgo.execute(sql, db, [pgo.text(session.id_to_string(session_id))], fn(_) {
        Ok(Nil)
      })
    {
      Ok(_) -> Ok(Nil)
      Error(err) -> {
        io.debug(err)
        wisp.log_error(
          "Could not delete session with id" <> session.id_to_string(session_id),
        )
        Error(session.DbErrorDeleteError(
          "Could not delete session with id" <> session.id_to_string(session_id),
        ))
      }
    }
  }
}
