CREATE TABLE IF NOT EXISTS tournaments (
  id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  name VARCHAR (255) UNIQUE NOT NULL CONSTRAINT name_not_blank CHECK (length(name) > 0),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  CONSTRAINT end_date_after_start_date CHECK (ends_at > starts_at)

);

CREATE TABLE IF NOT EXISTS leagues (
  id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  name VARCHAR (255) UNIQUE NOT NULL,
  tournament_id INT NOT NULL REFERENCES tournaments ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS countries (
  id VARCHAR (3) PRIMARY KEY,
  code VARCHAR (2) UNIQUE NOT NULL,
  name VARCHAR (255) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS tournament_groups (
  id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  name VARCHAR (1) NOT NULL,
  tournament_id INT NOT NULL REFERENCES tournaments ON DELETE CASCADE,
  finished BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (tournament_id, name)  -- A group can only exist once in a tournament
);

CREATE TABLE IF NOT EXISTS tournament_participants (
  id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  tournament_id INT REFERENCES tournaments ON DELETE CASCADE,
  group_id INT REFERENCES tournament_groups ON DELETE CASCADE,
  country_id VARCHAR (3) REFERENCES countries ON DELETE CASCADE,
  UNIQUE (tournament_id, country_id)  -- A country can only participate once in a tournament
);

CREATE TABLE IF NOT EXISTS fixtures (
  id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  tournament_id INT REFERENCES tournaments ON DELETE CASCADE,
  home_team INT REFERENCES tournament_participants ON DELETE CASCADE,
  away_team INT REFERENCES tournament_participants ON DELETE CASCADE,
  kickoff TIMESTAMPTZ NOT NULL,
  home_goals INT NOT NULL DEFAULT 0,
  away_goals INT NOT NULL DEFAULT 0,
  home_penalties INT,
  away_penalties INT,
  group_stage BOOLEAN NOT NULL DEFAULT TRUE,
  fixture_data JSONB, -- you can use this to add any additional data you want to track for the match
  UNIQUE (home_team, away_team, kickoff)  -- countries can only play each other once at the same time
);

CREATE TABLE IF NOT EXISTS users (
  id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  email VARCHAR (255) NOT NULL UNIQUE,
  password VARCHAR (255) NOT NULL,
  super_admin BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS participants (
  id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  user_id INT REFERENCES users ON DELETE CASCADE,
  league_id INT REFERENCES leagues ON DELETE CASCADE,
  role VARCHAR (255) NOT NULL DEFAULT 'PARTICIPANT',
  accepted BOOLEAN NOT NULL DEFAULT FALSE,
  primary_flag BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (user_id, league_id),  -- User can only be a participant in the same league once (but they can have many entries)
  CHECK (role IN ('PARTICIPANT', 'OWNER', 'ADMIN'))
);

CREATE TABLE IF NOT EXISTS participant_entries (
  id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  name VARCHAR (255) NOT NULL,
  participant_id INT REFERENCES participants ON DELETE CASCADE,
  league_id INT REFERENCES leagues ON DELETE CASCADE,
  paid BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (league_id, name)  -- Entry Name's have to be unique in a league
);

CREATE TABLE IF NOT EXISTS participant_entry_picks (
  id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  participant_id INT REFERENCES participants ON DELETE CASCADE,
  participant_entry_id INT REFERENCES participant_entries ON DELETE CASCADE,
  tournament_participant_id INT REFERENCES tournament_participants ON DELETE CASCADE,
  position INT NOT NULL,
  UNIQUE (participant_entry_id, position),  -- All positions in an entry have to be unique: 1, 2, 3 ... or 8
  UNIQUE (participant_entry_id, tournament_participant_id),  -- No country can be used twice in an entry
  CHECK (position IN (1, 2, 3, 4, 5, 6, 7, 8)) -- you can only have 8 entries (not sure if this Business Rule belongs in the DB but for now it is here)
);
