# Feature Checklist: Dynamic IOU History Page

- [x] Update `Route` type in `src/Types.elm` to remove `ExampleHistory` and add `IouHistory UserId`.
- [x] Update `Route.parser` in `src/Route.elm` to parse `/iou?other={email}` into `IouHistory UserId`.
- [x] Update `Route.toString` in `src/Route.elm` for the new `IouHistory` route.
- [x] Update `Route.title` in `src/Route.elm` for the new `IouHistory` route.
- [x] Remove all references to `ExampleHistory` route from code.
- [x] Add mock IOU data between `schalk.dormehl@gmail.com` and `s.dormehl@sakeliga.org.za` in `src/Frontend.elm`.
- [x] Update `currentUserEmail` constant in `src/Frontend.elm` to `schalk.dormehl@gmail.com` for mock data generation.
- [x] Update `Frontend.view` to handle the `IouHistory otherUserId` route:
    - Check if user is logged in (`model.currentUser`).
    - If logged in, render `Pages.UserIouHistory.view` with logged-in user's email and `otherUserId`.
    - If not logged in, display a login prompt.
- [x] Run `./compile.sh` to ensure everything compiles. 