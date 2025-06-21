#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

# display services
function MAIN_MENU() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  else
    echo -e "\n~~~~~ MY SALON ~~~~~\n"
    echo -e "Welcome to My Salon, how can I help you?\n"
  fi
  SERVICE_LIST=$($PSQL "SELECT * FROM services;")
  echo "$SERVICE_LIST" | while read SERVICE_ID PIPE SERVICE_NAME;
  do
    echo "$SERVICE_ID) $SERVICE_NAME "
  done
}

# ask user for service
function REQUEST_SERVICE() {
  read SERVICE_ID_SELECTED

  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED;")
  # if service doesn't exist go back to display services
  if [[ -z $SERVICE_NAME ]]; then
    MAIN_MENU "I could not find that service. What would you like today?"
    REQUEST_SERVICE
  else
    SERVICE_NAME=$(echo "$SERVICE_NAME" | sed 's/ //g')
    # if services exists
    # ask for the phone number
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';")
    # if phone doesn't exists
    if [[ -z $CUSTOMER_ID ]]; then
      # ask for the name
      echo -e "\nI don't have a record for that phone number, what's your name?"
      read CUSTOMER_NAME
      # insert customer in the database
      INSERTING_CUSTOMER=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';")
    else
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE';")
    fi
    
    # ask for time
    echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
    read SERVICE_TIME
    # make the reservation
    APPOINTMENT_INSERT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
    if [[ $APPOINTMENT_INSERT = "INSERT 0 1" ]]; then
      echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    fi
  fi
}


MAIN_MENU
REQUEST_SERVICE