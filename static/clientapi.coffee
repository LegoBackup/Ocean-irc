#special elems of the text
typingArea = $("textarea");
sideBar = $("#sidebar");
sideBarFocus = 0;
numChannels = $("#sidebar a").length

#init args
initChans = ["general", "mabois", "knurds"];
messages = {};

#data pulled from the server
autocompletes = [];
users = [];
activeChannel = ""


window.ircapi_sendMessage = (str) ->
	return

setActiveChannel = (chan) ->
	activeChannel = chan;
	window.location.hash = "##{chan}";
	$(".ticked").removeClass("ticked");
	$("#sidebar a[href='##{chan}']").addClass("ticked");
	
handleLinkClick = (evt) ->
	setActiveChannel(this.hash.substring(1));
	evt.preventDefault();

joinChannel = (channame) ->
	$.ajax ("./api/join/"+channame+"/"),
		type: "GET"
		dataType: "json"
		error: (jqXHR, textStatus, errorThrown) ->
			console.log("error in getting userlist: ", errorThrown)
		success: (data, textStatus, jqXHR) ->
			if (data["private"])
				$("<a href=\"##{channame}\">##{channame}</a>").insertAfter(
					$("#sidebar #privateChannels")).click(handleLinkClick);
			else
				$("<a href=\"##{channame}\">##{channame}</a>").insertAfter(
					$("#sidebar #publicChannels")).click(handleLinkClick);

			if (window.location.hash == undefined)
				setActiveChannel(channame);	
			else if (window.location.hash == "##{channame}")
				setActiveChannel(channame)

			messages["##{channame}"] = [];
			users.push(data["users"])

buildMsg = (msg) ->
	icon = "./static/imgdump/placeholder.gif";
	$("#chatcontents").append(
		$("<section class='post'>"+
			"<img src='#{icon}'/>"+
			"<section class='name'>#{msg['usr']}</section>"+
			"<section class='timestamp'>#{msg['timestamp']}</section>"+
			"<section class='body'>#{msg['msg']}</section>"+
		"</section>"));

fetchMessages = ->
	$.ajax ("./api/getMessages"),
		type: "GET"
		dataType: "json"
		error: (jqXHR, textStatus, errorThrown) ->
			console.log("error in getting userlist: ", errorThrown)
		success: (data, textStatus, jqXHR) ->
			for msg in data
				messages[msg["channel"]].push(msg)
				if (msg["channel"].substring(1) == activeChannel)
					buildMsg(msg)

# On Document Ready
$(document).ready ->
	#sending a "connect to server" message on connect
	$.ajax "./api/connect/104.236.63.94/oceanman/", 
		type: "GET"
		dataType: "html"
		error: (jqXHR, textStatus, errorThrown) ->
        	console.log(textStatus);
		success: (data, textStatus, jqXHR) ->
			console.log(data);
			#load users and autocompletes when connected
			loadAutoCompletes();
			(joinChannel(c) for c in initChans.reverse())
			initChans.reverse();

			setInterval(fetchMessages, 100);

loadAutoCompletes = ->
	$.ajax "./api/autocompletes",
		type: "GET"
		dataType: "json"
		error: (jqXHR, textStatus, errorThrown) ->
			console.log("error in getting autocompletes: ", errorThrown)
		success: (data, textStatus, jqXHR) ->
			this.autocompletes = data
			console.log(this.autocompletes)
