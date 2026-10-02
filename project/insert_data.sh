#!/bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Start clean so reruns always give 24 teams and 32 games
$PSQL "TRUNCATE games, teams RESTART IDENTITY" > /dev/null

# "|| [[ -n $YEAR ]]" processes the last line even if the file has no trailing newline
while IFS="," read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS || [[ -n $YEAR ]]
do
  # strip any Windows carriage return
  OPPONENT_GOALS=${OPPONENT_GOALS%$'\r'}

  if [[ $YEAR != "year" ]]
  then
    # insert teams (ON CONFLICT keeps them unique, no extra lookup needed)
    $PSQL "INSERT INTO teams(name) VALUES('${WINNER//\'/\'\'}') ON CONFLICT (name) DO NOTHING" > /dev/null
    $PSQL "INSERT INTO teams(name) VALUES('${OPPONENT//\'/\'\'}') ON CONFLICT (name) DO NOTHING" > /dev/null

    # look up the real IDs (nothing hard-coded)
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='${WINNER//\'/\'\'}'")
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='${OPPONENT//\'/\'\'}'")

    $PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)" > /dev/null
  fi
done < games.csv