<%

var util = require('util');
var conn = {};

var cdo = function cdo(options) {
	var gwcfg = Server.CreateObject("CDO.Configuration");
	gwcfg.Fields(cdoSendUsingMethod) = cdoSendUsingPort;
	gwcfg.Fields(cdoSMTPServer) = conn.host || 'localhost';
	gwcfg.Fields(cdoSMTPServerPort) = conn.port || (conn.secure ? 465 : 25);
	gwcfg.Fields.Update();
	
	var gw = Server.CreateObject("CDO.Message");

	gw.Configuration = gwcfg;
	gw.BodyPart.Charset = 'utf-8';
	gw.From = options.from;
	gw.Subject = options.subject;
	
	if (options.to) {
		if ('string' === typeof options.to) options.to = [options.to];
		gw.To = options.to.join(';');
	};
	
	if (options.cc) {
		if ('string' === typeof options.cc) options.cc = [options.cc];
		gw.Cc = options.cc.join(';');
	};
	
	if (options.bcc) {
		if ('string' === typeof options.bcc) options.bcc = [options.bcc];
		gw.Bcc = options.bcc.join(';');
	};

	if (options.attachments) {
		for (var i = 0, att; i < options.attachments.length; i++) {
			try {
				att = gw.AddRelatedBodyPart(options.attachments[i].path, options.attachments[i].filename, 1);
				if (options.attachments[i].filename) att.Fields.Item("urn:schemas:mailheader:content-disposition") = 'attachment; filename="'+ options.attachments[i].filename +'"';
				att.Fields.Item("urn:schemas:mailheader:content-id") = '<'+ options.attachments[i].cid +'>';
				att.Fields.Update();
			} catch (ex) {};
		};
	};
	
	if (options.html) gw.HTMLBody = options.html;
	gw.TextBody = options.text;

	try {
		gw.send();
	} catch (ex) {
		ex.stack = ex.stack || Error.captureStackTrace();
		throw ex;
	};
};

var persits = function persits(options) {
	var gw = Server.CreateObject("Persits.MailSender");

	if (options.from.indexOf('<') !== -1) {
		gw.from = options.from.substring(options.from.indexOf('<') + 1, options.from.lastIndexOf('>')).trim();
		gw.fromName = options.from.substr(0, options.from.indexOf('<')).trim();
	} else {
		gw.from = options.from;
	};

	//gw.MailFrom = ?;
	gw.subject = gw.encodeHeader(options.subject, "utf-8");
	
	if (options.html) {
		gw.isHTML = true;
		gw.body = options.html;
		gw.altBody = options.text;
	} else {
		gw.isHTML = false;
		gw.body = options.text;
	}

	gw.queue = options.queue || false;
	
	if (options.to) {
		if ('string' === typeof options.to) options.to = [options.to];
		for (var i = 0; i < options.to.length; i++) {
			gw.addAddress(options.to[i]);
		};
	};
	
	if (options.cc) {
		if ('string' === typeof options.cc) options.cc = [options.cc];
		for (var i = 0; i < options.cc.length; i++) {
			gw.addCC(options.cc[i]);
		};
	};
	
	if (options.bcc) {
		if ('string' === typeof options.bcc) options.bcc = [options.bcc];
		for (var i = 0; i < options.bcc.length; i++) {
			gw.addBcc(options.bcc[i]);
		};
	};

	if (!options.queue) {
		gw.host = conn.host || 'localhost';
		gw.port = conn.port || (conn.secure ? 465 : 25);
		//gw.SSL = conn.secure || false;
	};
	
	gw.charSet = 'utf-8';
	gw.contentTransferEncoding = "Quoted-Printable";
	
	if (options.headers) {
		for (var i in options.headers) {
			gw.addCustomHeader(i +': '+ options.headers[i]);
		};
	};
	
	if (options.attachments) {
		for (var i = 0; i < options.attachments.length; i++) {
			if (options.attachments[i].path) {
				gw.addEmbeddedImage(options.attachments[i].path, options.attachments[i].cid);
			} else if (options.attachments[i].content) {
				gw.addEmbeddedImage(options.attachments[i].filename, options.attachments[i].cid, options.attachments[i].content);
			};
		};
	};
	
	try {
		gw.send();
	} catch (ex) {
		ex.stack = ex.stack || Error.captureStackTrace();
		throw ex;
	};
};

module.exports = {
	setup: function setup(cfg) {
		conn = cfg;
		return this;
	},
	send: function send(options, done) {
		var error = null;
		
		try {
			if (options.provider === 'persits') {
				persits(options);
			} else {
				cdo(options);
			};
		} catch (ex) {
			ex.stack = ex.stack || Error.captureStackTrace();
			error = ex;
		};
		
		util.defer(done, error);
		
		return this;
	}
};

%>
