```mermaid
sequenceDiagram
    participant Browser
    participant LamderaNav as Lamdera Navigation
    participant FrontendInit as Frontend.init / update (UrlChanged)
    participant RouteParser as Route.fromUrl / parser
    participant FrontendView as Frontend.view
    participant UserHistoryPage as Pages.UserIouHistory.view
    participant PageFrame as Pages.PageFrame
    participant BackendComms as Backend Communications

    Browser->>LamderaNav: Navigates to /iou-history/example
    LamderaNav->>FrontendInit: Triggers UrlChanged with Url
    FrontendInit->>RouteParser: Calls Route.fromUrl(url)
    RouteParser-->>FrontendInit: Returns Route = ExampleHistory
    FrontendInit->>FrontendView: Updates model, calls view(model { currentRoute = ExampleHistory })
    
    Note over FrontendView: Enters view function
    FrontendView->>FrontendView: Determines viewContent based on model.currentRoute
    FrontendView->>UserHistoryPage: Matches ExampleHistory, calls UserHistoryPage.view(model, "them@example.com", mockIouDict)
    UserHistoryPage-->>FrontendView: Returns Html using mockIouDict
    
    Note over FrontendView: Has viewContent Html (using mock data)
    FrontendView->>PageFrame: Calls PageFrame.viewHeader(model)
    PageFrame-->>FrontendView: Returns Header Html
    FrontendView->>PageFrame: Calls PageFrame.viewFooter(model)
    PageFrame-->>FrontendView: Returns Footer Html
    
    FrontendView->>Browser: Assembles Document { body = [Header, viewContent, Footer] }
    Browser->>Browser: Renders initial page using mock data (briefly visible - the "flash")
    
    alt User is Logged In (or logs in shortly after)
        BackendComms-->>FrontendInit: Receives AuthSuccess or UserDataToFrontend msg
        FrontendInit->>FrontendInit: Processes msg in updateFromBackend
        Note over FrontendInit: AuthSuccess handler includes 'Nav.pushUrl model.key "/"'
        FrontendInit->>LamderaNav: Issues Cmd Nav.pushUrl "/"
        LamderaNav->>Browser: Changes URL to /
        LamderaNav->>FrontendInit: Triggers UrlChanged with new Url (/)
        FrontendInit->>RouteParser: Calls Route.fromUrl(url /)
        RouteParser-->>FrontendInit: Returns Route = Default
        FrontendInit->>FrontendView: Updates model, calls view(model { currentRoute = Default })
        FrontendView->>FrontendView: Renders Default page content
        FrontendView->>Browser: Assembles Document for Default page
        Browser->>Browser: Replaces mock history page with Default page
    end

```

This diagram shows a plausible *actual* flow explaining the flash:

1.  The URL `/iou-history/example` is parsed, and the view initially renders using `mockIouDict`.
2.  This mock view is briefly visible in the browser.
3.  If the user is logged in, a message like `AuthSuccess` arrives from the backend.
4.  The `updateFromBackend` function handles this message.
5.  Crucially, the handler for `AuthSuccess` issues a `Nav.pushUrl model.key "/"` command.
6.  Lamdera Navigation changes the browser URL to `/`.
7.  This triggers `UrlChanged` again, parsing the route as `Default`.
8.  The `Frontend.view` function now renders the `Default` page, replacing the previously flashed `ExampleHistory` content.

This sequence explains why the mock data appears briefly and then disappears when logged in – the application automatically navigates the user to the home page after confirming authentication. 