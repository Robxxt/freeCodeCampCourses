CREATE DATABASE worldcup;

# part one

// create tables

CREATE TABLE games(game_id SERIAL PRIMARY KEY, year INT NOT
NULL, winner_id INT NOT NULL, opponent_id INT NOT NULL, winner_goals INT NOT NULL, opponent_goals INT NOT NULL, round VARCHAR(60) NOT NULL);

CREATE TABLE teams(team_id SERIAL PRIMARY KEY, name VARCHAR(60) UNIQUE NOT NULL);

// set foreign keys for games table
ALTER TABLE games ADD FOREIGN KEY(opponent_id) REFERENCES teams(team_id);

ALTER TABLE games ADD FOREIGN KEY(winner_id) REFERENCES teams(team_id);

# part two

