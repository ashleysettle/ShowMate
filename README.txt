Beta Release: ShowMate (Group 2)

Contributions (Cumulative):
We feel that each member contributed 25% both for beta and cumulatively.

Nick Favoriti (25%)
- Created login button on the settings page
- Wrote a function that would change username
- Wrote function for creating a new user and added button
- Wrote function for sign in button and added the button
- Created the UserManager file which made sure that all user info was added to firebase correctly
- Worked on adding friends functionality by creating methods to send a request or add user based on whether the account is public or private
- Helped work on UI design and button functionality

Ashley Settle (25%)
- Created the firebase and the functionality of the sign in and create account 
- Created the database for the firebase to enable extra features like privacy and username
- Added the ability to create a username and change username for the account
- Created the storyboard for the friends page 
- Implemented the design on the Friends page
- Worked a lot on the UI of the page
- Worked and reworked button placement and the types of data structures used to display the data we were fetching from the firebase
- Created the tables and table view cell to view friends and search results
- Worked on the firebase to add the ability for a user to have a public/private account

Victoria Plaxton (25%)
- Created TVShow class with attributes for fetched data
- Wrote a function for handling user search (fetches titles and poster urls for results matching entered strings, and forms basic TVShow objects)
- Wrote a function that will be called when a user selects a presented search result. It fetches a full set of show info from TMDB, creating a fully filled-in TVShow object)
- Fetched additional information from TMDB including episodes per season so that status updates can become a more show-specific dropdown experience instead of just entering numbers
- Worked on cleaning and streamlining the tv code (will continue to do this since the logic is still messy, especially with the addition of the status updates)
- Researched storing user current watches / watch list in information in firebase

Sydney Schrader (25%)
- Created the code base, basic screens, and segues between them
- Created the tab bar controller between all the pages
- Wrote code for keeping the user logged in and their current username on every screen, and making sure there was no user logged in when the app launched
- Wrote code for the carousel view of the shows on the feed and shows page
- Implemented the watchlist and the currently watching list and the UI to see them
- Implemented the search functionality and the show detail page, with the buttons to add and delete shows from watching/wishlists
- Updated the UI of the app to be functional with iPhone keyboard
- Added status update to currently watching list

Important Note for Testing Followers/Friends Functionality:  Enter in one of our first names, all lowercase (so victoria, ashley…). Then you will be able to follow us.

Differences: 
We decided to push seeing your friend’s status updates to the next release and focus on actually making friends and status updates for yourself.

We decided it also might not be intuitive to rate a show every time you update your status, only when you finish it. We might add ratings/stars in the final release, but decided it's not a huge priority since it isn't super intuitive.

As we mentioned in alpha, we got rid of the groups feature.

Next release we will polish design and focus on the feed itself. We also have a few more features to add to the Friends page, such as removing a friend, requesting a user who has a private profile, and fixing some UI aspects. Seeing your friend’s status updates and possibly adding a profile picture aspect. The chat feature probably won't be included in our final iteration, but hopefully we can get comments to work and other status aspects of the feed that we are pushing to final.
