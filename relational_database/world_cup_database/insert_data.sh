#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

function has_space() {
  # return true if the argument is with this syntax "text space text"
  # false otherwise
  if [[ $1 =~ ^[a-zA-Z]+[[:space:]][a-zA-Z+$] ]]; then
      return 0
  fi
  return 1
}

GAME_LIST=()
CSV_DATA_FILE="games.csv"
echo "$($PSQL "TRUNCATE games, teams CASCADE")"

# reading the games from csv and storing them in an array 

while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS;
do
  if [[ $YEAR == "year" ]]; then continue; fi
    IFS="|"
    # echo "$ROUND|$WINNER|$OPPONENT"
    if has_space $ROUND; then
      ROUND="$(echo "$ROUND" | tr " " "*")"
    fi
    if has_space $OPPONENT; then
      OPPONENT="$(echo "$OPPONENT" | tr " " "*")"
    fi
    if has_space $WINNER; then
      WINNER="$(echo "$WINNER" | tr " " "*")"
    fi
    GAME="$YEAR '$ROUND' '$WINNER' '$OPPONENT' $WINNER_GOALS $OPPONENT_GOALS"
    GAME_LIST+=("$GAME")
done < $CSV_DATA_FILE

# insert countries to the table teams

IFS="|"
for GAME in ${GAME_LIST[*]}; do
  IFS=" "
  WINNER_COUNTRY="$(echo "$GAME" | awk '{print $3}' | tr "*" " ")"
  LOOSER_COUNTRY="$(echo "$GAME" | awk '{print $4}' | tr "*" " ")"
  TEAM_ID_WINNER="$($PSQL "SELECT team_id FROM teams WHERE name=$WINNER_COUNTRY";)"
  TEAM_ID_LOOSER="$($PSQL "SELECT team_id FROM teams WHERE name=$LOOSER_COUNTRY";)"
  # if the winner is not in the list of countries add it
  if [[ -z $TEAM_ID_WINNER ]]; then
    RESULT=$($PSQL "INSERT INTO teams(name) VALUES($WINNER_COUNTRY)");
    if [[ $RESULT = "INSERT 0 1" ]]; then
      echo "Inserted $WINNER_COUNTRY"
    fi
  fi
  # if the looser is not in the list of countries add it
  if [[ -z $TEAM_ID_LOOSER ]]; then
    RESULT=$($PSQL "INSERT INTO teams(name) VALUES($LOOSER_COUNTRY)");
    if [[ $RESULT = "INSERT 0 1" ]]; then
      echo "Inserted $LOOSER_COUNTRY"
    fi
  fi
done

# insert matches to the table games

IFS="|"
for GAME in ${GAME_LIST[*]}; do
  IFS=" "
  YEAR="$(echo "$GAME" | awk '{print $1}' | tr "*" " ")"
  ROUND="$(echo "$GAME" | awk '{print $2}' | tr "*" " ")"
  WINNER_COUNTRY="$(echo "$GAME" | awk '{print $3}' | tr "*" " ")"
  LOOSER_COUNTRY="$(echo "$GAME" | awk '{print $4}' | tr "*" " ")"
  WINNER_ID="$($PSQL "SELECT team_id FROM teams WHERE name=$WINNER_COUNTRY";)"
  LOOSER_ID="$($PSQL "SELECT team_id FROM teams WHERE name=$LOOSER_COUNTRY";)"
  WINNER_GOALS="$(echo "$GAME" | awk '{print $5}' | tr "*" " ")"
  LOOSER_GOALS="$(echo "$GAME" | awk '{print $6}' | tr "*" " ")"
  GAME_ID=$($PSQL "SELECT game_id FROM games WHERE year=$YEAR AND winner_id=$WINNER_ID AND opponent_id=$LOOSER_ID;")
  if [[ -z $GAME_ID ]]; then
    QUERY="INSERT INTO games(year, winner_id, opponent_id, winner_goals, opponent_goals, round)"
    QUERY+=" VALUES($YEAR, $WINNER_ID, $LOOSER_ID, $WINNER_GOALS, $LOOSER_GOALS, $ROUND);"
    echo $($PSQL "$QUERY")
  fi
done