#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=periodic_table --tuples-only -c "

function SET_FIRST_SYMBOL_CHARACTER_TO_UPPERCASE() {
  ELEMENTS=$($PSQL "SELECT symbol FROM elements;" | sed 's/ //')
  for RAW_ELEMENT in $ELEMENTS; do
    # make first character uppercase
    ELEMENT=$(echo $RAW_ELEMENT | sed 's/./\U&/')
    # set first character from symbol to uppercase in the database
    $PSQL "UPDATE elements SET symbol='$ELEMENT' WHERE symbol='$RAW_ELEMENT';"
  done
}

function SET_ATOMIC_MASS_CORRECT_FORMAT() {
  ATOMIC_MASSES=$($PSQL "SELECT atomic_mass FROM properties;" | sed 's/ //')
  for RAW_ATOMIC_MASS in $ATOMIC_MASSES; do
    # make first character uppercase
    ATOMIC_MASS=$(echo $RAW_ATOMIC_MASS | sed 's/0*$//g')
    # set first character from symbol to uppercase in the database
    $PSQL "UPDATE properties SET atomic_mass='$ATOMIC_MASS' WHERE atomic_mass='$RAW_ATOMIC_MASS';"
  done
}

# make a function that sets the properties type id based on the types table

function DISPLAY_INFORMATION() {
  OUTPUT=$(echo $1 | sed 's/ //g')
  if [[ -z $OUTPUT ]]; then
    echo I could not find that element in the database.
    exit
  fi
  IFS='|' read ATOMIC_NUMBER NAME TYPE SYMBOL ATOMIC_MASS MELTING_POINT BOILING_POINT <<< "$OUTPUT"
  echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $ATOMIC_MASS amu. $NAME has a melting point of $MELTING_POINT celsius and a boiling point of $BOILING_POINT celsius."
}

# only first time
# SET_ATOMIC_MASS_CORRECT_FORMAT
# SET_FIRST_SYMBOL_CHARACTER_TO_UPPERCASE

if [[ $# -eq 0 ]]; then
 echo Please provide an element as an argument.
else
  if [[ $1 =~ ^[0-9]+$ ]]; then
    OUTPUT=$($PSQL "SELECT atomic_number, name, type, symbol, atomic_mass, melting_point_celsius, boiling_point_celsius FROM elements INNER JOIN properties USING(atomic_number) INNER JOIN types USING(type_id) WHERE atomic_number=$1")
    DISPLAY_INFORMATION "$OUTPUT"
  elif [[ "${#1}" -eq 1 || "${#1}" -eq 2 ]]; then
    OUTPUT=$($PSQL "SELECT atomic_number, name, type, symbol, atomic_mass, melting_point_celsius, boiling_point_celsius FROM elements INNER JOIN properties USING (atomic_number) INNER JOIN types USING(type_id) WHERE symbol='$1'")
    DISPLAY_INFORMATION "$OUTPUT"
  else
    OUTPUT=$($PSQL "SELECT atomic_number, name, type, symbol, atomic_mass, melting_point_celsius, boiling_point_celsius FROM elements INNER JOIN properties USING (atomic_number) INNER JOIN types USING(type_id) WHERE name='$1'")
    DISPLAY_INFORMATION "$OUTPUT"
  fi
fi
