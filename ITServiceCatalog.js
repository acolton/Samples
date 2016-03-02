$(document).ready(function () {

  var serviceID = ($(location).attr('href')).split("?")[1];
    
    getContent(serviceID);
    getLinks(serviceID);
    getDetails(serviceID);
});


/* ---------------------------------------------------------------- MAIN CONTENT ----------------------------------------------------------------------------*/
function getContent(serviceID) {

    var method = "GetListItems";
    var list = "ServiceOptions";
    var fieldsToRead = "<ViewFields>" +
				"<FieldRef Name='Title' />" +
				"<FieldRef Name='Image' />" +
				"<FieldRef Name='Overview' />" +
				"<FieldRef Name='HowToOrder' />" +
			"</ViewFields>";
	
	var query = "<Query>" +
		    	"<Where>" +
				"<And>" +
					"<Eq>" +
						"<FieldRef Name='ServiceCode'/><Value Type='Text'>" + serviceID + "</Value>" +
					"</Eq>" +
					"<Eq>" +
						"<FieldRef Name='ActiveR'/><Value Type='Text'>Yes</Value>" +
					"</Eq>" +
				 "</And>" +
			"</Where>" +
		   "</Query>";

    $().SPServices({
        operation: method,
        async: false,
        listName: list,
        CAMLViewFields: fieldsToRead,
        CAMLQuery: query,
        CAMLRowLimit: 1,
        completefunc: function (xData, Status) {
            $(xData.responseXML).SPFilterNode("z:row").each(function () {
                var title = ($(this).attr("ows_Title"));
                var image = ($(this).attr("ows_Image")).split(",")[0];   
                var overview = ($(this).attr("ows_Overview")); 
                var order = ($(this).attr("ows_HowToOrder"));  
              				
                populatePage(image, title, overview, order);

            });
        }
    });
  
}

/* Publish Content to Page */
function populatePage(image, title, overview, order) {
	
    $("#imageHolder").append("<p align='center'><img width='180' src='" + image + "' alt=''/></p>");
    $("#title").append(title);
    $("#center").append("<div id='overview'>" + 
    			"<h1>Overview</h1>" +
    			"<p>" + overview + "</p><br/>" +
		  	"</div>");
    $("#orderDetail").append("<p>" + order + "</p>");
	  				
}	


/* ---------------------------------------------------------------------------- LINKS -----------------------------------------------------------------*/
function getLinks(serviceID) {

    var i = 0;
    var x = 0;
    var method = "GetListItems";
    var list = "Links";
    var fieldsToRead = "<ViewFields>" +
				"<FieldRef Name='URL' />" +
				"<FeldRef Name='LinkText' />" +
				"<FieldRef Name='LinkType' />" +
				"<FieldRef Name='ServiceCode' />" +
			"</ViewFields>";

    var query = "<Query>" +
			"<Where>" +
				"<And>" +
					"<Eq>" +
						"<FieldRef Name='ServiceCode'/><Value Type='Text'>" + serviceID + "</Value>" +
					"</Eq>" +
					"<Eq>" +
						"<FieldRef Name='ActiveR'/><Value Type='Text'>Yes</Value>" +
					"</Eq>" +
				"</And>" +
			"</Where>" +
			"<OrderBy>" +
				"<FieldRef Name='LinkType' Ascending='True'/>" +
			"</OrderBy>" +
		"</Query>";

    $().SPServices({
        operation: method,
        async: false,
        listName: list,
        CAMLViewFields: fieldsToRead,
        CAMLQuery: query,
        completefunc: function (xData, Status) {
            $(xData.responseXML).SPFilterNode("z:row").each(function () {
                var link = ($(this).attr("ows_URL")).split(",")[0];
                var servicecode = ($(this).attr("ows_ServiceCode")).split('#')[1]; 
                var linkText = ($(this).attr("ows_LinkText"));
                var linkType = ($(this).attr("ows_LinkType"));	
                	if (linkType == "related") {
                		i++;
                		}
                   	else  { 
                   		x++; 
                   		}
                populateLinks(link, linkText, linkType, i, x, servicecode); 
                	
            });
        }
    });
  
}

/* Publish Links to Page */
function populateLinks(link, linkText, linkType, i, x, servicecode) {
 	 	
 if (linkType == "related") {
	if (i == 1) {
		$("#relatedHolder").append("<div id='related'><h2>Related Links</h2></div>");
	}

	$("#related").append("<div><p><a class='grey' target='_blank' href='" + link + "'>" + linkText + "</a></p><br />");	
 } 
  
 else {
	if (x == 1) {
		$("#educationHolder").append("<div id='learnMore' class='header'><img src='../PublishingImages/DetailHeaders-02.png' alt='Learn More' /></div>" +
 									  "<div id='education'><h2>Education and Details</h2></div>");
	}

    $("#education").append("<p><a class='grey' target='_blank' href='" + link + "'><img width='30' align='absMiddle' src='/PublishingImages/ITServices-" + 
                           linkType + ".png' alt=''/>&#160;&#160;" + linkText + "</a></p>");
 }

}

/* ---------------------------------------------------------------------------- DETAILS -----------------------------------------------------------------*/
function getDetails(serviceID) {

    var method = "GetListItems";
    var list = "ServiceOptionDetails";
    var fieldsToRead = "<ViewFields>" +
				"<FieldRef Name='ContentType0' />" +
				"<FieldRef Name='Content' />" +
				"<FieldRef Name='Title' />" +
			"</ViewFields>";

    var query = "<Query>" +
			"<Where>" +
				"<And>" +
					"<Eq>" +
						"<FieldRef Name='ServiceCode'/><Value Type='Text'>" + serviceID + "</Value>" +
					"</Eq>" +
					"<Eq>" +
						"<FieldRef Name='ActiveR'/><Value Type='Text'>Yes</Value>" +
					"</Eq>" +
				"</And>" +
			"</Where>" +
			"<OrderBy>" +
				"<FieldRef Name='ContentType0' Ascending='True'/>" +
			"</OrderBy>" +
		"</Query>";

    $().SPServices({
        operation: method,
        async: false,
        listName: list,
        CAMLViewFields: fieldsToRead,
        CAMLQuery: query,
        completefunc: function (xData, Status) {
            $(xData.responseXML).SPFilterNode("z:row").each(function () {
                var content = ($(this).attr("ows_Content"));
                var contentType = ($(this).attr("ows_ContentType0"));
                var title = ($(this).attr("ows_Title"));
                populateDetails(content, contentType, title); 
                	
            });
        }
    }); 
  
}

/* Publish Details to Page */
function populateDetails(content, contentType, title) {

 	if (contentType == "Features") {
		 $("#center").append("<h1>Key Features</h1><p>" + content + "</p><br/>");
	}
	else if (contentType == "WhoUses") {
		 $("#center").append("<h1>Who Uses It?</h1><p>" + content + "</p><br/>");
	}
	else if (contentType == "How") {
		 $("#center").append("<h1>How is it Used?</h1><p>" + content + "</p><br/>");
	}
	else if (contentType == "StaffedHours") {
		 $("#supportDetail").append("<h2>Technical Support <img width='13px'" +
		   "src='http://itservices.xxxxxx.com/PublishingImages/questionMark.png'" + 
		   "title='If the Service Desk is unable to resolve your case, it will be escalated to the respective technical support team.'></h2><p>" + content + "</p>");
	}
	else if (contentType == "Uptime") {
		 $("#glanceDetail").append("<h2>Uptime</h2><p>" + content + "</p>");
	}
	else if (contentType == "SLA") {
		 $("#glanceDetail").append("<h2>Service Level Expectations <!--<img width='13px' src='http://itservices-dev13.xxxxxx.com/PublishingImages/questionMark.png' title='What is SLE?'>--></h2><p>" + content + "</p>");
	}
	else if (contentType == "AppLink") {
		 $("#imageHolder").append("<p align='center'>" + content +"</p>");
	}
	else {
		 $("#left").append("<div id='upgrade'>" +
		 				   "<div id='news' class='header'><img src='../PublishingImages/DetailHeaders-03.png' alt='News' /></div>" +	
				           "<h2>" + title + "</h2>" +
				           "<p>" + content + "</p>" +
				       "</div>");
	}

}