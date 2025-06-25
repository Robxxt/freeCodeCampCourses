#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess --tuples-only -c "
RANDOM_NUMBER=$(( $RANDOM % 1000 + 1 ))
USER_NUMBER_GUESSES=0

echo "Enter your username:"
read USERNAME

QUERY=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME';")
read USER_ID PIPE GAMES_PLAYED PIPE BEST_GAME <<< "$QUERY"
# check if user exists in the database
if [[ -z $USER_ID ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # save the user in the database
  CREATE_USER_RESULT=$($PSQL "INSERT INTO users (username) VALUES('$USERNAME');")
  if [[ $CREATE_USER_RESULT != "INSERT 0 1" ]]; then
    echo "Failed to save the user in the database: $CREATE_USER_RESULT"
    exit
  fi;
  QUERY=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME';")
  read USER_ID PIPE GAMES_PLAYED PIPE BEST_GAME <<< "$QUERY" 
else
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo "rn:$RANDOM_NUMBER"
echo "Guess the secret number between 1 and 1000:"
read USER_GUESS
if [[ ! "$USER_GUESS" =~ ^[0-9]+$ ]]; then
  echo "That is not an integer, guess again:"
  read USER_GUESS
fi

# increment the games_played counter
(( GAMES_PLAYED++ ))
# update user games_played counter in the database
UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED where user_id=$USER_ID;")
if [[ $UPDATE_RESULT != "UPDATE 1" ]]; then
  echo "Failed to update the db with the new games_played counter"
  exit
fi

while [[ true ]]; do
  (( USER_NUMBER_GUESSES++ ))
  if [[ ! "$USER_GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    read USER_GUESS
    (( USER_NUMBER_GUESSES-- ))
  elif [[ $USER_GUESS -gt $RANDOM_NUMBER ]]; then
    echo "It's lower than that, guess again:"
    read USER_GUESS
  elif [[ $USER_GUESS -lt $RANDOM_NUMBER ]]; then
    echo "It's higher than that, guess again:"
    read USER_GUESS
  else
    echo "You guessed it in $USER_NUMBER_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"
    if [[ $USER_NUMBER_GUESSES -lt $BEST_GAME || $BEST_GAME -eq 0 ]]; then
      # update best game to this one
      RESULT_UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game=$USER_NUMBER_GUESSES WHERE user_id=$USER_ID;")
      if [[ $RESULT_UPDATE_BEST_GAME != "UPDATE 1" ]]; then
        echo "Failed to update the current best game user score in the db."
        exit
      fi
    fi
    exit
  fi
done
