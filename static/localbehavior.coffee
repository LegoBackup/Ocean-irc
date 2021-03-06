#keycode defs
ENTER = 13;
TAB = 9
ESC = 27
BACKTICK = 192

UP = 38
DOWN = 40
J = 74
K = 75

#special elems of the text
typingArea = $("textarea");
sideBar = $("#sidebar");
sideBarFocus = 0;
#todo query channels

#data pulled from the server
autocompletes = [];
currentusers = [];

shiftSidebarFocus = (index) ->
	numChannels = $("#sidebar a").length
	sideBarFocus = (numChannels + sideBarFocus + index) % numChannels
	$("#sidebar a:nth-of-type("+(sideBarFocus+1)+")").focus()


# On Document Ready
$(document).ready ->

	#keypresses that make it to the top level
	$(document).keydown (e) -> 
		switch e.keyCode
			when BACKTICK
				$("body").toggleClass("sidebarhidden");
			when ENTER #ENTER
				typingArea.focus();
				e.preventDefault();

	#keypresses on the input box
	typingArea.keydown (e)->
		e.stopPropagation();
		switch e.keyCode
			when BACKTICK
				e.preventDefault();
				$("body").toggleClass("sidebarhidden");
				if(! $("body").hasClass("sidebarhidden"))
					shiftSidebarFocus(0);
			when TAB  #TAB
				e.preventDefault();
				$("body").removeClass("sidebarhidden");

				tofocus = $("#sidebar a.ticked");
				sideBarElems = $("#sidebar a")
				sideBarFocus = sideBarElems.index(tofocus);
				shiftSidebarFocus(0);
			when ENTER #ENTER
				if (! e.shiftKey)
					e.preventDefault();
					if(typingArea.val() != "")
						window.ircapi_sendMessage(typingArea.val());
						$(typingArea).val("");
					
			when ESC #ESC
				#switch focus from text bar to the sidebar
				$("body").removeClass("sidebarhidden");
				shiftSidebarFocus(0)


	#navigating in the sidebar
	sideBar.keydown (e) -> 
		e.stopPropagation();
		e.preventDefault();
		switch e.keyCode
			when BACKTICK
				$("body").addClass("sidebarhidden");
				typingArea.focus();
			when TAB
				typingArea.focus();
			when ENTER
				$(":focus").click();
			when UP, K
				shiftSidebarFocus(-1);
			when DOWN, J
				shiftSidebarFocus(1);

	sideBar.focusin (e) ->
		$("#sidebar").addClass("containsFocus");

	sideBar.focusout (e) ->
		$("#sidebar").removeClass("containsFocus");
	