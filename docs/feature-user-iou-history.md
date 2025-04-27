# Feature: User IOU History Page

- [x] Define `UserIouHistory String` route in `Route.elm`.
- [x] Create `src/Pages/UserIouHistory.elm` module.
- [x] Define minimal `Model` and `Msg` (if needed, likely not for mock) in `Pages.UserIouHistory`.
- [ ] Implement `init` function in `Pages.UserIouHistory`. (Not needed for mock)
- [x] Implement `view` function in `Pages.UserIouHistory` to:
    - [x] Filter IOUs involving the current user and the target user.
    - [x] Calculate the balance from the current user's perspective.
    - [x] Group transactions by month (`(Year, Month)`).
    - [x] Calculate and display the closing balance for each month.
    - [x] Display monthly transaction details.
- [x] Update `Frontend.elm` `update` function for the new route.
- [x] Update `Frontend.elm` `view` function to render the new page.
- [x] Update `PageFrame.elm` `pageView` function to include the new page type.
- [x] Run `./compile.sh` to check compilation. 