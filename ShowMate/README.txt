Contributions:

Nick Favoriti (25%)
    - Created login button on the settings page
    - Wrote a function that would change username
    - Wrote function for creating a new user and added button
    - Wrote function for sign in button and added the button
Ashley Settle (25%)
    - Created the firebase and the functionality of the sign in and create account
    - Created the database for the firebase to enable extra features like privacy and username
    - Added the ability to create a username and change username for the account
    - Created the storyboard for the friends page
Victoria Plaxton (25%)
    - Created TVShow class with attributes for fetched data
    - Wrote a function for handling user search (fetches titles and poster urls for results matching entered strings, and forms basic TVShow objects)
    - Wrote a function that will be called when a user selects a presented search result. It fetches a full set of show info from TMDB, creating a fully filled-in TVShow object)
Sydney Schrader (25%)
    - Created the code base, basic screens, and segues between them
    - Created the tab bar controller between all the pages
    - Wrote code for keeping the user logged in and their current username on every screen, and making sure there was no user logged in when the app launched
    - Wrote code for the carousel view of the shows on the feed and shows page

Differences:
-   We no longer plan to have a groups option, which is a large deviation from our original idea. We think it is more realistic to focus on friends, given our short timeline. There will not be group-specific status messages, a user’s messages are shared with all their friends.

-   We did not create the Watched List/Wish List (using just one list right now for simplicity) and we didn’t display status message of groupmates/friends.

-   We prioritized the TV show backend over the front end. Before building out the design, we wanted to ensure that the features we included in our TV Show page were feasible. As a result, we will do more of the work on the TV show design for our Beta release and have finished the API work early.

-   We changed our method for adding something to your list. Instead of having a plus sign next to each list to add to that list, the user will only be able to add to their lists from the search bar (results pop up, with three dots on each result, click dots for add to list / remove from list options). The functionality for this will be done in the next release.


