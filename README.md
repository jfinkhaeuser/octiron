# octiron

*Octiron magically transforms events to GitHub "events".*

Events octiron responds to can be any classes or Hash prototypes. Using
transmogrifiers, events can be turned into other kinds of events.

GitHub "events" are API calls to GitHub that modify something, e.g. create
or delete issues, comments, etc.

The gem includes some transmogrifiers that transmogrify Hash events to
GitHub API calls via octokit.

Users neet to provide some GitHub authentication information, and
transmogrifiers from their own bespoke events to Hash events, and octiron
takes care of turning this into GitHub API calls.

