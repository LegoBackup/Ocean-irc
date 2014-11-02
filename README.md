#Ocean-irc

an irc client/bot pair for implementing slack-like functionality

![IMAGE](./ocean--01.png)

##Design Goals

- The bot/client pair should be able to run on any irc server, and be invisible to users not running ocean-client

- ocean-client should be clean, minimalist, and usable without constantly using commands.

##Feature List

###shared content (defined server side)
- Custom emoticons
- User icons
- Text expansions / macros
- Usergroups and @mentions (`@group`, `@everyone`, plus custom groups like `@nerds` or `@ladies`)

###autocompletion/tab expansion
- `/commands`
- `#channel` links
- `:emoticons:`

###client features
- notifications on specific words
- Text expansions / macros

###etc
- Plugin Driven and Extensible
- Log everything said in public channels and direct messages between ocean users
	- Anything said in dms should be retrievable only by the people in the direct messages 

##Observations

- External service integrations (i.e. a chat message when a git branch is pushed to, etc) can already be implemented in vanilla irc with bots.

- Irc's existing commands are all formatted as `/command`. Therefore, in order to mesh well with existing services, custom ocean commands should be prefixed with `/` (i.e `/hangouts`, `/yo`, &c)


##Protocol
The ocean-bot Protocol is designed to work with ircd-ratbox
Many servers work similarly, but we shouldn't worry about getting exact behavior matches

###Ocean-Bot Protocol
1. ocean-bot connects to a server  
2. sets nick if nick “ocean-bot” is unavailable, panic and quit  
3. joins channel #general  
4. calls `/names`, checks that it is a server op 
	(that its name is prepended with @, i.e. @ocean-bot)

5. calls `/list`, attempts to join all channels displayed this way  
	(note that server ops can see any channel on the server, even ones with mode +s +p)

7. ocean-bot then sit in all the joined channels and logs messages while waiting for clients to query it with messages

(see the [Plugins](#plugins) section for a more detailed description of how ocean-bot and ocean-client communicate)

###Ocean-Client Protocol

1. On connecting to the server, a client calls `/whois ocean-bot`
	- if no client is found, ocean-client enters `simple` mode
	- when in simple mode, ocean-client notifies all client-server plugins
2. send an "init" message to Oceanbot

##Plugins

More or less all of the desired features can be implemented with the following plugin system

###Event Hooks
plugins in ocean can register for a series of events to listen for, that will be fired for every item in the listener list whenever the corresponding action happens.

the events are as follows:
`message-send` is triggered whenever a message is sent
`message-recv` is triggered whenever a message is received
`keystroke` is triggered whenever a keystroke is handled


###Load Order
because of interdependence between plugins, loading order matters. All local plugins are loaded before Client-Server plugins. Within those categorizations, plugins use the `priority` attribute defined in their `plugin-name.json` file.

###Rules for every Plugin
each plugin must implement the following methods:
`generate-init-params`: creates a json string to pass to the server on connect
`parse-init-params`: parses the output of `generate-init-params` and returns an appropriate json string for updating/initializing the client-side plugin
`initialize`: takes the output of `parse-init-params` and initializes the client-side plugin from it

`generate-init-params` produces 2 fields: 
1. version, a version number for the plugin 2. cache-updated, a timestamp of the last time the cache was updated for this server

also, in the plugin folder, there must be a json file called `plugin-name.json` (where plugin-name is the name of the .py folder defining the plugin)

###Local Plugins
Local plugins are plugins that do not have a server sided component. They only have event hooks. Only called plugins because they are dynamically loaded from the `local-plugin` directory

###Client-Server Plugins 
client-server plugins are python modules loaded dynamically from the `client-server-plugin` directory. They are composed of 2 components: a clientside and serverside plugin. All comminication between ocean-bot and ocean-client is in the form of JSON formatted strings, prepended with the name of the plugin it is intended for, i.e. `"plugin-name": {...}
`

##Core Plugins

####link-expand (local only)
expands images, webms and youtube videos linked in chat (client side only)

####tab-completion (local only)
handles the tab completion engine and dialog (client side only).

####init
the init plugin is responsible for managing the initialization of other plugins on the client. it cannot be disabled or uninstalled
On initially connecting to a server, ocean-client sends a list of it's locally installed plugins to the server-side ocean-bot , along with the json strings generated by `generate-init-params`
ocean-bot passes the initializing arguments down to each plugin's `parse-init-params` method, then sends a list of initializing arguments back to ocean-client.
ocean-client's init plugin then passes that initialization to the `initialize` method of each of the mentioned plugins, and prints the appropriate errors to stdout.

An example of a client's init string is below 
(`<timestamp>` and `<public-key>` are placeholders for actual data)
```
"init" : {
	"version": "0.0.1",
	"plugins": {
		"text-expand": {
			"version": "0.0.1",
			"cache-updated": <timestamp>}

		"emoticon-text": {
			"version": "0.0.1",
			"cache-updated": <timestamp>},

		"pm-logger": {
			"version": "0.0.1",
			"timestamp": <timestamp>
			"public-key": <public-key>}
	}
}
```

In the event that a client plugin is not supported, ocean-bot replaces the contents of the response data with and error string.

and an example of ocean-bot's response could be:
```
"init": {
	"plugins": {
		"test-expand": {
			"logbot": "(｡≖‿≖)",
			"tableflip": "(╯°□°）╯︵ ┻━┻"},

		"emoticon-text": {
			"emoticon-names": [...]},

		"pm-logger": "plugin 'pm-logger' not supported"
	}
}
```

####text-expand
plugin for text macros.

Its `generate-init-params` produces 2 fields: 
1. `version`, a version number for the text-expand plugin
2. `cache-updated`, a timestamp of the last time the text-expand cache was updated for this server

Its `parse-init-params` takes the output of `generate-init-params`, and returns a list of new/changed macros since the `cache-updated`

text-expand also registers its emoticons with the [tab completion plugin](#tab-completion)

####emoticon-text
the emoticon fetching bot for :emoticons:

Its `generate-init-params` and `parse-init-params` functions act the same way as `text-expand` (see above)

Its `parse-init-params` takes the output of `generate-init-params`, and returns a list of the names of new emoticons

the emoticon-text uses lazy fetching for emoticons
emoticons are not loaded until they are mentioned in chat, at which point it is fetched from ocean-bot and inserted into the text.

For example, the first time a user recieves the `:laugh:` emoticon, the outgoing message is formatted like this:
```
"emoticon-text": {"fetch-icons"[ "laugh" ]}
```

and the response from ocean-bot:
```
"emoticon-text": {
	"icons":[
		{   "name": "laugh"
			"payload": <payload>}
}
```

where `<payload>` is a base-64 encoded string of the raw dump of the png of the emoticon.

emoticon-text also registers its emoticons with the [tab completion plugin](#tab-completion) for tab completion

####user-manager
manager for usernames and user icons

Its `generate-init-params` and `parse-init-params` functions act the same way as `text-expand` (see above)

Its `parse-init-params` takes the output of `generate-init-params`, and returns a list of the names of users and their user icons that have changed since the last update, formatted like so:

```
"user-manager":{
	"known-users": [
		{   "username": "weeaboo"
			"real-name": "Mr. Real Namington"
			"user-icon": <payload>},
		...
}
```

where `<payload>` is a base-64 encoded string of the png of the user icon

when a new user logs on to the server, ocean-bot notifies all currently logged on users with the following message
```
"user-manager": {
	"new-user": {
		"real-name": "real-name"
		"user-icon": <payload>}
}
```
and the ocean-client plugin then updates its cache of users.

####pm-logger
plugin to keep an encrypted copy of all personal messages in a database on ocean-bot.
Every time a private message is sent/received, the following is dm'd to ocean-bot

```
"pm-logger": {
	// encoded with your public key
	"message": <message>
	"sender": <sender username>
	"recipient" : <recipient username>
	
	// encoded with your private key
	"signature": <timestamp>
}
```

hooked into the `keystroke` event. If a `:` is typed or a `/` is typed at the beginning of a line, it opens an autocomplete dialog, the contents of which are pulled from one of two separate lists that tab-completion allows other plugins to register for with the `register` method.

To register a tab completion, a plugin must provide an input string, output string, and list that the completion should go into.

##Description of UI
Imagine Slack's UI, but exactly the same.

##Development Priorities

some features are more critical than others, some features depend on others.

###Backend:
1. communication between ocean-client and ocean-bot over irc
2. init plugin
3. tab-completion plugin logic
4. emoticon-text plugin logic
5. link-expand plugin

###Frontend:
1. basic (animated) irc client panel
2. GUI for the tab-completion plugin
3. front end of emoticon-text (image insertion into text)
4. login screen (for connecting to an irc server, setting nick/ real name, etc) 
5. link-expansion in chat

##Future Plans
this document only aims to cover the basic functionality of the Ocean client-server pair. In the future, we should talk about

1. something to manage @groups
2. mention-listener: a plugin to listen for specific phrases or @group mentions that plays sounds and hooks into whatever your native notification system is
2. A web frontend for managing plugins on ocean-bot and viewing logs
3. More plugins for basic functionality
4. A GUI in ocean-client for managing plugins
	- maybe using git repos and have a curated list?
5. markdown parsing in messages
6. Color theming with a generic theme.json

##Finishing Notes
This is stuff we will probably end up using over the course of the hackathon, so if its relevant to you, read up.

TODO on this doc:
1. write something for user-icons
2. more accurate description of UI

1. [PyQt](https://wiki.python.org/moin/PyQt)
2. [python irc](https://pypi.python.org/pypi/irc)
3. [loading python modules dynamically](http://stackoverflow.com/questions/951124/dynamic-loading-of-python-modules)

Also , we're using python3. Deal with it.
