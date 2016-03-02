$(document).ready(function () {
    searchPrompt();

	$("#searchButton").click(function () {
        universalResults();
        return false;
    });

    $("#query").keydown(function (e) {

        var code = (e.keyCode ? e.keyCode : e.which);
        if (code == 13) {
            universalResults();
            return false;
        }
        
    });
});

function searchPrompt() {
    var input = $("input[id='query']");
    var prompt = "Search...";

    input.click(function () {
        if ($(this).val() == prompt) $(this).val("");
    });
    input.blur(function () {
        if ($(this).val() == "") $(this).val(prompt);
    });
    input.blur();
}

function universalResults() {
       
    var method = "GetListItems";
    var list = "Videos";
    var category = document.getElementById("selected").value;
    var searchString = document.getElementById("query").value;
    var input = $("#query").val().split(" ");
    var count = new Number;
    var fieldsToRead = "<ViewFields>" +
				"<FieldRef Name='Title' />" +
				"<FieldRef Name='Thumbnail' />" +
				"<FieldRef Name='Description' />" +
				"<FieldRef Name='Likes' />" +
				"<FieldRef Name='CreatedDate' />" +
				"<FieldRef Name='Duration' />" +
				"<FieldRef Name='Hits' />" +
				"<FieldRef Name='ID' />" +
				"<FieldRef Name='Contributor' />" +
				"<FieldRef Name='Channel' />" +
			"</ViewFields>";
    var baseQuery;
    if (category == "all") {
        baseQuery = "<And>" +
        	     	"<Eq>" +
		 		"<FieldRef Name='Active'/><Value Type='Text'>true</Value>" +
		      	"</Eq>" +
	              	"<Or>" +
		       		"<Contains>" +
					"<FieldRef Name='Title' /><Value Type='Text'>" + input[0] + "</Value>" +
		    		"</Contains>" +
		    		"<Contains>" +
					"<FieldRef Name='Description' /><Value Type='Text'>" + input[0] + "</Value>" +
		    		"</Contains>" +
		    	"</Or>" +
		    "</And>";
    } else {
        baseQuery = "<And>" +
        		"<Eq>" +
				"<FieldRef Name='Active'/><Value Type='Text'>true</Value>" +
			"</Eq>" +
	        	"<And>" +
				"<Eq>" +
					"<FieldRef Name='Channel' /><Value Type='Text'>" + category + "</Value>" +
				"</Eq>" +
				"<Or>" +
					"<Contains>" +
						"<FieldRef Name='Title' /><Value Type='Text'>" + input[0] + "</Value>" +
					"</Contains>" +
					"<Contains>" +
							"<FieldRef Name='Description' /><Value Type='Text'>" + input[0] + "</Value>" +
					"</Contains>" +
				"</Or>" +
			"</And>" +
		   "</And>";
    }

	var finalQuery = baseQuery;
    for (var i = 1; i < input.length; i++) {
        finalQuery = "<And>" + finalQuery + "<Or>" +
						"<Contains>" +
							"<FieldRef Name='Title' /><Value Type='Text'>" + input[i] + "</Value>" +
						"</Contains>" +
						"<Contains>" +
							"<FieldRef Name='Description' /><Value Type='Text'>" + input[i] + "</Value>" +
						"</Contains>" +
					"</Or></And>";
    }

    finalQuery = "<Query><Where>" + finalQuery + "</Where><OrderBy><FieldRef Name='Likes' Ascending='False' /></OrderBy></Query>";

    $("#content").empty().append("<div id='title'>Search Results</div><div class='arrow'></div>" +
        "<div id='results'></div>");
    
    $().SPServices({
        operation: method,
        async: false,
        listName: list,
        CAMLViewFields: fieldsToRead,
        CAMLQuery: finalQuery,
        completefunc: function (xData, Status) {
            $(xData.responseXML).SPFilterNode("z:row").each(function () {
                var Title = ($(this).attr("ows_Title"));
                var Description = ($(this).attr("ows_Description"));
                var Thumbnail = ($(this).attr("ows_Thumbnail")).split(",")[0];
                var Like = ($(this).attr("ows_Likes")).split(".")[0];
                var ID = ($(this).attr("ows_ID"));
                var Date = ($(this).attr("ows_CreatedDate")).split("#")[1];
                var Duration = ($(this).attr("ows_Duration"));
                var Views = ($(this).attr("ows_Hits")).split(".")[0];
                var channel = ($(this).attr("ows_Channel"));
                var Contributor = ($(this).attr("ows_Contributor"));
                count = count + 1;
                AddSearchResult(Title, Description, Thumbnail, Like, ID, Date, Duration, Views, channel, Contributor);
            });
        }
    });
    if (count == 0) {
        $("#results").append("<div id='video'><td><tr>" +
            "<h1>No Results Found for '" + searchString + "'. Please consider expanding your search.</h1><br />" +
            "<h3>If you still can't find what you are looking for you can <a href='Request.aspx'>Request a Video</a>.</h3></td></tr></div>");
    }
    saveSearch(category, input);
}

function AddSearchResult(Title, Description, Thumbnail, Like, ID, Date, Duration, Views, channel, Contributor) {

    $("#results").append("<div id='video'><td><tr>" +
        "<div class='thumbnail'><a href='../SitePages/Watch.aspx?" + ID + "'>" +
        "<img class='thumb' src='" + Thumbnail + "'/>" +
        "<div class='time'>" + Duration + "</div></a></div>" +

        "<div class='details'><h1><a href='../SitePages/Watch.aspx?" + ID + "' class='" + channel + "18'>" + Title + "</a></h1>" +
        "<h2><b>by <a href='#'>" + Contributor + "</a>&emsp;Date Added: " + Date + "&emsp;" + Like + " likes" +
        "&emsp;" + Views + " views</b><br />" + Description + "</h2></div></td></tr></div>");
}

function saveSearch(category, input) {
    var batch =
        "<Batch OnError=\"Continue\"> \
            <Method ID=\"1\" Cmd=\"New\"> \
                <Field Name=\"Channel\">" + category + "</Field> \
                <Field Name=\"SearchString\">" + input + "</Field> \
            </Method> \
        </Batch>";

    var soapEnv =
        "<?xml version=\"1.0\" encoding=\"utf-8\"?> \
        <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \
            xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" \
            xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"> \
          <soap:Body> \
            <UpdateListItems xmlns=\"http://schemas.microsoft.com/sharepoint/soap/\"> \
              <listName>Searches</listName> \
              <updates> \
                " + batch + "</updates> \
            </UpdateListItems> \
          </soap:Body> \
        </soap:Envelope>";

    $.ajax({
        url: "http://itservices-dev13.xxxxxx.com/btube/_vti_bin/lists.asmx",
        beforeSend: function (xhr) {
            xhr.setRequestHeader("SOAPAction",
                "http://schemas.microsoft.com/sharepoint/soap/UpdateListItems");
        },
        type: "POST",
        dataType: "xml",
        data: soapEnv,
        contentType: "text/xml; charset=utf-8"
    });
}