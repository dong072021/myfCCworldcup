#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
echo $($PSQL "TRUNCATE TABLE games, teams")
#
cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
    # Skip the header row
    if [[ "$YEAR" == "year" ]]; then
        continue
    fi

    # Insert teams into the teams table if they don't already exist
    # Insert winner team if not already in the teams table
    INSERT_WINNER_RESULT=$($PSQL "INSERT INTO teams (name) 
                                SELECT '$WINNER' 
                                WHERE NOT EXISTS (SELECT 1 FROM teams WHERE name = '$WINNER')")
    
    # Insert opponent team if not already in the teams table
    INSERT_OPPONENT_RESULT=$($PSQL "INSERT INTO teams (name) 
                                  SELECT '$OPPONENT' 
                                  WHERE NOT EXISTS (SELECT 1 FROM teams WHERE name = '$OPPONENT')")
done

# After inserting unique teams, insert the game results into the games table
cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
    # Skip the header row
    if [[ "$YEAR" == "year" ]]; then
        continue
    fi

    # Get team_id for winner and opponent from the teams table
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name = '$WINNER'")
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name = '$OPPONENT'")

    # Insert the game result into the games table
    INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) 
    VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)")

    # Check if the insert was successful (optional)
    if [[ $? -eq 0 ]]; then
        echo "Inserted game: $YEAR $ROUND - $WINNER vs $OPPONENT"
    else
        echo "Error inserting game: $YEAR $ROUND - $WINNER vs $OPPONENT"
    fi
done