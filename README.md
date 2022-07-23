# MySQL Word Cup Simulator

:warning: **Warning: only for true SQL connoisseurs.**

:dizzy_face: A crazy SQL experiment in simulating a single-elimination tournament.

A real algorithm written entirely in SQL which, starting from a list of teams, draws the teams into pairs of challengers, assigns them a random result, eliminates the losing teams and continues until there is only one winner.

The stored procedure intentionally contains all the simulation logic, so as to regenerate new results by issuing a single command.

``` sql
CALL simulate();
```

The result is a summary of the total goals scored, goals conceded and goal difference for each team throughout the tournament.

Tested and working on MySQL 8.

:star: **If you liked what I did, if it was useful to you or if it served as a starting point for something more magical let me know with a star** :green_heart:
